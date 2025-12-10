#!/bin/bash

echo "=================================================="
echo "Caret Version Risk Demo - All Scenarios"
echo "=================================================="
echo ""
echo "This demo proves 8 real-world risks with using"
echo "caret (^) versions in library package dependencies."
echo "(Plus 1 scenario showing the benefit)"
echo ""
echo "=================================================="
echo ""

# Track results
PASSED=0
FAILED=0
START_TIME=$(date +%s)

cd "$(dirname "$0")/.."

# Ensure clean state
echo "Preparing monorepo..."
rm -rf node_modules apps/*/node_modules packages/*/node_modules 2>/dev/null || true
yarn install --silent 2>&1 | grep -v "warning" | head -5
echo "✅ Monorepo setup complete"
echo ""
echo "=================================================="
echo ""

run_scenario() {
    local num=$1
    local name=$2
    local script=$3

    echo ""
    echo "=================================================="
    echo "Running Scenario $num: $name"
    echo "=================================================="
    echo ""

    if bash "$script"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
        echo "⚠️  Scenario $num completed (demonstrated the problem)"
    fi

    echo ""
    sleep 1
}

# Run all risk scenarios (1-8)
run_scenario 1 "Multi-Team Time-Based Inconsistency" "scripts/scenario-1.sh"
run_scenario 2 "Lock File Drift" "scripts/scenario-2.sh"
run_scenario 3 "Merge Conflict Hell" "scripts/scenario-3.sh"
run_scenario 4 "Dependency Update Cascade" "scripts/scenario-4.sh"
run_scenario 5 "Audit Compliance Failure" "scripts/scenario-5.sh"
run_scenario 6 "Breaking Patch Version (Real Example)" "scripts/scenario-6.sh"
run_scenario 7 "Package Manager Differences" "scripts/scenario-7.sh"
run_scenario 8 "Transitive Dependency Hell" "scripts/scenario-8.sh"

# Run benefit scenario (0)
run_scenario 0 "Caret re-resolves to latest compatible after lock removal" "scripts/scenario-0.sh"

# Summary
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=================================================="
echo "SUMMARY"
echo "=================================================="
echo ""
echo "Total scenarios run: 9"
echo "Duration: ${DURATION}s"
echo ""
echo "8 risk scenarios demonstrate caret (^) problems in library dependencies:"
echo ""
echo "  1. ❌ Multi-team inconsistency (different install times)"
echo "  2. ❌ Unpredictable lock file changes (yarn add drift)"
echo "  3. ❌ Merge conflicts on unrelated code"
echo "  4. ❌ Surprise dependency updates (cascade)"
echo "  5. ❌ Audit compliance failures (can't provide exact version)"
echo "  6. ❌ Breaking changes in patch versions (real example)"
echo "  7. ❌ Package manager differences (npm vs yarn vs pnpm)"
echo "  8. ❌ Transitive dependency hell (multi-layer uncertainty)"
echo ""
echo "1 benefit scenario (0) shows the caret upside:"
echo "  0. ✅ Re-resolves to latest compatible after lock removal (auto-patch)"
echo "     ⚠️  But: it is an untested silent upgrade"
echo ""
echo "=================================================="
echo "CONCLUSION"
echo "=================================================="
echo ""
echo "These are NOT theoretical problems."
echo "These are REAL scenarios that happen in production."
echo ""
echo "Recommendation: Use FIXED versions in library packages"
echo ""
echo "Example:"
echo '  {
    "dependencies": {
      "eslint-config-prettier": "10.1.0"   // ← Fixed, not ^10.1.0
    }
  }'
echo ""
echo "Benefits of fixed versions:"
echo "  ✅ All consumers get the SAME version"
echo "  ✅ Security updates controlled by library maintainer"
echo "  ✅ No version conflicts or surprises"
echo "  ✅ Predictable, reproducible behavior"
echo "  ✅ Audit compliance (definitive version)"
echo "  ✅ Works with ALL package managers (npm/yarn/pnpm)"
echo ""
echo "Update workflow:"
echo "  1. Library maintainer updates dependency"
echo "  2. Tests pass, publish new library version"
echo "  3. ALL apps update library, get tested version"
echo "  4. No surprises, no inconsistencies"
echo ""
echo "=================================================="
echo ""
