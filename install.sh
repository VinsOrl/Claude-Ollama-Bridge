#!/usr/bin/env bash

# Color codes for terminal output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}Starting claude-ollama installation for Unix/macOS...${NC}"

# 1. Detect the correct profile file (Zsh vs Bash)
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    PROFILE="$HOME/.zshrc"
else
    PROFILE="$HOME/.bashrc"
fi

echo "Targeting profile: $PROFILE"

# 2. Ensure profile exists
if [ ! -f "$PROFILE" ]; then
    touch "$PROFILE"
fi

# 3. Define the function payload exactly as it will appear in the profile
PAYLOAD=$(cat << 'EOF'

# --- claude-ollama start ---
claude-ollama() {
  # Fetch models and strip Windows carriage returns
  local models=($(ollama list | awk 'NR>1 {print $1}' | tr -d '\r'))

  if [ ${#models[@]} -eq 0 ]; then
    echo -e "\033[0;31mError: No Ollama models found.\033[0m"
    return 1
  fi

  echo -e "\n\033[0;36m--- Choose your model ---\033[0m"
  PS3="Select a model (number): "
  select selected_model in "${models[@]}"; do
    if [ -n "$selected_model" ]; then
      local model=$selected_model
      break
    else
      echo -e "\033[0;31mInvalid selection.\033[0m"
    fi
  done

  echo -e "\n\033[0;36m--- Session Options ---\033[0m"
  echo "1) Start a New Session"
  echo "2) Resume an Existing Session"
  printf "Select an option (1 or 2): "
  read session_choice

  export ANTHROPIC_BASE_URL="http://localhost:11434"
  export ANTHROPIC_API_KEY="ollama"

  if [ "$session_choice" = "1" ]; then
    echo -e "\033[0;32mStarting new session with $model...\033[0m"
    claude --model "$model"
  elif [ "$session_choice" = "2" ]; then
    printf "Enter Session ID (Leave blank for latest): "
    read session_id
    if [ -z "$session_id" ]; then
      echo -e "\033[0;32mResuming latest session with $model...\033[0m"
      claude --model "$model" --continue
    else
      echo -e "\033[0;32mResuming session $session_id with $model...\033[0m"
      claude --model "$model" --resume "$session_id"
    fi
  else
    echo -e "\033[0;31mInvalid choice. Exiting.\033[0m"
  fi
}
# --- claude-ollama end ---
EOF
)

# 4. Auto-Update Logic
if grep -q "# --- claude-ollama start ---" "$PROFILE"; then
    echo -e "${YELLOW}Old version detected. Updating to new version...${NC}"
    sed -i.bak '/# --- claude-ollama start ---/,/# --- claude-ollama end ---/d' "$PROFILE"
    rm -f "${PROFILE}.bak"
else
    echo -e "${GREEN}Fresh Installation detected.${NC}"
fi

# 5. Inject the code
echo "$PAYLOAD" >> "$PROFILE"

echo -e "${GREEN}Installation Successful!${NC}"
echo -e "Please restart your terminal, or run: ${CYAN}source $PROFILE${NC}"
