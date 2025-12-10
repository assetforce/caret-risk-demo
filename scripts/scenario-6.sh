#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 6: Breaking Patch Version (REAL EXAMPLE)"
echo "==========================================="
echo ""
echo "Problem: PATCH version has breaking change"
echo "         eslint-config-prettier 10.1.0 → 10.1.1"
echo "         Import path changed (documented in CHANGELOG)"
echo ""
echo "Reference:"
echo "https://github.com/prettier/eslint-config-prettier/blob/07829b4912d173986610a4985247896b09f9fcaf/CHANGELOG.md#patch-changes-4"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
APP_DIR="$REPO_ROOT/apps/scenario-6-breaking-patch"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
echo ""

echo "Simulating real-world scenario..."
echo ""

# ===== Developer A (January) =====
echo "Developer A (January 2025, installs v10.1.0):"

setup_shared_dep_version "10.1.0" "v10.1.0/index.js"

cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-6-breaking-patch",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

echo "   Testing code..."
(cd "$REPO_ROOT" && node -e "
const lib = require('@demo/eslint-config');
const result = lib.test();
if (result.success) {
  console.log('   ✅ Code works with v' + result.dependencyVersion);
} else {
  console.log('   ❌ Code breaks with v' + result.dependencyVersion);
  console.log('   Error:', result.error.substring(0, 80));
}
" 2>&1)

echo ""

# ===== Developer B (February) =====
echo "Developer B (February 2025, installs v10.1.1):"

setup_shared_dep_version "10.1.1" "v10.1.1/index.js"

cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-6-breaking-patch",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

echo "   Testing same code..."
(cd "$REPO_ROOT" && node -e "
const lib = require('@demo/eslint-config');
const result = lib.test();
if (result.success) {
  console.log('   ✅ Code works with v' + result.dependencyVersion);
} else {
  console.log('   ❌ Code breaks with v' + result.dependencyVersion);
  console.log('   Error:', result.error.substring(0, 80) + '...');
}
" 2>&1)

echo ""
echo "==========================================="
echo "Result:"
echo "  ❌ SAME code, DIFFERENT behavior!"
echo "  Same package.json range (^10.1.0)"
echo "  Same library code"
echo "  Different install time = different result"
echo ""
echo "Real-world impact:"
echo "  - Dev A: Passes CI, merges PR"
echo "  - Dev B: Fails CI, can't figure out why"
echo "  - Lost productivity: 4+ hours debugging"
echo ""
echo "Root Cause: Caret (^) allowed patch update"
echo "           v10.1.1 had breaking change"
echo "           This is a REAL example from eslint-config-prettier"
echo ""
echo "Solution: Use fixed versions"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
reset_to_initial_state
echo ""
