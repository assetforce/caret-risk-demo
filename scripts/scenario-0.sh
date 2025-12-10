#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 0: Caret re-resolves to latest compatible after lock removal"
echo "==========================================="
echo ""
echo "Goal: Show that caret (^10.1.0) jumps to the newest compatible patch (10.1.1)"
echo "      once the lock is removed."
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
APP_DIR="$REPO_ROOT/apps/scenario-0-caret-upgrade"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

# ===== STEP 1: Initial install with lock =====
echo "Step 1: Install with lock (resolves 10.1.0 within ^10.1.0)"

cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-0-caret-upgrade",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

echo "   Resolved versions (before):"
(cd "$REPO_ROOT" && node -e "
const pkg = require('./packages/shared-dep/package.json');
const lib = require('@demo/eslint-config');
console.log('   - @demo/shared-dep package.json version:', pkg.version);
console.log('   - @demo/eslint-config sees dependency version:', lib.sharedDepVersion);
")
echo ""

# ===== STEP 2: Publish patch version =====
echo "Step 2: Publish patch shared-dep@10.1.1 (still inside ^10.1.0)"
setup_shared_dep_version "10.1.1" "v10.1.1/index.js"
echo ""

# ===== STEP 3: Remove lock and reinstall =====
echo "Step 3: Remove lock + reinstall to trigger re-resolve"
cleanup_root
(cd "$REPO_ROOT" && silent_install)

echo "   Resolved versions (after):"
(cd "$REPO_ROOT" && node -e "
const pkg = require('./packages/shared-dep/package.json');
const lib = require('@demo/eslint-config');
console.log('   - @demo/shared-dep package.json version:', pkg.version);
console.log('   - @demo/eslint-config sees dependency version:', lib.sharedDepVersion);
")
echo ""

echo "==========================================="
echo "Result:"
echo "  ✅ After deleting the lockfile, caret (^10.1.0) re-resolves to the latest compatible patch: 10.1.1"
echo "  ✅ App and library both use 10.1.1 (hoisted/deduped)"
echo ""
echo "Notes:"
echo "  - Caret will re-resolve on fresh install when the lock is removed"
echo "  - This is the 'auto-patch' upside of caret"
echo "  - Risk: it is an untested silent upgrade, so teams must control when to re-resolve"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
reset_to_initial_state
echo ""
