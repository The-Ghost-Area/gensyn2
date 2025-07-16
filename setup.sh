#!/bin/bash
#
# GENSYN AUTO SETUP SCRIPT
# Improved version with enhanced error logging and modern practices.
#
set -e # Exit immediately if a command exits with a non-zero status.

# === Configuration ===
TOTAL_STEPS=6
LOG_FILE="/tmp/gensyn_setup.log"
WORK_DIR=~/work

# Clean up previous log file
>"${LOG_FILE}"

# === Color and Formatting Definitions ===
# Fallback to empty strings if tput is not available or fails
GREEN=$(tput setaf 2 2>/dev/null) || GREEN=""
NC=$(tput sgr0 2>/dev/null) || NC=""
BOLD=$(tput bold 2>/dev/null) || BOLD=""
RED=$(tput setaf 1 2>/dev/null) || RED=""

# === UI Functions ===
get_random_color() {
    # A smaller, more readable set of colors
    colors=(33 39 45 51 81 87 123 129 165 201 27)
    echo "$(tput setaf ${colors[$RANDOM % ${#colors[@]}]})"
}

print_banner() {
    clear
    echo "$(get_random_color)"
    echo "██████╗ ███████╗██╗   ██╗██╗██╗     "
    echo "██╔══██╗██╔════╝██║   ██║██║██║     "
    echo "██║  ██║█████╗  ██║   ██║██║██║     "
    echo "██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     "
    echo "██████╔╝███████╗ ╚████╔╝ ██║███████╗"
    echo "╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝"
    echo "${NC}"
    echo "${BOLD}🔥 GENSYN AUTO SETUP SCRIPT 🔥${NC}"
    echo
}

print_main_progress() {
    local step=$1
    local progress=$(( (step * 100) / TOTAL_STEPS ))
    local filled_len=$(( (progress * 20) / 100 ))
    local empty_len=$(( 20 - filled_len ))
    local bar=$(printf "%${filled_len}s" | tr ' ' '█')$(printf "%${empty_len}s" | tr ' ' '─')
    echo "Overall Progress: [${GREEN}${bar}${NC}] ${progress}%"
}

# === Core Logic Functions ===

handle_error() {
    local message="$1"
    local step="$2"

    print_banner
    print_main_progress "${step}"
    printf "\n${RED}✖ An error occurred during: %s${NC}\n" "${message}"
    echo "--------------------------------------------------"
    echo "  ${BOLD}Error Details (from ${LOG_FILE}):${NC}"
    echo "--------------------------------------------------"
    # Indent the log output for readability
    sed 's/^/    /' "${LOG_FILE}"
    echo "--------------------------------------------------"
    echo "${RED}Exiting setup. Please review the error above, fix the issue, and retry.${NC}"
    exit 1
}

# Universal runner with loader and detailed logging
run_with_loader() {
    local message="$1"
    local step="$2"
    local command_to_run="$3"
    
    # Run command in the background, redirecting stdout/stderr to the log file
    eval "${command_to_run}" >> "${LOG_FILE}" 2>&1 &
    local pid=$!

    local spinner=("🌍" "🌎" "🌏")
    local i=0
    
    # Hide cursor
    tput civis
    while [ -d /proc/$pid ]; do
        print_banner
        print_main_progress "${step}"
        printf "\r%s... %s" "${message}" "${spinner[$i]}"
        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.2
    done
    # Show cursor
    tput cnorm
    
    # Wait for the process one last time to get the exit code
    wait $pid
    local exit_code=$?
    
    print_banner
    print_main_progress "${step}"
    if [ $exit_code -eq 0 ]; then
        printf "\r${GREEN}✔ %s... Done${NC}\n" "${message}"
        sleep 1
    else
        handle_error "${message}" "${step}"
    fi
}

