#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" || exit 1
bash test-osobni.sh && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
