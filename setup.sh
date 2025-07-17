#!/bin/bash

# ==============================================================================
# Gensyn Node Installation Script
# Yeh script aapke diye gaye guide ke anusaar Gensyn Node ke liye zaroori
# dependencies, CUDA, Node.js, Yarn, aur project setup karti hai.
# ==============================================================================

# Script ko fail hone par turant rokne ke liye
set -e

# Screen par message dikhane ke liye helper function
log() {
  echo "=============================================================================="
  echo " $1"
  echo "=============================================================================="
}

# Step 1: System Dependencies Install Karna
log "Step 1: System ko update aur zaroori packages install kiye ja rahe hain..."
sudo apt-get update
sudo apt-get install -y \
  python3 \
  python3-venv \
  python3-pip \
  curl \
  wget \
  screen \
  git \
  lsof \
  nano \
  unzip \
  iproute2 \
  build-essential \
  gcc \
  g++ \
  ca-certificates \
  gnupg

# Step 2: CUDA Install Karna
log "Step 2: NVIDIA CUDA Toolkit install kiya ja raha hai..."
if [ -f cuda.sh ]; then
  rm cuda.sh
fi
curl -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh
chmod +x cuda.sh
# 'source' ya '.' command script ke andar seedhe kaam nahi karega, 
# isliye hum ise subshell mein chalayenge taki environment set ho sake.
# Lekin guide ke anusaar, ise seedhe chalana zaroori hai.
# Dhyan dein: Yeh aapke system par NVIDIA drivers aur CUDA install karega.
. ./cuda.sh

# Step 3: Node.js aur Yarn Install Karna
log "Step 3: Node.js (v20.x) aur Yarn install kiye ja rahe hain..."

# Node.js setup
log "Node.js repository set kiya ja raha hai..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Yarn setup (apt-key deprecated hai, isliye naya tareeka use kiya gaya hai)
log "Yarn repository set kiya ja raha hai..."
sudo mkdir -p /etc/apt/keyrings
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/yarnkey.gpg
echo "deb [signed-by=/etc/apt/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Node.js aur Yarn install
sudo apt-get update
sudo apt-get install -y nodejs yarn

# Step 4: Installation Versions Verify Karna
log "Step 4: Installation versions check kiye ja rahe hain..."
echo -n "Node.js version: " && node -v
echo -n "NPM version: " && npm -v
echo -n "Yarn version: " && yarn -v
echo -n "Python version: " && python3 --version

# Step 5: Gensyn Project Setup Karna
log "Step 5: Gensyn rl-swarm repository clone aur setup kiya ja raha hai..."
# Agar directory pehle se hai to use delete kar dein
if [ -d "rl-swarm" ]; then
  log "'rl-swarm' directory pehle se maujood hai. Ise hataya ja raha hai..."
  rm -rf rl-swarm
fi
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

# Step 6: Python Virtual Environment aur Modal Login Setup
log "Step 6: Python venv aur modal-login dependencies install kiye ja rahe hain..."
python3 -m venv .venv
source .venv/bin/activate

# Ab modal-login directory mein Yarn packages install karein
cd modal-login
yarn install
yarn upgrade
yarn add next@latest
yarn add viem@latest
cd ..

# Deactivate venv (script ke ant mein aadat ke taur par)
deactivate

log "Installation aur setup poora ho gaya hai!"
echo
echo "Ab aapko manual roop se 'screen' session shuru karna hai aur aage ke steps karne hain."
echo "Commands:"
echo "1. screen -S gensyn"
echo "2. cd rl-swarm"
echo "3. source .venv/bin/activate"
echo "Iske baad aap Gensyn ke documentation ke anusaar aage badh sakte hain."
