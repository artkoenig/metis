#!/bin/bash
# Runs every test suite in this repo, one after another, and exits 0 only
# when all of them pass. This is the one command behind "the suite is
# green" — a new suite must be added to the list below.
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
suites=(
  test-plugin.sh
  test-loader-removed.sh
  skills/cost/assets/test-token-cost.sh
)

# test-loader-removed.sh's own criterion-4 check runs `bash test.sh` to
# confirm it exits 0. Since test-loader-removed.sh must itself be named
# above (test-plugin.sh's coverage case requires every suite file in the
# tree to be listed here), a plain nested run would re-invoke
# test-loader-removed.sh, which would invoke test.sh again, without end. A
# run that is already nested inside another test.sh run (signalled by
# METIS_TEST_SH_NESTED, exported below so children inherit it) drops only
# the suite that causes the recursion; every other suite still runs for
# real, so nothing is skipped in the top-level run anyone actually invokes.
if [ -n "${METIS_TEST_SH_NESTED:-}" ]; then
  nested=()
  for s in "${suites[@]}"; do
    [ "$s" = "test-loader-removed.sh" ] || nested+=("$s")
  done
  suites=("${nested[@]}")
fi
export METIS_TEST_SH_NESTED=1

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
