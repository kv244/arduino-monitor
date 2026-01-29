#!/bin/bash
# Git Commit Script for Arduino Monitor
# This script will help you commit the code to GitHub

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Arduino Monitor - Git Commit Helper${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Error: git is not installed${NC}"
    echo "Please install git first: https://git-scm.com/downloads"
    exit 1
fi

# Initialize git repository if not already done
if [ ! -d .git ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    echo ""
fi

# Show current status
echo -e "${GREEN}Current git status:${NC}"
git status
echo ""

# Add all files
echo -e "${YELLOW}Adding files to git...${NC}"
git add .
echo ""

# Show what will be committed
echo -e "${GREEN}Files to be committed:${NC}"
git status
echo ""

# Prompt for commit message
echo -e "${YELLOW}Enter commit message (or press Enter for default):${NC}"
read -r commit_msg

if [ -z "$commit_msg" ]; then
    commit_msg="Arduino UNO Monitor - Improved version with bug fixes and safety features"
fi

# Commit
echo -e "${YELLOW}Committing changes...${NC}"
git commit -m "$commit_msg"
echo ""

# Instructions for GitHub
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Next steps to push to GitHub:${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "1. Create a new repository on GitHub:"
echo "   https://github.com/new"
echo ""
echo "2. Set the remote URL (replace YOUR_USERNAME and REPO_NAME):"
echo "   git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git"
echo ""
echo "3. Push to GitHub:"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo -e "${YELLOW}Or if you prefer SSH:${NC}"
echo "   git remote add origin git@github.com:YOUR_USERNAME/REPO_NAME.git"
echo ""
echo -e "${GREEN}Repository is ready to push!${NC}"
