#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 3: Merge Conflict Hell"
echo "==========================================="
echo ""
echo "Problem: Two developers work in parallel"
echo "         Neither touches eslint config"
echo "         yarn.lock conflicts on @demo/shared-dep"
echo "         Merged version is random"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
SCENARIO_DIR="$REPO_ROOT/apps/scenario-3-merge-conflict"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

# ===== Developer A's branch =====
echo "Developer A's branch (adds react):"

cat > "$SCENARIO_DIR/branch-a/package.json" << 'EOF'
{
  "name": "branch-a",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0",
    "react": "18.2.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

DEV_A_VERSION=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/eslint-config').sharedDepVersion)" 2>/dev/null || echo "unknown")
echo "   @demo/shared-dep: $DEV_A_VERSION"

# Save Dev A's lock file
cp "$REPO_ROOT/yarn.lock" "$SCENARIO_DIR/yarn.lock.dev-a" 2>/dev/null || true
echo ""

# ===== Developer B's branch =====
echo "Developer B's branch (adds vue):"

mkdir -p "$SCENARIO_DIR/branch-b"
cat > "$SCENARIO_DIR/branch-b/package.json" << 'EOF'
{
  "name": "branch-b",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0",
    "vue": "3.3.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

DEV_B_VERSION=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/eslint-config').sharedDepVersion)" 2>/dev/null || echo "unknown")
echo "   @demo/shared-dep: $DEV_B_VERSION"

# Save Dev B's lock file
cp "$REPO_ROOT/yarn.lock" "$SCENARIO_DIR/yarn.lock.dev-b" 2>/dev/null || true
echo ""

# ===== Check for conflicts =====
echo "Attempting to merge lock files..."
if [ -f "$SCENARIO_DIR/yarn.lock.dev-a" ] && [ -f "$SCENARIO_DIR/yarn.lock.dev-b" ]; then
    CONFLICT_COUNT=$(diff "$SCENARIO_DIR/yarn.lock.dev-a" "$SCENARIO_DIR/yarn.lock.dev-b" 2>/dev/null | grep -c "@demo/shared-dep" || echo "0")
    if [ "$CONFLICT_COUNT" -gt 0 ]; then
        echo "   ❌ Found $CONFLICT_COUNT conflicts on @demo/shared-dep"
    fi
fi

echo ""
echo "==========================================="
echo "Result:"
echo "  ❌ Lock file conflict on @demo/shared-dep"
echo "  Neither developer touched this dependency!"
echo "  Dev A: $DEV_A_VERSION"
echo "  Dev B: $DEV_B_VERSION"
echo ""
echo "Root Cause: Caret (^) allows different resolutions"
echo "           at different times"
echo ""
echo "Solution: Use fixed versions"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
rm -f "$SCENARIO_DIR/yarn.lock.dev-a" "$SCENARIO_DIR/yarn.lock.dev-b" 2>/dev/null || true
rm -rf "$SCENARIO_DIR/branch-b" 2>/dev/null || true
reset_to_initial_state
echo ""
