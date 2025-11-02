# AI Running Coach - Arch Linux Edition

## Arch-Specific Notes

### Installation
```bash
# Install dependencies
sudo pacman -S jq python python-pip

# Optional: Install gemini-cli
sudo pacman -S nodejs npm
npm install -g gemini-cli
```

### Gemini CLI Integration

If you have gemini-cli installed, you can enable AI-powered responses:

1. Get API key from https://makersuite.google.com/app/apikey
2. Set environment variable:
```bash
export GEMINI_API_KEY="your-api-key-here"
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
```

3. Enable in config:
```bash
nano config/gemini_config.json
# Set "enabled": true
```

### Differences from Ubuntu Version
- Uses `pacman` instead of `apt-get`
- Date command doesn't use milliseconds
- Python packages installed with `--break-system-packages` flag if needed

### Running on Arch
Everything else works the same:
```bash
./running_coach.sh start
./running_coach.sh chat
```
