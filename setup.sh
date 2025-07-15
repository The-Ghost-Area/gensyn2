#!/bin/bash
set -e

# === डायरेक्टरी और लॉग सेटअप ===
WORK_DIR=~/work
LOG_DIR=/tmp/gensyn-setup-logs
mkdir -p "$WORK_DIR"
mkdir -p "$LOG_DIR"
cd "$WORK_DIR" || exit 1

# === कलर और फॉर्मेटिंग परिभाषाएँ ===
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)
BOLD=$(tput bold)

# === बैनर के लिए रैंडम कलर ===
get_random_color() {
    colors=(1 2 3 4 5 6 9 10 11 12 13 14 21 27 33 39 45 51 81 87 123 129 165 201)
    echo "$(tput setaf ${colors[$RANDOM % ${#colors[@]}]})"
}

# === बैनर प्रिंट करें ===
print_banner() {
    clear
    local color
    color=$(get_random_color)
    echo "$color"
    echo "██████╗ ███████╗██╗   ██╗██╗██╗     "
    echo "██╔══██╗██╔════╝██║   ██║██║██║     "
    echo "██║  ██║█████╗  ██║   ██║██║██║     "
    echo "██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     "
    echo "██████╔╝███████╗ ╚████╔╝ ██║███████╗"
    echo "╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝"
    echo "${NC}"
    echo "${BOLD}🔥 GENSYN AUTO SETUP SCRIPT BY DEVIL 🔥${NC}"
    echo ""
}

# === मुख्य प्रोग्रेस बार ===
print_main_progress() {
    local step=$1
    local total_steps=6
    local progress=$(( (step * 100) / total_steps ))
    local filled=$(( progress / 5 ))
    local empty=$(( 20 - filled ))
    # shellcheck disable=SC2059
    local bar=$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s" | tr ' ' '-')
    echo "Overall Progress: [$bar] $progress%"
}

# === त्रुटि संभालने वाला फंक्शन ===
handle_error() {
    local message="$1"
    local log_file="$2"
    
    echo ""
    echo "${RED}${BOLD}✖ Error: $message${NC}"
    echo "Gensyn setup failed."
    echo "Please check the log file for details: ${BOLD}$log_file${NC}"
    echo "Exiting setup. Please fix the issue and retry."
    exit 1
}

# === कमांड चलाने और दिखाने वाला फंक्शन ===
run_command() {
    local step_num="$1"
    local total_steps="$2"
    local message="$3"
    local command_to_run="$4"
    local log_file="$5"
    
    local earth_spin=("🌍" "🌎" "🌏")
    local i=0
    
    # कमांड को बैकग्राउंड में चलाएं और उसका आउटपुट लॉग फाइल में डालें
    eval "$command_to_run" > "$log_file" 2>&1 &
    local pid=$!

    # जब तक कमांड चल रहा है, लोडर दिखाएं
    while kill -0 $pid 2>/dev/null; do
        print_banner
        print_main_progress "$step_num"
        printf "\r[%d/%d] %s... %s" "$step_num" "$total_steps" "$message" "${earth_spin[$i]}"
        i=$(( (i + 1) % ${#earth_spin[@]} ))
        sleep 0.2
    done

    # कमांड के एग्जिट स्टेटस को जांचें
    if wait $pid; then
        print_banner
        print_main_progress "$step_num"
        printf "\r[%d/%d] %s... ${GREEN}Done${NC} %s\n" "$step_num" "$total_steps" "$message" "✔️"
        sleep 1
    else
        print_banner
        print_main_progress "$step_num"
        printf "\r[%d/%d] %s... ${RED}Failed${NC} %s\n" "$step_num" "$total_steps" "$message" "✖"
        handle_error "$message failed" "$log_file"
    fi
}

# --- स्क्रिप्ट का मुख्य भाग ---

# === प्रारंभिक बैनर ===
print_banner
print_main_progress 0
sleep 2

# === स्टेप 1: सिस्टम अपडेट और निर्भरताएँ ===
LOG_FILE_1="$LOG_DIR/01-dependencies.log"
CMD1="sudo apt-get update -qq && sudo apt-get install -y -qq \
  sudo python3 python3-venv python3-pip curl wget screen git lsof nano unzip \
  iproute2 build-essential gcc g++ ca-certificates gnupg"
run_command 1 6 "Updating system and installing base packages" "$CMD1" "$LOG_FILE_1"

# === स्टेप 2: CUDA सेटअप ===
LOG_FILE_2="$LOG_DIR/02-cuda-setup.log"
CMD2="curl -s -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh && \
      chmod +x cuda.sh && \
      bash ./cuda.sh"
run_command 2 6 "Downloading and running CUDA setup" "$CMD2" "$LOG_FILE_2"

# === स्टेप 3: Node.js और Yarn ===
LOG_FILE_3="$LOG_DIR/03-node-yarn.log"
CMD3="sudo mkdir -p /etc/apt/keyrings && \
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
      curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
      echo 'deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main' | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null && \
      sudo apt-get update -qq && \
      sudo apt-get install -y -qq nodejs yarn"
run_command 3 6 "Setting up Node.js and Yarn" "$CMD3" "$LOG_FILE_3"

# === स्टेप 4: GoLang सेटअप ===
LOG_FILE_4="$LOG_DIR/04-golang.log"
CMD4="wget -qO go.tar.gz https://go.dev/dl/go1.20.13.linux-amd64.tar.gz && \
      sudo rm -rf /usr/local/go && \
      sudo tar -C /usr/local -xzf go.tar.gz && \
      rm go.tar.gz && \
      echo 'export PATH=\$PATH:/usr/local/go/bin' >> ~/.profile && \
      source ~/.profile"
run_command 4 6 "Installing GoLang" "$CMD4" "$LOG_FILE_4"
export PATH=$PATH:/usr/local/go/bin # वर्तमान सेशन के लिए पाथ सेट करें

# === स्टेप 5: Gensyn रिपॉजिटरी क्लोन करना ===
LOG_FILE_5="$LOG_DIR/05-gensyn-clone.log"
CMD5="git clone https://github.com/gensyn/go-gensyn"
run_command 5 6 "Cloning Gensyn repository" "$CMD5" "$LOG_FILE_5"

# === स्टेप 6: निर्भरताएँ इंस्टॉल करना ===
LOG_FILE_6="$LOG_DIR/06-gensyn-install.log"
CMD6="cd go-gensyn && make deps"
run_command 6 6 "Installing Gensyn dependencies" "$CMD6" "$LOG_FILE_6"

# === समापन संदेश ===
print_banner
print_main_progress 6
echo "${GREEN}${BOLD}🎉 Gensyn setup completed successfully! 🎉${NC}"
echo ""
echo "You can now proceed with further Gensyn instructions."
