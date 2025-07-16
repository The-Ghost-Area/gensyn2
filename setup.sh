#!/bin/bash
#
# GENSYN AUTO SETUP SCRIPT - FIXED VERSION
# This version fixes the freezing issue at Node.js/Yarn setup step
#
set -e # Exit immediately if a command exits with a non-zero status.

# === Configuration ===
TOTAL_STEPS=6
LOG_FILE="/tmp/gensyn_setup_log_$(date +%s).log"
WORK_DIR=~/work

# Clean up old log files to prevent them from piling up
find /tmp -name "gensyn_setup_log_*.log" -mmin +60 -delete > /dev/null 2>&1

# === Color and Formatting Definitions ===
GREEN=$(tput setaf 2 2>/dev/null) || GREEN=""
NC=$(tput sgr0 2>/dev/null) || NC=""
BOLD=$(tput bold 2>/dev/null) || BOLD=""
RED=$(tput setaf 1 2>/dev/null) || RED=""
YELLOW=$(tput setaf 3 2>/dev/null) || YELLOW=""

# === UI Functions ===
print_banner() {
    clear
    local colors=(1 2 3 4 5 6)
    local color
    color=$(tput setaf ${colors[$RANDOM % ${#colors[@]}]})
    echo "$color"
    echo "██████╗ ███████╗██╗   ██╗██╗██╗     "
    echo "██╔══██╗██╔════╝██║   ██║██║██║     "
    echo "██║  ██║█████╗  ██║   ██║██║██║     "
    echo "██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     "
    echo "██████╔╝███████╗ ╚████╔╝ ██║███████╗"
    echo "╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝"
    echo "${NC}"
    echo "${BOLD}🔥 GENSYN AUTO SETUP SCRIPT (FIXED VERSION) 🔥${NC}"
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
    if [[ -n $SUDO_LOOP_PID ]]; then
        kill "$SUDO_LOOP_PID" 2>/dev/null
    fi

    print_banner
    print_main_progress "${step}"
    printf "\n${RED}✖ एक त्रुटि हुई: %s${NC}\n" "${message}"
    echo "--------------------------------------------------"
    echo "  ${BOLD}त्रुटि का विवरण (Error Details from ${LOG_FILE}):${NC}"
    echo "--------------------------------------------------"
    # Indent the log output for readability
    sed 's/^/    /' "${LOG_FILE}"
    echo "--------------------------------------------------"
    echo "${RED}सेटअप बंद हो रहा है। कृपया ऊपर दी गई त्रुटि को ठीक करें और फिर से प्रयास करें।${NC}"
    exit 1
}

run_with_loader() {
    local message="$1"
    local step="$2"
    local command_to_run="$3"
    
    # Add timeout to prevent hanging
    timeout 600 bash -c "eval \"${command_to_run}\"" >> "${LOG_FILE}" 2>&1 &
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
    
    # --- SUDO PASSWORD PRE-AUTHENTICATION ---
    echo "${YELLOW}यह स्क्रिप्ट इंस्टॉलेशन के लिए एडमिनिस्ट्रेटर अधिकार (sudo) का उपयोग करेगी।${NC}"
    echo "कृपया आगे बढ़ने के लिए अपना पासवर्ड एक बार दर्ज करें।"
    sudo -v
    
    # Keep the sudo session alive in the background
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_LOOP_PID=$!
    # Ensure the keep-alive loop is killed on script exit
    trap "kill $SUDO_LOOP_PID 2>/dev/null" EXIT

    echo "${GREEN}धन्यवाद! सेटअप शुरू हो रहा है...${NC}"
    echo "सभी विस्तृत लॉग इस फ़ाइल में सहेजे जाएंगे: ${LOG_FILE}"
    sleep 2

    # --- Step 0: Go to work directory ---
    echo "कार्यशील डायरेक्टरी ${WORK_DIR} में जा रहा है..."
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
    echo "सफलतापूर्वक डायरेक्टरी में: $(pwd)"
    sleep 1

    # --- Step 1: System Update ---
    run_with_loader "[1/${TOTAL_STEPS}] सिस्टम अपडेट और बेस पैकेज इंस्टॉल करना" 1 \
        "sudo apt-get update -qq && sudo apt-get install -y -qq sudo python3 python3-venv python3-pip curl wget screen git lsof nano unzip iproute2 build-essential gcc g++"

    # --- Step 2: CUDA Setup ---
    run_with_loader "[2/${TOTAL_STEPS}] CUDA सेटअप डाउनलोड और चलाना" 2 \
        "rm -f cuda.sh && curl -s -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh && chmod +x cuda.sh && bash ./cuda.sh"

    # --- Step 3: Node.js and Yarn Setup (FIXED) ---
    print_banner
    print_main_progress 3
    echo "[3/${TOTAL_STEPS}] Node.js और Yarn सेटअप करना..."
    
    # Check if Node.js is already installed
    if command -v node &> /dev/null; then
        echo "${GREEN}✔ Node.js पहले से इंस्टॉल है: $(node -v)${NC}"
    else
        echo "➡️  Node.js इंस्टॉल कर रहा है..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >> "${LOG_FILE}" 2>&1
        sudo apt-get update -qq >> "${LOG_FILE}" 2>&1
        sudo apt-get install -y -qq nodejs >> "${LOG_FILE}" 2>&1
        echo "${GREEN}✔ Node.js इंस्टॉल हो गया: $(node -v)${NC}"
    fi

    # Check if Yarn is already installed
    if command -v yarn &> /dev/null; then
        echo "${GREEN}✔ Yarn पहले से इंस्टॉल है: $(yarn -v)${NC}"
    else
        echo "➡️  Yarn इंस्टॉल कर रहा है..."
        # Use npm to install yarn globally (more reliable)
        sudo npm install -g yarn >> "${LOG_FILE}" 2>&1
        echo "${GREEN}✔ Yarn इंस्टॉल हो गया: $(yarn -v)${NC}"
    fi
    
    sleep 2

    # --- Step 4: Version Check ---
    run_with_loader "[4/${TOTAL_STEPS}] इंस्टॉल किए गए संस्करणों की जाँच करना" 4 \
        "node -v && npm -v && yarn -v && python3 --version"

    # --- Step 5: Clone Gensyn Project ---
    if [ -d "rl-swarm" ]; then
        print_banner
        print_main_progress 5
        echo "${GREEN}✔ [5/${TOTAL_STEPS}] 'rl-swarm' डायरेक्टरी पहले से मौजूद है, क्लोनिंग को छोड़ रहा है।${NC}"
        sleep 1
    else
        run_with_loader "[5/${TOTAL_STEPS}] Gensyn AI रिपॉजिटरी क्लोन करना" 5 \
            "git clone --quiet https://github.com/gensyn-ai/rl-swarm.git"
    fi

    # --- Step 6: Setup Base Environment ---
    print_banner
    print_main_progress 6
    echo "[6/${TOTAL_STEPS}] बेस एनवायरनमेंट सेटअप और Yarn पैकेज इंस्टॉल करना..."

    (
        cd rl-swarm || { echo "${RED}Error: 'rl-swarm' डायरेक्टरी नहीं मिली!${NC}"; exit 1; }
        
        echo "➡️  Python वर्चुअल एनवायरनमेंट बना रहा है..."
        python3 -m venv .venv >> "${LOG_FILE}" 2>&1 || { echo "${RED}Python venv बनाने में विफल।${NC}"; exit 1; }
        echo "✅ Python एनवायरनमेंट 'rl-swarm/.venv' में बन गया है।"

        if [ -d "modal-login" ]; then
            (
                cd modal-login || { echo "${RED}Error: 'modal-login' डायरेक्टरी नहीं मिली!${NC}"; exit 1; }
                
                echo "➡️  ${BOLD}'yarn install' चला रहा है... इसमें कुछ मिनट लग सकते हैं।${NC}"
                yarn install --network-timeout 100000
            )
        else
            echo "${YELLOW}Warning: 'modal-login' डायरेक्टरी नहीं मिली, yarn install को छोड़ रहा है।${NC}"
        fi
    )
    
    if [ $? -ne 0 ]; then
        echo "The setup process failed. Please check the output above for errors." >> "${LOG_FILE}"
        handle_error "Environment setup विफल रहा" 6
    fi
    
    echo "${GREEN}✔ Base environment setup पूरा हुआ।${NC}"
    sleep 2
    
    # --- Final Output ---
    print_banner
    print_main_progress ${TOTAL_STEPS}
    echo
    echo "${GREEN}${BOLD}✅ बेस सेटअप पूरा हुआ!${NC}"
    echo "रिपॉजिटरी क्लोन हो गई है और शुरुआती निर्भरताएँ इंस्टॉल हो गई हैं।"
    echo
    echo "${BOLD}--- आगे क्या करें ---${NC}"
    echo "1. प्रोजेक्ट डायरेक्टरी में जाएं:"
    echo "   ${GREEN}cd ~/work/rl-swarm${NC}"
    echo "2. Python एनवायरनमेंट को सक्रिय (activate) करें:"
    echo "   ${GREEN}source .venv/bin/activate${NC}"
    echo "3. अब आप प्रोजेक्ट स्क्रिप्ट चला सकते हैं (जैसे ./run_rl_swarm.sh)"
    echo
    echo "${BOLD}--- डिबगिंग के लिए ---${NC}"
    echo "अगर कोई समस्या आती है, तो लॉग फ़ाइल देखें:"
    echo "   ${GREEN}cat ${LOG_FILE}${NC}"
    echo
}

# Run the main function
main
