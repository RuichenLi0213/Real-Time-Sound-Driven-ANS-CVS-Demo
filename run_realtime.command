#!/bin/bash
# Real-microphone mode (default).  Double-click in Finder or run: bash run_realtime.command
cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then
  echo "First run: installing (needs internet once)..."
  bash ./setup_macos.sh || { echo; read -r -p "Setup failed. Press Return to close." _; exit 1; }
fi
.venv/bin/python ans_cvs_realtime.py "$@"
