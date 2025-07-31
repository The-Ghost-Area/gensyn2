#!/bin/bash

set -e

echo "🔄 Updating system packages..."
apt update && apt upgrade -y

echo "🛠️ Installing general utilities and tools..."
apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano \
  automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev \
  tar clang bsdmainutils ncdu unzip

echo "🐍 Installing Python and related packages..."
apt install -y python3 python3-pip python3-venv python3-dev

echo "⬇️ Installing Node.js (v22)..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
node -v

echo "📦 Installing Yarn (via npm)..."
npm install -g yarn
yarn -v

echo "🧶 Reinstalling Yarn via official script (optional)..."
curl -o- -L https://yarnpkg.com/install.sh | bash
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
source ~/.bashrc || true

echo "📁 Cloning Gensyn RL-Swarm repository..."
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

echo "🐍 Creating and activating virtual environment..."
python3 -m venv .venv
source .venv/bin/activate || . .venv/bin/activate

echo "🚀 Running RL Swarm setup..."
./run_rl_swarm.sh
