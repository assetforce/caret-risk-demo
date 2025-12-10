#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 1: Multi-Team Time-Based Inconsistency"
echo "==========================================="
echo ""
echo "Problem: Different teams install at different times,"
echo "         get different versions within caret range,"
echo "         same code behaves differently"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

# ===== TEST: Team A (January) =====
echo "📅 Team A (2025-01-15, before v10.1.1 release):"
echo "   @demo/shared-dep is at v10.1.0"
echo "   Installing @demo/eslint-config with ^10.1.0..."

cat > "$REPO_ROOT/apps/team-a/package.json" << 'EOF'
{
  "name": "team-a",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

# Clean install
cleanup_app "team-a"
cleanup_root
(cd "$REPO_ROOT" && silent_install)

# Test
(cd "$REPO_ROOT/apps/team-a" && node -e "
const lib = require('@demo/eslint-config');
const result = lib.test();
console.log('   Result:', result.success ? '✅ Works' : '❌ Breaks');
console.log('   Dependency:', result.dependencyVersion);
" 2>&1)

echo ""

# ===== SIMULATE VERSION BUMP =====
echo "📦 [2025-02-01] @demo/shared-dep releases v10.1.1"
echo "   This is a PATCH version, within ^10.1.0 range"
echo ""

setup_shared_dep_version "10.1.1" "v10.1.1/index.js"
verify_shared_dep_version "10.1.1"

# ===== TEST: Team B (February) =====
echo "📅 Team B (2025-02-15, after v10.1.1 release):"
echo "   @demo/shared-dep is now at v10.1.1"
echo "   Installing @demo/eslint-config with ^10.1.0 (same range)..."

cat > "$REPO_ROOT/apps/team-b/package.json" << 'EOF'
{
  "name": "team-b",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

# Clean install
cleanup_app "team-b"
cleanup_root
(cd "$REPO_ROOT" && silent_install)

# Test
(cd "$REPO_ROOT/apps/team-b" && node -e "
const lib = require('@demo/eslint-config');
const result = lib.test();
console.log('   Result:', result.success ? '✅ Works' : '❌ Breaks');
console.log('   Dependency:', result.dependencyVersion);
if (!result.success) {
  console.log('   Error:', result.error.substring(0, 100));
}
" 2>&1) || echo "   ❌ Import failed (breaking change)"

echo ""
echo "==========================================="
echo "Result:"
echo "  ❌ Same package.json (^10.1.0), different behavior!"
echo "  Team A: works with v10.1.0"
echo "  Team B: breaks with v10.1.1"
echo "  Both within caret range!"
echo ""
echo "Root Cause: Caret (^) allows patch updates"
echo "           v10.1.1 has breaking change in import path"
echo "           (Real example from eslint-config-prettier)"
echo ""
echo "Solution: Use fixed versions"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
reset_to_initial_state
echo ""
