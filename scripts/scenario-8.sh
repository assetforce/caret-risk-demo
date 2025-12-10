#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 8: Transitive Dependency Hell"
echo "==========================================="
echo ""
echo "Problem: Multiple layers of caret (^) dependencies"
echo "         create exponential version uncertainty"
echo ""
echo "Dependency chain:"
echo "  App → Library A (^1.0.0)"
echo "        ↓"
echo "        Library B (^1.0.0)"
echo "        ↓"
echo "        Library C (^1.0.0)"
echo "        ↓"
echo "        shared-dep (^10.1.0)"
echo ""
echo "Impact: 3 layers of caret = 3× uncertainty"
echo "        Debugging 'works on my machine' becomes nightmare"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
APP_DIR="$REPO_ROOT/apps/scenario-8-transitive"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

# ===== STEP 1: Install with 10.1.0 =====
echo "Step 1: Developer A installs (January 2025)"
echo "   All layers resolve to earliest versions"

cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-8-transitive",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/lib-a": "^1.0.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

echo "   Dependency tree:"
(cd "$REPO_ROOT" && node -e "
const libA = require('@demo/lib-a');
const libB = require('@demo/lib-b');
const libC = require('@demo/lib-c');
console.log('   App → @demo/lib-a');
console.log('         ↓');
console.log('         @demo/lib-b');
console.log('         ↓');
console.log('         @demo/lib-c');
console.log('         ↓');
console.log('         @demo/shared-dep:', libC.sharedDepVersion);
" 2>/dev/null)

DEV_A_VERSION=$(cd "$REPO_ROOT" && node -e "
const libA = require('@demo/lib-a');
console.log(libA.sharedDepVersion);
" 2>/dev/null || echo "unknown")

echo ""
echo "   Developer A sees: shared-dep@$DEV_A_VERSION"
echo "   ✅ Feature works"
echo ""

# ===== STEP 2: Upstream releases 10.1.1 =====
echo "📦 [February 2025] @demo/shared-dep releases 10.1.1 (breaking change)"
echo ""

# ===== STEP 3: Install with 10.1.1 =====
echo "Step 2: Developer B installs (February 2025)"
echo "   Bottom layer (shared-dep) resolves to 10.1.1"

setup_shared_dep_version "10.1.1" "v10.1.1/index.js"

cat > "$APP_DIR/package.json" << 'EOF'
{
  "name": "scenario-8-transitive",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/lib-a": "^1.0.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

echo "   Dependency tree:"
(cd "$REPO_ROOT" && node -e "
const libA = require('@demo/lib-a');
const libB = require('@demo/lib-b');
const libC = require('@demo/lib-c');
console.log('   App → @demo/lib-a');
console.log('         ↓');
console.log('         @demo/lib-b');
console.log('         ↓');
console.log('         @demo/lib-c');
console.log('         ↓');
console.log('         @demo/shared-dep:', libC.sharedDepVersion);
" 2>/dev/null)

DEV_B_VERSION=$(cd "$REPO_ROOT" && node -e "
const libA = require('@demo/lib-a');
console.log(libA.sharedDepVersion);
" 2>/dev/null || echo "unknown")

echo ""
echo "   Developer B sees: shared-dep@$DEV_B_VERSION"

# Test if it works
(cd "$REPO_ROOT" && node -e "
try {
  const libA = require('@demo/lib-a');
  const result = libA.feature();
  if (result.libB.libC.success) {
    console.log('   ✅ Feature works');
  }
} catch (e) {
  console.log('   ❌ Feature breaks:', e.message.substring(0, 60));
}
" 2>&1) || echo "   ❌ Feature breaks!"

echo ""

# ===== STEP 4: Debugging nightmare =====
echo "Step 3: Debugging the problem"
echo ""
echo "   Developer B: 'Code doesn't work on my machine!'"
echo "   Developer A: 'Works on mine...'"
echo ""
echo "   Where is the problem?"
echo "   - App code? (App)"
echo "   - Feature library? (@demo/lib-a)"
echo "   - Service library? (@demo/lib-b)"
echo "   - Utility library? (@demo/lib-c)"
echo "   - Base dependency? (@demo/shared-dep)"
echo ""
echo "   Answer: @demo/shared-dep (3 layers deep!)"
echo "   Time wasted debugging: 4+ hours"
echo ""

echo "==========================================="
echo "Result:"
echo "  ❌ 3-layer caret chain = 3× version uncertainty"
echo "  Developer A: $DEV_A_VERSION (works)"
echo "  Developer B: $DEV_B_VERSION (breaks)"
echo ""
echo "Complexity breakdown:"
echo "  - Layer 1: App → lib-a (^1.0.0) - 1 uncertainty"
echo "  - Layer 2: lib-a → lib-b (^1.0.0) - 2 uncertainties"
echo "  - Layer 3: lib-b → lib-c (^1.0.0) - 3 uncertainties"
echo "  - Layer 4: lib-c → shared-dep (^10.1.0) - 4 uncertainties"
echo ""
echo "  Total: EXPONENTIAL complexity"
echo "  Debugging: NIGHTMARE"
echo ""
echo "Root Cause: Cascading caret (^) ranges"
echo "           Each layer adds uncertainty"
echo ""
echo "Solution: Use fixed versions in libraries"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
reset_to_initial_state
echo ""
