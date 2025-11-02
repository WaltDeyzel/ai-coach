#!/bin/bash

# Gemini CLI Integration Helper
# This script enables AI-powered responses using gemini-cli

export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

check_gemini_available() {
    if ! command -v gemini &> /dev/null; then
        echo -e "${RED}✗${NC} gemini-cli not found"
        echo ""
        echo "Install with:"
        echo "  ${CYAN}sudo pacman -S nodejs npm${NC}"
        echo "  ${CYAN}npm install -g gemini-cli${NC}"
        echo ""
        echo "Or with yay:"
        echo "  ${CYAN}yay -S gemini-cli${NC}"
        return 1
    fi
    
    if [ -z "${GEMINI_API_KEY}" ]; then
        echo -e "${YELLOW}⚠${NC}  GEMINI_API_KEY not set"
        echo ""
        echo "Get your API key from: https://makersuite.google.com/app/apikey"
        echo ""
        echo "Then set it:"
        echo "  ${CYAN}export GEMINI_API_KEY='your-api-key-here'${NC}"
        echo "  ${CYAN}echo 'export GEMINI_API_KEY=\"your-key\"' >> ~/.bashrc${NC}"
        return 1
    fi
    
    return 0
}

enable_gemini() {
    echo -e "${CYAN}Enabling Gemini CLI Integration...${NC}\n"
    
    if ! check_gemini_available; then
        return 1
    fi
    
    # Update config
    local config_file="${PROJECT_ROOT}/config/gemini_config.json"
    
    if [ -f "${config_file}" ]; then
        # Enable gemini in config
        jq '.enabled = true' "${config_file}" > "${config_file}.tmp"
        mv "${config_file}.tmp" "${config_file}"
        
        echo -e "${GREEN}✓${NC} Gemini integration enabled in config"
    fi
    
    # Update system config
    local sys_config="${PROJECT_ROOT}/config/system_config.json"
    if [ -f "${sys_config}" ]; then
        jq '.gemini_integration.enabled = true' "${sys_config}" > "${sys_config}.tmp"
        mv "${sys_config}.tmp" "${sys_config}"
        
        echo -e "${GREEN}✓${NC} System configuration updated"
    fi
    
    echo ""
    echo -e "${GREEN}Gemini CLI is now enabled!${NC}"
    echo ""
    echo "Restart your agents for changes to take effect:"
    echo "  ${CYAN}./running_coach.sh restart${NC}"
}

disable_gemini() {
    echo -e "${CYAN}Disabling Gemini CLI Integration...${NC}\n"
    
    local config_file="${PROJECT_ROOT}/config/gemini_config.json"
    
    if [ -f "${config_file}" ]; then
        jq '.enabled = false' "${config_file}" > "${config_file}.tmp"
        mv "${config_file}.tmp" "${config_file}"
        
        echo -e "${GREEN}✓${NC} Gemini integration disabled"
    fi
    
    local sys_config="${PROJECT_ROOT}/config/system_config.json"
    if [ -f "${sys_config}" ]; then
        jq '.gemini_integration.enabled = false' "${sys_config}" > "${sys_config}.tmp"
        mv "${sys_config}.tmp" "${sys_config}"
        
        echo -e "${GREEN}✓${NC} System configuration updated"
    fi
    
    echo ""
    echo "Restart your agents for changes to take effect:"
    echo "  ${CYAN}./running_coach.sh restart${NC}"
}

test_gemini() {
    echo -e "${CYAN}Testing Gemini CLI...${NC}\n"
    
    if ! check_gemini_available; then
        return 1
    fi
    
    echo "Sending test prompt to Gemini..."
    echo ""
    
    local test_prompt="You are a running coach. Respond with exactly: 'Gemini CLI is working! Ready to help with your training.'"
    
    local response=$(gemini "${test_prompt}" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Gemini CLI Response:"
        echo ""
        echo "${response}"
        echo ""
        echo -e "${GREEN}✓${NC} Test successful!"
    else
        echo -e "${RED}✗${NC} Test failed"
        echo "Error: ${response}"
        return 1
    fi
}

show_status() {
    echo -e "${CYAN}Gemini CLI Integration Status${NC}\n"
    
    # Check if gemini-cli is installed
    if command -v gemini &> /dev/null; then
        echo -e "  gemini-cli:       ${GREEN}✓ Installed${NC}"
        gemini --version 2>/dev/null || echo "    (version unknown)"
    else
        echo -e "  gemini-cli:       ${RED}✗ Not Installed${NC}"
    fi
    
    # Check API key
    if [ -n "${GEMINI_API_KEY}" ]; then
        local masked_key="${GEMINI_API_KEY:0:8}...${GEMINI_API_KEY: -4}"
        echo -e "  API Key:          ${GREEN}✓ Set${NC} (${masked_key})"
    else
        echo -e "  API Key:          ${RED}✗ Not Set${NC}"
    fi
    
    # Check config
    local config_file="${PROJECT_ROOT}/config/gemini_config.json"
    if [ -f "${config_file}" ]; then
        local enabled=$(jq -r '.enabled' "${config_file}")
        if [ "${enabled}" = "true" ]; then
            echo -e "  Configuration:    ${GREEN}✓ Enabled${NC}"
        else
            echo -e "  Configuration:    ${YELLOW}○ Disabled${NC}"
        fi
    else
        echo -e "  Configuration:    ${RED}✗ Not Found${NC}"
    fi
    
    echo ""
}

show_help() {
    echo "Gemini CLI Integration Helper"
    echo ""
    echo "Usage: $0 {enable|disable|test|status}"
    echo ""
    echo "Commands:"
    echo "  enable   - Enable Gemini CLI integration"
    echo "  disable  - Disable Gemini CLI integration"
    echo "  test     - Test Gemini CLI connection"
    echo "  status   - Show integration status"
    echo ""
    echo "Setup:"
    echo "  1. Install gemini-cli:"
    echo "     sudo pacman -S nodejs npm"
    echo "     npm install -g gemini-cli"
    echo ""
    echo "  2. Get API key from:"
    echo "     https://makersuite.google.com/app/apikey"
    echo ""
    echo "  3. Set API key:"
    echo "     export GEMINI_API_KEY='your-key-here'"
    echo "     echo 'export GEMINI_API_KEY=\"your-key\"' >> ~/.bashrc"
    echo ""
    echo "  4. Enable integration:"
    echo "     $0 enable"
    echo ""
}

case "${1}" in
    enable)
        enable_gemini
        ;;
    disable)
        disable_gemini
        ;;
    test)
        test_gemini
        ;;
    status)
        show_status
        ;;
    *)
        show_help
        exit 1
        ;;
esac
