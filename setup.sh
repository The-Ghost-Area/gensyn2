#!/bin/bash
#
# GENSYN RL SWARM SETUP SCRIPT - UPDATED ACCORDING TO THE GUIDE
# This script automates the dependency installation and initial setup.
#
set -e # Exit immediately if a command exits with a non-zero status.

# === Configuration ===
TOTAL_STEPS=7
LOG_FILE="/tmp/gensyn_setup_log_$(date +%s).log"
WORK_DIR=~/work

# === Color and Formatting Definitions ===
GREEN=$(tput setaf 2 2>/dev/null) || GREEN=""
NC=$(tput sgr0 2>/dev/null) || NC=""
BOLD=$(tput bold 2>/dev/null) || BOLD=""
RED=$(tput setaf 1 2>/dev/null) || RED=""
YELLOW=$(tput setaf 3 2>/dev/null) || YELLOW=""

# === UI Functions ===
print_banner() {
    clear
    local color
    color=$(tput setaf 33)
    echo "$color"
    echo "██████╗ ███████╗██╗   ██╗██╗██╗     "
    echo "██╔══██╗██╔════╝██║   ██║██║██║     "
    echo "██║  ██║█████╗  ██║   ██║██║██║     "
    echo "██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     "
    echo "██████╔╝███████╗ ╚████╔╝ ██║███████╗"
    echo "╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝"
    echo "${NC}"
    echo "${BOLD}🔥 GENSYN RL SWARM - AUTO SETUP SCRIPT (GUIDE UPDATED) 🔥${NC}"
    echo
}

print_main_progress() {
    local step=$1
    local progress=$(( (step * 100) / TOTAL_STEPS ))
    local filled_len=$(( (progress * 20) / 100 ))
    local empty_len=$(( 20 - filled_len ))
    local bar
    bar=$(printf "%${filled_len}s" | tr ' ' '█')$(printf "%${empty_len}s" | tr ' ' '─')
    echo "Overall Progress: [${GREEN}${bar}${NC}] ${progress}%"
}

# === Core Logic Functions ===
handle_error() {
    local message="$1"
    local step="$2"
    # Ensure the sudo keep-alive loop is killed
    if [[ -n $SUDO_LOOP_PID ]]; then kill "$SUDO_LOOP_PID" 2>/dev/null; fi
    print_banner
    print_main_progress "${step}"
    printf "\n${RED}✖ एक त्रुटि हुई: %s${NC}\n" "${message}"
    echo "--------------------------------------------------"
    echo "  ${BOLD}त्रुटि का विवरण (Error Details from ${LOG_FILE}):${NC}"
    echo "--------------------------------------------------"
    sed 's/^/    /' "${LOG_FILE}"
    echo "--------------------------------------------------"
    echo "${RED}सेटअप बंद हो रहा है। कृपया ऊपर दी गई त्रुटि को ठीक करें और फिर से प्रयास करें।${NC}"
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
    tput civis # Hide cursor
    while [ -d /proc/$pid ]; do
        print_banner
        print_main_progress "${step}"
        printf "\r%s... %s" "${message}" "${spinner[$i]}"
        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.2
    done
    tput cnorm # Show cursor
    wait $pid
    local exit_code=$?
    print_banner
    print_main_progress "${step}"
    if [ $exit_code -eq 0 ]; then
        printf "\r${GREEN}✔ %s... पूरा हुआ।${NC}\n" "${message}"
        sleep 1
    else
        handle_error "${message}" "${step}"
    fi
}

