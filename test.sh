#!/bin/bash
# Runs every test suite in this repo, one after another, and exits 0 only
# when all of them pass. This is the one command behind "the suite is
# green" — a new suite must be added to the list below.
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
suites=(
  test-plugin.sh
  test-install.sh
  skills/bootstrap/assets/test-session-start-core.sh
  skills/bootstrap/assets/test-session-start-loader.sh
  skills/cost/assets/test-token-cost.sh
)

failed=0
for suite in "${suites[@]}"; do
  echo "=== $suite"
  bash "$root/$suite" || { failed=$((failed + 1)); }
  echo
done

if [ "$failed" -eq 0 ]; then
  echo "PASS: all ${#suites[@]} suites"
else
  echo "FAIL: $failed of ${#suites[@]} suite(s)"
  exit 1
fi
