#!/bin/bash
#
# GENSYN AUTO SETUP SCRIPT
# Modified version: Clones the repo and runs only 'yarn install'.
#
set -e # Exit immediately if a command exits with a non-zero status.

# === Configuration ===
TOTAL_STEPS=6
LOG_FILE="/tmp/gensyn_setup.log"
WORK_DIR=~/work

# Clean up previous log file
>"${LOG_FILE}"

# === Color and Formatting Definitions ===
GREEN=$(tput setaf 2 2>/dev/null) || GREEN=""
NC=$(tput sgr0 2>/dev/null) || NC=""
BOLD=$(tput bold 2>/dev/null) || BOLD=""
RED=$(tput setaf 1 2>/dev/null) || RED=""

# === UI Functions ===
get_random_color() {
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
    sed 's/^/    /' "${LOG_FILE}"
    echo "--------------------------------------------------"
    echo "${RED}Exiting setup. Please review the error above, fix the issue, and retry.${NC}"
    exit 1
}

run_with_loader() {
    local message="$1"
    local step="$2"
    local command_to_run="$3"
    
    eval "${command_to_run}" >> "${LOG_FILE}" 2>&1 &
    local pid=$!

    local spinner=("🌍" "🌎" "🌏")
    local i=0
    
    tput civis
    while [ -d /proc/$pid ]; do
        print_banner
        print_main_progress "${step}"
        printf "\r%s... %s" "${message}" "${spinner[$i]}"
        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.2
    done
    tput cnorm
    
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

    # --- Steps 1-4 (Unchanged) ---
    echo "Changing to target directory ${WORK_DIR}..."
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
    echo "Successfully changed to: $(pwd)"
    sleep 1

    run_with_loader "[1/${TOTAL_STEPS}] Updating system and installing base packages" 1 \
        "sudo apt-get update -qq && sudo apt-get install -y -qq sudo python3 python3-venv python3-pip curl wget screen git lsof nano unzip iproute2 build-essential gcc g++"

    run_with_loader "[2/${TOTAL_STEPS}] Downloading and running CUDA setup" 2 \
        "rm -f cuda.sh && curl -s -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh && chmod +x cuda.sh && bash ./cuda.sh"

    run_with_loader "[3/${TOTAL_STEPS}] Setting up Node.js and Yarn" 3 \
        "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
        sudo apt-get update -qq && sudo apt-get install -y -qq nodejs && \
        sudo mkdir -p /etc/apt/keyrings && \
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
        echo 'deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main' | sudo tee /etc/apt/sources.list.d/yarn.list && \
        sudo apt-get update -qq && sudo apt-get install -y -qq yarn"

    run_with_loader "[4/${TOTAL_STEPS}] Verifying installed versions" 4 \
        "node -v && npm -v && yarn -v && python3 --version"
    
    echo "${BOLD}Installed Versions:${NC}"
    printf "┌──────────┬──────────┐\n"; printf "│ Node.js  │ $(node -v 2>/dev/null || echo "N/A") │\n"; printf "│ npm      │ $(npm -v 2>/dev/null || echo "N/A") │\n"; printf "│ Yarn     │ $(yarn -v 2>/dev/null || echo "N/A") │\n"; printf "│ Python   │ $(python3 --version 2>/dev/null | cut -d' ' -f2 || echo "N/A") │\n"; printf "└──────────┴──────────┘\n";
    sleep 2

    # --- Step 5: Clone Gensyn Project (Unchanged) ---
    if [ -d "rl-swarm" ]; then
        print_banner
        print_main_progress 5
        echo "${GREEN}✔ [5/${TOTAL_STEPS}] Directory rl-swarm already exists, skipping clone.${NC}"
        sleep 1
    else
        run_with_loader "[5/${TOTAL_STEPS}] Cloning Gensyn AI repository" 5 \
            "git clone --quiet https://github.com/gensyn-ai/rl-swarm.git"
    fi

    # === MODIFIED Step 6: Setup Base Environment and run 'yarn install' ONLY ===
    print_banner
    print_main_progress 6
    echo "[6/${TOTAL_STEPS}] Setting up base environment and installing Yarn packages..."

    # Use a subshell to safely manage directory changes
    (
        cd rl-swarm || { echo "${RED}Error: Directory 'rl-swarm' not found!${NC}"; exit 1; }
        
        echo "➡️  Creating Python virtual environment..."
        python3 -m venv .venv >> "${LOG_FILE}" 2>&1 || { echo "${RED}Failed to create Python venv.${NC}"; exit 1; }
        echo "✅ Python environment created in 'rl-swarm/.venv'."

        (
            cd modal-login || { echo "${RED}Error: Directory 'modal-login' not found!${NC}"; exit 1; }
            
            echo "➡️  ${BOLD}Running 'yarn install'... This may take several minutes. You will see live output below.${NC}"
            # Run yarn install verbosely and check its exit code
            yarn install
        )
    )
    # Check if the subshell failed
    if [ $? -ne 0 ]; then
        # The handle_error function expects a log file, so let's add a message.
        echo "The 'yarn install' process failed. Please check the output above for errors." >> "${LOG_FILE}"
        handle_error "yarn install" 6
    fi
    
    echo "${GREEN}✔ Yarn install complete.${NC}"
    sleep 2
    
    # --- Final Output ---
    print_banner
    print_main_progress ${TOTAL_STEPS}
    echo
    echo "${GREEN}${BOLD}✅ BASE SETUP COMPLETE${NC}"
    echo "The repository is cloned and initial dependencies are installed."
    echo
    echo "${BOLD}--- What to do next ---${NC}"
    echo "1. Navigate to the project directory:"
    echo "   ${GREEN}cd ~/work/rl-swarm${NC}"
    echo "2. Activate the Python environment:"
    echo "   ${GREEN}source .venv/bin/activate${NC}"
    echo "3. Run the project scripts as needed (e.g., ./run_rl_swarm.sh)"
    echo
}

# Run the main function
main