# === Main Script Execution ===
main() {
    print_banner
    print_main_progress 0
    echo "Starting Gensyn setup. All detailed logs will be in ${LOG_FILE}"
    sleep 2

    echo "Changing to target directory ${WORK_DIR}..."
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
    echo "Successfully changed to: $(pwd)"
    sleep 1

    # --- Step 1: System Update ---
    run_with_loader "[1/${TOTAL_STEPS}] Updating system and installing base packages" 1 \
        "sudo apt-get update -qq && sudo apt-get install -y -qq sudo python3 python3-venv python3-pip curl wget screen git lsof nano unzip iproute2 build-essential gcc g++"

    # --- Step 2: CUDA Setup ---
    run_with_loader "[2/${TOTAL_STEPS}] Downloading and running CUDA setup" 2 \
        "rm -f cuda.sh && curl -s -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh && chmod +x cuda.sh && bash ./cuda.sh"

    # --- Step 3: Node.js and Yarn Setup (Modern Method) ---
    run_with_loader "[3/${TOTAL_STEPS}] Setting up Node.js and Yarn" 3 \
        "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
        sudo apt-get update -qq && sudo apt-get install -y -qq nodejs && \
        sudo mkdir -p /etc/apt/keyrings && \
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
        echo 'deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main' | sudo tee /etc/apt/sources.list.d/yarn.list && \
        sudo apt-get update -qq && sudo apt-get install -y -qq yarn"

    # --- Step 4: Version Verification ---
    run_with_loader "[4/${TOTAL_STEPS}] Verifying installed versions" 4 \
        "node -v && npm -v && yarn -v && python3 --version"
    
    echo "${BOLD}Installed Versions:${NC}"
    printf "┌──────────┬──────────┐\n"; printf "│ Node.js  │ $(node -v 2>/dev/null || echo "N/A") │\n"; printf "│ npm      │ $(npm -v 2>/dev/null || echo "N/A") │\n"; printf "│ Yarn     │ $(yarn -v 2>/dev/null || echo "N/A") │\n"; printf "│ Python   │ $(python3 --version 2>/dev/null | cut -d' ' -f2 || echo "N/A") │\n"; printf "└──────────┴──────────┘\n";
    sleep 2

    # --- Step 5: Clone Gensyn Project ---
    if [ -d "rl-swarm" ]; then
        print_banner
        print_main_progress 5
        echo "${GREEN}✔ [5/${TOTAL_STEPS}] Directory rl-swarm already exists, skipping clone.${NC}"
        sleep 1
    else
        run_with_loader "[5/${TOTAL_STEPS}] Cloning Gensyn AI repository" 5 \
            "git clone --quiet https://github.com/gensyn-ai/rl-swarm.git"
    fi

    # --- Step 6: Python Environment & Frontend Setup ---
    print_banner
    print_main_progress 6
    echo "[6/${TOTAL_STEPS}] Setting up Python environment and frontend..."
    
    # Use a subshell to contain directory changes (safer than cd/cd)
    (
        cd rl-swarm || { echo "Error: Directory 'rl-swarm' not found!"; exit 1; }
        
        echo "➡️  Creating Python virtual environment..."
        python3 -m venv .venv >> "${LOG_FILE}" 2>&1 || handle_error "Python venv creation" 6
        echo "✅ Python environment created."
        
        (
            cd modal-login || { echo "Error: Directory 'modal-login' not found!"; exit 1; }

            echo "➡️  ${BOLD}Running 'yarn install'... This may take several minutes. See live output below.${NC}"
            yarn install || handle_error "Yarn install" 6

            echo "➡️  ${BOLD}Running 'yarn upgrade'...${NC}"
            yarn upgrade || handle_error "Yarn upgrade" 6
            
            echo "➡️  ${BOLD}Running 'yarn add next@latest viem@latest'...${NC}"
            yarn add next@latest viem@latest || handle_error "Yarn add next/viem" 6
        )
    )
    # Check the subshell's exit code
    [ $? -eq 0 ] || handle_error "Frontend setup" 6 "[6/6] Setting up environment..."

    echo "${GREEN}✔ Frontend setup complete.${NC}"
    sleep 2
    
    # --- Final Output ---
    print_banner
    print_main_progress ${TOTAL_STEPS}
    echo
    echo "${GREEN}${BOLD}✅ GENSYN SETUP COMPLETE${NC}"
    echo "All files are located in: ${BOLD}$(pwd)/rl-swarm${NC}"
    echo "To get started, navigate to the directory and activate the environment."
    echo
    echo "${BOLD}Happy computing!${NC}"
}

# Run the main function
main
