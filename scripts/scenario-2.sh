#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 2: Lock File Drift"
echo "==========================================="
echo ""
echo "Problem: Adding unrelated dependency re-resolves ALL deps"
echo "         eslint-config-prettier unexpectedly upgrades"
echo "         CI breaks on unrelated PR"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
APP_DIR="$REPO_ROOT/apps/scenario-2-lock-drift"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

# ===== STEP 1: Initial install =====
echo "Step 1: Initial install with @demo/eslint-config (^10.1.0)"

cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-2-lock-drift",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

BEFORE_VERSION=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/eslint-config').sharedDepVersion)" 2>/dev/null || echo "unknown")
echo "   Initial @demo/shared-dep version: $BEFORE_VERSION"
echo ""

# Save lock file for comparison
cp "$REPO_ROOT/yarn.lock" "$REPO_ROOT/yarn.lock.before" 2>/dev/null || true

# ===== STEP 2: Simulate upstream patch release =====
echo "📦 Upstream publishes shared-dep@10.1.1 (PATCH, still in ^10.1.0 range)"
setup_shared_dep_version "10.1.1" "v10.1.1/index.js"
echo ""

# ===== STEP 3: Add unrelated dependency =====
echo "Step 2: Add unrelated dependency (local) → triggers re-resolve"
echo "   Developer adds @demo/eslint-config-fixed (no relation to shared-dep)..."

(cd "$REPO_ROOT" && yarn add @demo/eslint-config-fixed@1.0.0 --silent 2>&1 | grep -v "warning" | head -3)

AFTER_VERSION=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/eslint-config').sharedDepVersion)" 2>/dev/null || echo "unknown")
echo "   After adding unrelated dep: $AFTER_VERSION"
echo ""

# ===== STEP 4: Check what changed =====
echo "Step 3: Check what changed"
if [ -f "$REPO_ROOT/yarn.lock.before" ]; then
    DIFF_COUNT=$(diff "$REPO_ROOT/yarn.lock.before" "$REPO_ROOT/yarn.lock" 2>/dev/null | grep -c "^[<>]" || echo "0")
    echo "   Lock file changes: $DIFF_COUNT lines"
    
    if diff "$REPO_ROOT/yarn.lock.before" "$REPO_ROOT/yarn.lock" 2>/dev/null | grep -q "@demo/shared-dep"; then
        echo "   ❌ @demo/shared-dep version CHANGED (unexpected!)"
    fi
fi

echo ""
echo "==========================================="
echo "Result:"
echo "  ❌ Added unrelated dep, but @demo/shared-dep changed!"
echo "  Before: $BEFORE_VERSION"
echo "  After:  $AFTER_VERSION"
echo ""
echo "Root Cause: Caret (^) allows yarn to re-resolve"
echo "           during any 'yarn add' operation"
echo ""
echo "Solution: Use fixed versions"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
rm -f "$REPO_ROOT/yarn.lock.before" 2>/dev/null || true
reset_to_initial_state
echo ""
