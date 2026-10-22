#!/bin/bash
# TEST MODE: simulated stimuli from buttons, the microphone is NOT opened.
cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then
  echo "First run: installing (needs internet once)..."
  bash ./setup_macos.sh || { echo; read -r -p "Setup failed. Press Return to close." _; exit 1; }
fi
.venv/bin/python ans_cvs_realtime.py --test-mode "$@"
