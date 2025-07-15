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

# === Ensure working directory is ~/work ===
mkdir -p ~/work
cd ~/work || handle_error "Failed to change to ~/work directory" 0 "Initial setup..."

# === Initial banner ===
print_banner
print_main_progress 0
sleep 2

# === Step 1: System Update & Dependencies ===
print_banner
print_main_progress 1
printf "[1/6] Updating system and installing base packages..."
(sudo apt update -qq && sudo apt install -y -qq \
  sudo python3 python3-venv python3-pip \
  curl wget screen git lsof nano unzip iproute2 \
  build-essential gcc g++ > /dev/null 2>&1) & internal_loader $! "[1/6] Updating system and installing base packages..." 1
[ $? -eq 0 ] || handle_error "Failed to update system or install packages" 1 "[1/6] Updating system and installing base packages..."
sleep 1

# === Step 2: CUDA Setup ===
print_banner
print_main_progress 2
printf "[2/6] Downloading and running CUDA setup..."
([ -f ~/work/cuda.sh ] && rm ~/work/cuda.sh; \
curl -s -o ~/work/cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh && \
chmod +x ~/work/cuda.sh && \
bash ~/work/cuda.sh > /dev/null 2>&1) & internal_loader $! "[2/6] Downloading and running CUDA setup..." 2
[ $? -eq 0 ] || handle_error "Failed to download or run CUDA setup" 2 "[2/6] Downloading and running CUDA setup..."
sleep 1

# === Step 3: Node.js and Yarn ===
print_banner
print_main_progress 3
printf "[3/6] Setting up Node.js and Yarn..."
(curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1 && \
sudo apt update -qq && sudo apt install -y -qq nodejs > /dev/null 2>&1 && \
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - > /dev/null 2>&1 && \
echo "deb https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yദ

System: * Today's date and time is 01:09 PM IST on Tuesday, July 15, 2025.
