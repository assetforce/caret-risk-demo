#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 7: Package Manager Differences"
echo "==========================================="
echo ""
echo "Problem: npm, yarn, and pnpm resolve the SAME caret range"
echo "         to DIFFERENT versions at the SAME time"
echo ""
echo "Impact: 'Works in CI (npm), breaks locally (yarn)'"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
APP_DIR="$REPO_ROOT/apps/scenario-7-package-manager"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

# ===== STEP 1: Publish both versions =====
echo "Step 1: Simulate both 10.1.0 and 10.1.1 available in registry"
echo "   (In real npm registry, both versions exist simultaneously)"
echo ""

# Create package.json with caret range
cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-7-package-manager",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

# ===== STEP 2: Yarn install (simulates aggressive resolver) =====
echo "Step 2: Yarn install (tends to pick latest compatible)"
echo "   Installing with yarn..."

# Setup shared-dep to 10.1.1 to simulate yarn's aggressive resolution
setup_shared_dep_version "10.1.1" "v10.1.1/index.js"

cleanup_root
(cd "$REPO_ROOT" && yarn install --silent 2>&1 | grep -v "warning" | head -3)

YARN_VERSION=$(cd "$REPO_ROOT" && node -e "
const lib = require('@demo/eslint-config');
console.log(lib.sharedDepVersion);
" 2>/dev/null || echo "unknown")

echo "   Yarn resolved to: $YARN_VERSION"
echo ""

# Save yarn's lock file for comparison
cp "$REPO_ROOT/yarn.lock" "$APP_DIR/yarn.lock.yarn" 2>/dev/null || true

# ===== STEP 3: Simulate npm install (conservative resolver) =====
echo "Step 3: npm install (simulated - tends to pick earliest compatible)"
echo "   (In this demo, we simulate npm's conservative behavior)"

# Setup shared-dep to 10.1.0 to simulate npm's conservative resolution
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"

cleanup_root
(cd "$REPO_ROOT" && yarn install --silent 2>&1 | grep -v "warning" | head -3)

NPM_VERSION=$(cd "$REPO_ROOT" && node -e "
const lib = require('@demo/eslint-config');
console.log(lib.sharedDepVersion);
" 2>/dev/null || echo "unknown")

echo "   npm would resolve to: $NPM_VERSION (simulated)"
echo ""

# ===== STEP 4: Compare =====
echo "Step 4: Compare package manager resolutions"
echo ""
echo "   Same package.json: { \"@demo/eslint-config\": \"^10.1.0\" }"
echo "   Same time: 2025-12-10"
echo "   Same registry: Both 10.1.0 and 10.1.1 available"
echo ""
echo "   Yarn:  resolves to $YARN_VERSION"
echo "   npm:   resolves to $NPM_VERSION (simulated)"
echo ""

if [ "$YARN_VERSION" != "$NPM_VERSION" ]; then
    echo "   ❌ DIFFERENT versions from SAME caret range!"
fi

echo ""
echo "==========================================="
echo "Result:"
echo "  ❌ Same package.json, different package managers = different versions"
echo "  Yarn:  $YARN_VERSION"
echo "  npm:   $NPM_VERSION"
echo ""
echo "Real-world scenario:"
echo "  - CI uses npm → gets 10.1.0 → ✅ tests pass"
echo "  - Developer uses yarn → gets 10.1.1 → ❌ tests fail"
echo "  - Developer: 'Works on CI, why broken locally?!'"
echo ""
echo "Root Cause: Package managers have different resolution algorithms"
echo "           Caret (^) gives them flexibility to choose"
echo ""
echo "Solution: Use fixed versions"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
rm -f "$APP_DIR/yarn.lock.yarn" 2>/dev/null || true
reset_to_initial_state
echo ""
