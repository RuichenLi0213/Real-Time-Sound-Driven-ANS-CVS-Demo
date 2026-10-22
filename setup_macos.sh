#!/bin/bash
# =====================================================================
# setup_macos.sh  -  one-time installation for the real-time ANS-CVS program
#
#   bash setup_macos.sh                    create ./.venv and install requirements.txt
#   bash setup_macos.sh --recreate         delete ./.venv first and reinstall
#   bash setup_macos.sh --python=/path/to/python3   use a specific Python (3.9-3.12)
#
# Needs an internet connection the first time (pip downloads about 150 MB).
# Nothing is installed outside this folder.
# =====================================================================
set -e
cd "$(dirname "$0")"
HERE="$(pwd)"
RECREATE=0
PY_ARG=""
for a in "$@"; do
  case "$a" in
    --recreate) RECREATE=1 ;;
    --python=*) PY_ARG="${a#--python=}" ;;
    *) echo "unknown option: $a"; exit 2 ;;
  esac
done

ok_version() {   # Python 3.9 - 3.12 (numba 0.60 supports these)
  "$1" -c 'import sys; sys.exit(0 if (3, 9) <= sys.version_info[:2] <= (3, 12) else 1)' >/dev/null 2>&1
}

find_python() {
  local c
  for c in "$PY_ARG" python3.12 python3.11 python3.10 python3 \
           /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11 /opt/homebrew/bin/python3.10 \
           /usr/local/bin/python3.12 /usr/local/bin/python3.11 /usr/local/bin/python3.10 \
           /Library/Frameworks/Python.framework/Versions/3.12/bin/python3 \
           /Library/Frameworks/Python.framework/Versions/3.11/bin/python3 \
           "$HOME/anaconda3/bin/python3" "$HOME/Anaconda/anaconda3/bin/python3" "$HOME/miniconda3/bin/python3" \
           /usr/bin/python3; do
    [ -z "$c" ] && continue
    if command -v "$c" >/dev/null 2>&1 && ok_version "$c"; then
      command -v "$c"; return 0
    fi
  done
  return 1
}

echo "== ANS-CVS real-time program: setup in $HERE"
if [ "$RECREATE" = "1" ] && [ -d .venv ]; then
  echo "-- removing existing .venv"
  rm -rf .venv
fi

if [ ! -x .venv/bin/python ]; then
  PY="$(find_python)" || {
    echo
    echo "ERROR: no Python 3.9-3.12 found."
    echo "Install Python 3.11 from https://www.python.org/downloads/macos/ (or run: xcode-select --install"
    echo "to get Apple's python3), then run this script again, or pass --python=/path/to/python3."
    exit 1
  }
  echo "-- using $PY ($("$PY" -c 'import sys; print(sys.version.split()[0])'))"
  "$PY" -m venv .venv
fi

echo "-- installing packages into .venv (requirements.txt)"
.venv/bin/python -m pip install --upgrade pip >/dev/null
.venv/bin/python -m pip install -r requirements.txt

echo "-- checking imports"
.venv/bin/python -c "import numpy, scipy, numba, PyQt5.QtCore, pyqtgraph, sounddevice; print('   numpy', numpy.__version__, '| numba', numba.__version__, '| Qt', PyQt5.QtCore.QT_VERSION_STR, '| pyqtgraph', pyqtgraph.__version__, '| sounddevice', sounddevice.__version__)"

echo "-- compiling the model (numba JIT, cached in __pycache__) and checking stable rest"
.venv/bin/python - <<'PYEOF'
import time, numpy as np
t0 = time.time()
import ans_cvs_config as C, ans_cvs_design as D, ans_cvs_model as M
params, d = D.derive()
mod, out = D.rest_model(params, d, spinup_s=10.0, settle_s=10.0)
hr = out[-200:, M.OC['HR_bpm']].mean(); mp = out[-200:, M.OC['MAP_mean']].mean()
print('   rest HR %.2f bpm (target %.2f), MAP %.2f mmHg (target %.2f), done in %.1f s'
      % (hr, C.HR_REST_BPM, mp, C.MAP_REST_MMHG, time.time() - t0))
assert abs(hr - C.HR_REST_BPM) < 0.1 and abs(mp - C.MAP_REST_MMHG) < 0.1, 'model self-check failed'
PYEOF

chmod +x run_realtime.command run_test_mode.command run_model_tests.command run_microphone_check.command 2>/dev/null || true
echo
echo "Setup complete. Next:"
echo "   bash run_model_tests.command      (optional, no microphone)"
echo "   bash run_realtime.command         (real microphone, default mode)"
echo "   bash run_test_mode.command        (simulated stimuli, microphone not used)"
