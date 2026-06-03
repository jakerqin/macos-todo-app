#!/bin/bash

# Quick development workflow shortcuts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 macOS Todo App - Development Commands${NC}"
echo ""

case "$1" in
    "status"|"s")
        echo -e "${YELLOW}📊 Git Status:${NC}"
        git status --short
        echo ""
        echo -e "${YELLOW}🌿 Current Branch:${NC}"
        git branch --show-current
        echo ""
        echo -e "${YELLOW}🔗 Remote Status:${NC}"
        git remote -v
        ;;

    "commit"|"c")
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please provide a commit message${NC}"
            echo "Usage: ./scripts/dev.sh commit \"your message\""
            exit 1
        fi
        echo -e "${BLUE}📝 Committing changes...${NC}"
        ./scripts/auto-commit.sh "$2"
        ;;

    "push"|"p")
        echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
        git push origin main
        echo -e "${GREEN}✅ Pushed successfully!${NC}"
        ;;

    "pull"|"l")
        echo -e "${BLUE}⬇️  Pulling latest changes...${NC}"
        git pull origin main
        echo -e "${GREEN}✅ Updated successfully!${NC}"
        ;;

    "sync"|"sy")
        echo -e "${BLUE}🔄 Syncing with remote...${NC}"
        git pull origin main
        if [ $? -eq 0 ]; then
            git push origin main
            echo -e "${GREEN}✅ Sync completed!${NC}"
        else
            echo -e "${RED}❌ Sync failed - resolve conflicts first${NC}"
        fi
        ;;

    "clean"|"cl")
        echo -e "${YELLOW}🧹 Cleaning temporary files...${NC}"
        rm -f complete-plan*.txt
        rm -rf .DS_Store
        echo -e "${GREEN}✅ Cleaned up!${NC}"
        ;;

    "open"|"o")
        echo -e "${BLUE}🌐 Opening GitHub repository...${NC}"
        open https://github.com/jakerqin/macos-todo-app
        ;;

    "xcode"|"x")
        echo -e "${BLUE}📱 Opening Xcode project...${NC}"
        if [ -d "TodoApp.xcodeproj" ]; then
            open TodoApp.xcodeproj
        else
            echo -e "${YELLOW}⚠️  Xcode project not found. Run implementation first.${NC}"
        fi
        ;;

    "plan"|"pl")
        echo -e "${BLUE}📋 Opening implementation plan...${NC}"
        open docs/superpowers/plans/2026-06-02-macos-todo-app.md
        ;;

    *)
        echo -e "${GREEN}Available commands:${NC}"
        echo "  status, s     - Show git status and branch info"
        echo "  commit, c     - Commit and push changes (requires message)"
        echo "  push, p       - Push to GitHub"
        echo "  pull, l       - Pull latest changes"
        echo "  sync, sy      - Sync with remote (pull + push)"
        echo "  clean, cl     - Clean temporary files"
        echo "  open, o       - Open GitHub repository"
        echo "  xcode, x      - Open Xcode project"
        echo "  plan, pl      - Open implementation plan"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  ./scripts/dev.sh status"
        echo "  ./scripts/dev.sh commit \"Add new feature\""
        echo "  ./scripts/dev.sh sync"
        ;;
esac