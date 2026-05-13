#!/usr/bin/env bash

set -euo pipefail

EMACS_EXECUTABLES=(emacs-31 emacs-30 emacs-29)

for emacs_executable in "${EMACS_EXECUTABLES[@]}"; do
  echo "Starting test run with Emacs executable: $emacs_executable"
  RUN_TESTS_EMACS_EXECUTABLE="$emacs_executable" bin/run-tests.sh "$@"
  echo "Finished test run with Emacs executable: $emacs_executable"
done
