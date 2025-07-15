#!/bin/bash
set -e

# === Color and formatting definitions ===
GREEN=$(tput setaf 2)
NC=$(tput sgr0)
BOLD=$(tput bold)

# === Random color for banner ===
get_random_color() {
    colors=(1 2 3 4 5 6 9 10 11 12 13 14 21 27 33 39 45 51 81 87 123 129 165 201)
    echo $(tput setaf ${colors[$RANDOM % ${#colors[@]}]})
}

# === Print banner (persistent, full banner) ===
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
    echo "${BOLD}🔥 GENSYN AUTO SETUP SCRIPT BY DEVIL 🔥${NC}"
}

# === Main progress bar ===
print_main_progress() {
    local step=$1
    local total_steps=6
    local progress=$(( (step * 100) / total_steps ))
    local filled=$(( progress / 5 ))
    local empty=$(( 20 - filled ))
    local bar=$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s" | tr ' ' '-')
    echo "Overall Progress: [$bar] $progress%"
}

# === Internal step progress moon loader ===
internal_loader() {
    local pid=$1
    local message=$2
    local step=$3
    local earth_spin=("🌍" "🌎" "🌏")
    local i=0
    while [ -d /proc/$pid ]; do
        print_banner
        print_main_progress $step
        printf "\r%s %s" "$message" "${earth_spin[$i]}"
        i=$(( (i + 1) % ${#earth_spin[@]} ))
        sleep 0.2
        tput cuu1
        tput el
    done
    print_banner
    print_main_progress $step
    printf "\r%s %s ${GREEN}Done${NC}\n" "$message" "🌍"
    sleep 1
}

# === Error handling function ===
handle_error() {
    print_banner
    print_main_progress $2
    printf "\r%s [✖] Failed\n" "$3"
    echo "Error: $1"
    echo "Exiting setup. Please fix the issue and retry."
    exit 1
}

# === Initial banner ===
print_banner
print_main_progress 0
sleep 2

# === CHANGE TO WORKING DIRECTORY (~/work) ===
printf "Changing to target directory ~/work...\n"
mkdir -p ~/work
cd ~/work
printf "Successfully changed to: $(pwd)\n"
sleep 2


# === Step 1-4 (Same as before) ===
# ... (System Update, CUDA, Node.js, Version Check) ...
print_banner
print_main_progress 1
printf "[1/6] Updating system and installing base packages..."
(sudo apt update -qq && sudo apt install -y -qq sudo python3 python3-venv python3-pip curl wget screen git lsof nano unzip iproute2 build-essential gcc g++ > /dev/null 2>&1) & internal_loader $! "[1/6] Updating system and installing base packages..." 1
[ $? -eq 0 ] || handle_error "Failed to update system or install packages" 1 "[1/6] Updating system and installing base packages..."
sleep 1

print_banner
print_main_progress 2
printf "[2/6] Downloading and running CUDA setup..."
([ -f cuda.sh ] && rm cuda.sh; curl -s -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh && chmod +x cuda.sh && bash ./cuda.sh > /dev/null 2>&1) & internal_loader $! "[2/6] Downloading and running CUDA setup..." 2
[ $? -eq 0 ] || handle_error "Failed to download or run CUDA setup" 2 "[2/6] Downloading and running CUDA setup..."
sleep 1

print_banner
print_main_progress 3
printf "[3/6] Setting up Node.js and Yarn..."
(curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1 && sudo apt update -qq && sudo apt install -y -qq nodejs > /dev/null 2>&1 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - > /dev/null 2>&1 && echo "deb https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null && sudo apt update -qq && sudo apt install -y -qq yarn > /dev/null 2>&1) & internal_loader $! "[3/6] Setting up Node.js and Yarn..." 3
[ $? -eq 0 ] || handle_error "Failed to install Node.js or Yarn" 3 "[3/6] Setting up Node.js and Yarn..."
sleep 1

print_banner
print_main_progress 4
printf "[4/6] Verifying installed versions..."
(node -v > /dev/null 2>&1 && npm -v > /dev/null 2>&1 && yarn -v > /dev/null 2>&1 && python3 --version > /dev/null 2>&1) & internal_loader $! "[4/6] Verifying installed versions..." 4
[ $? -eq 0 ] || handle_error "Failed to verify versions" 4 "[4/6] Verifying installed versions..."
echo "Versions:"
printf "┌──────────┬──────────┐\n"; printf "│ Node.js  │ $(node -v 2>/dev/null || echo "Not installed") │\n"; printf "│ npm      │ $(npm -v 2>/dev/null || echo "Not installed") │\n"; printf "│ Yarn     │ $(yarn -v 2>/dev/null || echo "Not installed") │\n"; printf "│ Python   │ $(python3 --version 2>/dev/null | cut -d' ' -f2 || echo "Not installed") │\n"; printf "└──────────┴──────────┘\n";
sleep 2

# === Step 5: Clone Gensyn Project ===
print_banner
print_main_progress 5
printf "[5/6] Cloning Gensyn AI repository..."
( if [ ! -d "rl-swarm" ]; then git clone --quiet https://github.com/gensyn-ai/rl-swarm.git > /dev/null 2>&1; else echo "Directory rl-swarm already exists, skipping clone."; sleep 1; fi ) & internal_loader $! "[5/6] Cloning Gensyn AI repository..." 5
[ $? -eq 0 ] || handle_error "❌ Failed to clone repository" 5 "[5/6] Cloning Gensyn AI repository..."
sleep 1


# === Step 6: Python Virtual Environment & Frontend Setup (VERBOSE / UPDATED) ===
print_banner
print_main_progress 6
echo "[6/6] Setting up Python environment and frontend..."

# Yeh function ab live output dikhayega
setup_frontend_verbose() {
    # Pehle rl-swarm directory ke andar jaao
    cd rl-swarm 2>/dev/null || { echo "❌ Error: Directory 'rl-swarm' not found!"; exit 1; }

    echo "➡️  Creating Python virtual environment..."
    python3 -m venv .venv
    echo "✅ Python environment created."
    
    # Ab modal-login directory mein jaao
    cd modal-login 2>/dev/null || { echo "❌ Error: Directory 'modal-login' not found!"; exit 1; }
    
    echo "➡️  ${BOLD}Running 'yarn install'... This may take several minutes depending on your internet speed.${NC}"
    echo "You will see live download progress below."
    yarn install # <-- SILENT FLAG HATA DIYA GAYA
    
    echo "➡️  ${BOLD}Running 'yarn upgrade'...${NC}"
    yarn upgrade # <-- SILENT FLAG HATA DIYA GAYA
    
    echo "➡️  ${BOLD}Running 'yarn add next@latest viem@latest'...${NC}"
    yarn add next@latest viem@latest # <-- SILENT FLAG HATA DIYA GAYA
    
    echo "✅ Frontend setup complete."
    # Wapas main directory mein aa jaao
    cd ../..
}

# Upar banaye gaye function ko yahan chalao
setup_frontend_verbose || handle_error "Failed to set up Python environment or frontend." 6 "[6/6] Setting up environment..."
sleep 2


# === Final Output ===
print_banner
print_main_progress 6
echo
echo "${BOLD}✅ GENSYN SETUP COMPLETE${NC}"
echo "All files are located in: ${BOLD}$(pwd)/rl-swarm${NC}"
echo "${BOLD}🛡️ DEVIL KO THANKS BOLO${NC}"
