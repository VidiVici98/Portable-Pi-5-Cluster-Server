#!/bin/bash

################################################################################
# Cluster Dashboard Launcher
# Start the tactical operations web interface
################################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="$SCRIPT_DIR/venv"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cluster Command & Control Dashboard      ║${NC}"
echo -e "${BLUE}║  Tactical Operations Interface            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check Python
if ! command -v python3 &>/dev/null; then
    echo "Error: Python 3 not found"
    exit 1
fi

# Create venv if needed
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

# Install requirements
if [ ! -f "$VENV_DIR/lib/python*/site-packages/flask.py" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install -q -r "$SCRIPT_DIR/requirements.txt"
fi

# Export environment variables
export FLASK_APP="$SCRIPT_DIR/app.py"
export FLASK_ENV="${FLASK_ENV:-development}"
export DEBUG="${DEBUG:-True}"
export DEMO_MODE="${DEMO_MODE:-True}"
export HOST="${HOST:-127.0.0.1}"
export PORT="${PORT:-5000}"

# Show configuration
echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  Demo Mode: $DEMO_MODE"
echo "  Debug: $DEBUG"
echo ""
echo -e "${GREEN}Access Dashboard:${NC}"
echo "  http://$HOST:$PORT"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Check if port is already in use
if netstat -tuln 2>/dev/null | grep -q ":$PORT " || lsof -i ":$PORT" 2>/dev/null | grep -q LISTEN; then
    echo -e "${YELLOW}Warning: Port $PORT is already in use${NC}"
    echo "Waiting 2 seconds for cleanup..."
    sleep 2
fi

# Start Flask
cd "$SCRIPT_DIR"
"$VENV_DIR/bin/python3" app.py
