#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 4: Dependency Update Cascade"
echo "==========================================="
echo ""
echo "Problem: Update one dependency"
echo "         Triggers updates to 10 others"
echo "         Surprise breaking changes"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
APP_DIR="$REPO_ROOT/apps/scenario-4-cascade"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

# ===== STEP 1: Initial state =====
echo "Step 1: Initial state"

cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-4-cascade",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

echo "   Installed dependencies:"
(cd "$REPO_ROOT" && yarn list --depth=0 2>/dev/null | grep "@demo" || true)
echo ""

# ===== STEP 2: Simulate upstream release =====
echo "📦 Upstream publishes shared-dep@10.1.1"
setup_shared_dep_version "10.1.1" "v10.1.1/index.js"
echo ""

# ===== STEP 3: Upgrade =====
echo "Step 2: Update to latest versions"
echo "   Running 'yarn upgrade'..."
(cd "$REPO_ROOT" && yarn upgrade --silent 2>&1 | grep -v "warning" | head -3)

echo ""
echo "   After upgrade:"
(cd "$REPO_ROOT" && yarn list --depth=0 2>/dev/null | grep "@demo" || true)

UPGRADED_VERSION=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/eslint-config').sharedDepVersion)" 2>/dev/null || echo "unknown")
echo ""
echo "   @demo/shared-dep upgraded to: $UPGRADED_VERSION"

# ===== STEP 4: Test if it breaks =====
echo ""
echo "Step 3: Test code"
(cd "$REPO_ROOT" && node -e "
try {
  const lib = require('@demo/eslint-config');
  const result = lib.test();
  if (!result.success) {
    console.log('   ❌ Code breaks after upgrade!');
    console.log('   Error:', result.error.substring(0, 80));
  }
} catch (e) {
  console.log('   ❌ Code breaks after upgrade!');
  console.log('   Error:', e.message.substring(0, 80));
}
" 2>&1)

echo ""
echo "==========================================="
echo "Result:"
echo "  ❌ Innocent 'yarn upgrade' broke the code"
echo "  @demo/shared-dep: 10.1.0 → $UPGRADED_VERSION"
echo "  Unexpected breaking change in patch version"
echo ""
echo "Root Cause: Caret (^) allows automatic upgrades"
echo "           to versions with breaking changes"
echo ""
echo "Solution: Use fixed versions"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
reset_to_initial_state
echo ""
