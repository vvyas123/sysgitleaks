#!/bin/bash

# Script to install gitleaks pre-commit hooks in existing repositories
# Based on git-secrets update-all-repos.sh

# Usage examples:
#   ./update-all-repos.sh                    # Updates all repos in current directory
#   ./update-all-repos.sh ~/Projects         # Updates all repos in ~/Projects
#   ./update-all-repos.sh ~/Sites ~/Projects # Updates repos in multiple directories

HIGHLIGHT="\e[01;34m"
SUCCESS="\e[01;32m"
ERROR="\e[01;31m"
NORMAL='\e[00m'

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo -e "${ERROR}Error: gitleaks is not installed${NORMAL}"
    echo "Please install gitleaks first:"
    echo "  • macOS: brew install gitleaks"
    echo "  • Linux: Download from https://github.com/gitleaks/gitleaks/releases"
    echo "  • Go: go install github.com/gitleaks/gitleaks/v8@latest"
    exit 1
fi

# Check if global template is set up
TEMPLATE_DIR="$HOME/.git-template"
if [ ! -d "$TEMPLATE_DIR/hooks" ]; then
    echo -e "${ERROR}Error: Git template directory not found${NORMAL}"
    echo "Please run ./install-gitleaks-global.sh first"
    exit 1
fi

function update_repo {
  local d="$1"
  
  # Skip if not a directory or is a symbolic link
  if [ ! -d "$d" ] || [ -L "$d" ]; then
    return 0
  fi
  
  # Try to enter directory, return if fails
  cd "$d" > /dev/null 2>&1 || return 0
  
  if [ -d ".git" ]; then
    printf "%b\n" "${HIGHLIGHT}Installing gitleaks hooks in $(pwd)${NORMAL}"
    
    # Check if this repo uses Husky
    if [ -d ".husky" ] || [ -f "package.json" ] && grep -q "husky" package.json 2>/dev/null; then
      echo -e "  ${HIGHLIGHT}⚠${NORMAL}  Detected Husky - skipping (Husky manages its own hooks)"
      echo -e "  ${HIGHLIGHT}→${NORMAL} For Husky repos, use server-side protection:"
      echo -e "     • GitHub Actions: https://github.com/gitleaks/gitleaks-action"
      echo -e "     • GitLab CI: Add gitleaks to .gitlab-ci.yml"
      echo -e "     • Or manually add gitleaks to .husky/pre-commit (not recommended)"
    else
      # Standard git hooks installation
      mkdir -p .git/hooks 2>/dev/null || {
        echo -e "  ${ERROR}✗${NORMAL} Failed to create hooks directory"
        cd .. > /dev/null 2>&1
        return 1
      }
      
      # Copy hooks from template
      if [ -f "$TEMPLATE_DIR/hooks/pre-commit" ]; then
        cp "$TEMPLATE_DIR/hooks/pre-commit" .git/hooks/pre-commit 2>/dev/null && \
        chmod +x .git/hooks/pre-commit 2>/dev/null && \
        echo -e "  ${SUCCESS}✓${NORMAL} Installed pre-commit hook"
      fi
      
      if [ -f "$TEMPLATE_DIR/hooks/commit-msg" ]; then
        cp "$TEMPLATE_DIR/hooks/commit-msg" .git/hooks/commit-msg 2>/dev/null && \
        chmod +x .git/hooks/commit-msg 2>/dev/null && \
        echo -e "  ${SUCCESS}✓${NORMAL} Installed commit-msg hook"
      fi
      
      # Test the installation
      if [ -x .git/hooks/pre-commit ]; then
        echo -e "  ${SUCCESS}✓${NORMAL} Hooks are executable and ready"
      else
        echo -e "  ${ERROR}✗${NORMAL} Warning: Hooks may not be executable"
      fi
    fi
  else
    # Not a git repo, scan subdirectories (but with protection)
    scan_dirs * 2>/dev/null || true
  fi
  
  cd .. > /dev/null 2>&1 || true
}

function scan_dirs {
  for x in "$@"; do
    # Skip hidden directories and problematic directories
    if [[ "$x" == .* ]] || [[ "$x" == "__MACOSX" ]] || [[ "$x" == "node_modules" ]]; then
      continue
    fi
    update_repo "$x" || true  # Continue even if update_repo fails
  done
}

function update_directory {
  if [ "$1" != "" ]; then 
    cd "$1" > /dev/null 2>&1 || {
      echo -e "${ERROR}✗${NORMAL} Cannot access directory: $1"
      return 1
    }
  fi
  printf "%b\n" "${HIGHLIGHT}Scanning ${PWD} for git repositories...${NORMAL}\n"
  scan_dirs * 2>/dev/null || true
}

# Main execution
echo -e "${HIGHLIGHT}========================================${NORMAL}"
echo -e "${HIGHLIGHT}Gitleaks Hook Installer${NORMAL}"
echo -e "${HIGHLIGHT}========================================${NORMAL}\n"

if [ "$1" == "" ]; then
  update_directory
else
  for dir in "$@"; do
    update_directory "$dir"
  done
fi

echo -e "\n${SUCCESS}========================================${NORMAL}"
echo -e "${SUCCESS}Update Complete!${NORMAL}"
echo -e "${SUCCESS}========================================${NORMAL}\n"

echo -e "${HIGHLIGHT}Summary:${NORMAL}"
echo "  • Gitleaks pre-commit hooks have been installed in all git repositories"
echo "  • Future commits will be scanned for blockchain private keys and secrets"
echo ""
echo -e "${HIGHLIGHT}Test the hooks:${NORMAL}"
echo "  cd /path/to/any/repo"
echo "  echo 'const key = \"abc\"' > test.js"
echo "  git add test.js"
echo "  git commit -m 'test' # Add a real secret to test blocking"
echo ""