# === Main Script Execution ===
main() {
    print_banner
    echo "${YELLOW}यह स्क्रिप्ट इंस्टॉलेशन के लिए एडमिनिस्ट्रेटर अधिकार (sudo) का उपयोग करेगी।${NC}"
    echo "आगे बढ़ने के लिए कृपया अपना पासवर्ड एक बार दर्ज करें।"
    sudo -v
    # Keep the sudo session alive in the background
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_LOOP_PID=$!
    trap "kill $SUDO_LOOP_PID 2>/dev/null" EXIT
    echo "${GREEN}धन्यवाद! सेटअप शुरू हो रहा है...${NC}"
    echo "सभी विस्तृत लॉग इस फ़ाइल में सहेजे जाएंगे: ${LOG_FILE}"
    sleep 2

    # --- Step 1: System Update & Upgrade ---
    run_with_loader "[1/${TOTAL_STEPS}] सिस्टम पैकेज अपडेट और अपग्रेड करना" 1 \
        "sudo apt-get update -qq && sudo apt-get upgrade -y -qq"

    # --- Step 2: Install General Utilities ---
    run_with_loader "[2/${TOTAL_STEPS}] सामान्य उपयोगिताएँ इंस्टॉल करना" 2 \
        "sudo apt-get install -y -qq screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip"
        
    # --- Step 3: Install Python ---
    run_with_loader "[3/${TOTAL_STEPS}] Python 3, pip और venv इंस्टॉल करना" 3 \
        "sudo apt-get install -y -qq python3 python3-pip python3-venv python3-dev"

    # --- Step 4: Install Node.js (v22) and Yarn ---
    run_with_loader "[4/${TOTAL_STEPS}] Node.js v22 और Yarn इंस्टॉल करना" 4 \
        "curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && \
        sudo apt-get install -y -qq nodejs && \
        sudo npm install -g yarn"

    # --- Step 5: Verify Versions ---
    run_with_loader "[5/${TOTAL_STEPS}] संस्करणों की जाँच करना" 5 \
        "node -v && yarn -v && python3 --version"
    
    # --- Step 6: Clone Gensyn Repository ---
    cd "$WORK_DIR"
    if [ -d "rl-swarm" ]; then
        print_banner
        print_main_progress 6
        echo "${YELLOW}✔ [6/${TOTAL_STEPS}] 'rl-swarm' डायरेक्टरी पहले से मौजूद है, क्लोनिंग को छोड़ रहा है।${NC}"
        sleep 1
    else
        run_with_loader "[6/${TOTAL_STEPS}] Gensyn AI रिपॉजिटरी क्लोन करना" 6 \
            "git clone https://github.com/gensyn-ai/rl-swarm/"
    fi
    
    # --- Step 7: Create Python Virtual Environment ---
    run_with_loader "[7/${TOTAL_STEPS}] Python वर्चुअल एनवायरनमेंट बनाना" 7 \
        "cd rl-swarm && python3 -m venv .venv"

    # --- Final Output ---
    print_banner
    print_main_progress ${TOTAL_STEPS}
    echo
    echo "${GREEN}${BOLD}✅ सेटअप पूरा हुआ! आपका सिस्टम अब तैयार है।${NC}"
    echo
    echo "${YELLOW}${BOLD}--- आगे क्या करना है (IMPORTANT) ---${NC}"
    echo "1. सबसे पहले, आपको एक ${BOLD}HuggingFace Access Token${NC} की आवश्यकता होगी।"
    echo "   अगर आपके पास नहीं है, तो यहाँ बनाएं: ${BOLD}https://huggingface.co/settings/tokens${NC}"
    echo "   टोकन बनाते समय ${BOLD}'write' permission${NC} देना न भूलें।"
    echo
    echo "2. अब, टर्मिनल में ये कमांड एक-एक करके चलाएं:"
    echo "   (a) प्रोजेक्ट डायरेक्टरी में जाएं:"
    echo "       ${GREEN}cd ~/work/rl-swarm${NC}"
    echo
    echo "   (b) नोड को बैकग्राउंड में चलाने के लिए एक स्क्रीन सेशन शुरू करें:"
    echo "       ${GREEN}screen -S swarm${NC}"
    echo
    echo "   (c) अब, नोड को चलाने के लिए यह कमांड चलाएं:"
    echo "       ${GREEN}./run_rl_swarm.sh${NC}"
    echo
    echo "   (यह आपसे आपका HuggingFace टोकन और अन्य जानकारी मांगेगा)।"
    echo
    echo "   (d) स्क्रीन से बाहर आने के लिए (ताकि नोड चलता रहे), दबाएं: ${BOLD}CTRL + A, फिर D${NC}"
    echo "   वापस स्क्रीन में जाने के लिए चलाएं: ${BOLD}screen -r swarm${NC}"
}

# Run the main function
main
