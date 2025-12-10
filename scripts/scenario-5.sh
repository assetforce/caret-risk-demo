#!/bin/bash
set -e

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

echo "==========================================="
echo "Scenario 5: Audit Compliance Failure"
echo "==========================================="
echo ""
echo "Problem: Auditor asks for exact versions"
echo "         Can't provide definitive answer with caret"
echo "         Each team has different lock file"
echo ""
echo "==========================================="
echo ""

REPO_ROOT=$(get_repo_root)
AUDIT_DIR="$REPO_ROOT/apps/scenario-5-audit"

# ===== SETUP =====
echo "📋 Setup: Preparing test environment..."
cleanup_all
setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
verify_shared_dep_version "10.1.0"
echo ""

echo "Simulating audit questionnaire..."
echo ""
echo "Q1: What version of eslint-config-prettier are you using?"
echo ""

# ===== Team A =====
cat > "$AUDIT_DIR/team-a-audit/package.json" << 'EOF'
{
  "name": "team-a-audit",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

TEAM_A=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/shared-dep').version)" 2>/dev/null || echo "unknown")
echo "   Team A (Vendor 1): $TEAM_A"

# ===== Team B =====
cat > "$AUDIT_DIR/team-b-audit/package.json" << 'EOF'
{
  "name": "team-b-audit",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

TEAM_B=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/shared-dep').version)" 2>/dev/null || echo "unknown")
echo "   Team B (Vendor 2): $TEAM_B"

# ===== Team C =====
cat > "$AUDIT_DIR/team-c-audit/package.json" << 'EOF'
{
  "name": "team-c-audit",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@demo/eslint-config": "^10.1.0"
  }
}
EOF

cleanup_root
(cd "$REPO_ROOT" && silent_install)

TEAM_C=$(cd "$REPO_ROOT" && node -e "console.log(require('@demo/shared-dep').version)" 2>/dev/null || echo "unknown")
echo "   Team C (In-house): $TEAM_C"

echo ""
echo "Auditor: 'So which version are you using?'"
echo "You: 'It depends...'"
echo "Auditor: 'That's not an acceptable answer.'"
echo ""

echo "==========================================="
echo "Result:"
echo "  ❌ Cannot provide single definitive version"
echo "  Team A: $TEAM_A"
echo "  Team B: $TEAM_B"
echo "  Team C: $TEAM_C"
echo ""
echo "Root Cause: Caret (^) means 'version depends on when/who installed'"
echo ""
echo "Audit Consequence: NON-COMPLIANT"
echo "Financial Industry: UNACCEPTABLE"
echo ""
echo "Solution: Use fixed versions"
echo "==========================================="
echo ""

# ===== CLEANUP =====
echo "🧹 Cleanup: Restoring initial state..."
reset_to_initial_state
echo ""
