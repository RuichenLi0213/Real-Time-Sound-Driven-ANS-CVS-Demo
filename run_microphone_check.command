#!/bin/bash
# REAL MICROPHONE check (10 s): opens the default input, prints device, sample rate and levels.
# Nothing is simulated; an onset is reported only if the room sound really exceeds the threshold.
cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then
  bash ./setup_macos.sh || exit 1
fi
.venv/bin/python test_audio_detector.py --live 10 "$@"
[ -t 0 ] && read -r -p "Press Return to close." _
