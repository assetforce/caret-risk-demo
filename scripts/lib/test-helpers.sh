#!/bin/bash

# Test Helpers for Caret Risk Demo
# Provides common setup, cleanup, and verification functions

# 获取 monorepo 根目录
get_repo_root() {
    # 从 scripts/lib/ 向上两级到达根目录
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_root="$(cd "$script_dir/../.." && pwd)"
    echo "$repo_root"
}

# Setup: 设置 shared-dep 版本
# Usage: setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
setup_shared_dep_version() {
    local version=$1
    local main_file=$2
    
    if [ -z "$version" ] || [ -z "$main_file" ]; then
        echo "❌ ERROR: setup_shared_dep_version requires version and main_file"
        return 1
    fi
    
    local repo_root=$(get_repo_root)
    
    cat > "$repo_root/packages/shared-dep/package.json" << EOF
{
  "name": "@demo/shared-dep",
  "version": "$version",
  "description": "Simulating eslint-config-prettier v$version",
  "main": "$main_file"
}
EOF
    
    echo "✅ Set @demo/shared-dep to $version (main: $main_file)"
}

# Reset all apps to empty dependencies
reset_all_apps_to_empty() {
    local repo_root=$(get_repo_root)

    echo "🔄 Resetting all apps to empty dependencies..."

    # Simple apps (root level)
    local -a simple_apps=(
        "team-a"
        "team-b"
        "scenario-0-caret-upgrade"
        "scenario-2-lock-drift"
        "scenario-4-cascade"
        "scenario-6-breaking-patch"
        "scenario-7-package-manager"
        "scenario-8-transitive"
    )

    for app in "${simple_apps[@]}"; do
        cat > "$repo_root/apps/$app/package.json" << EOF
{
  "name": "$app",
  "version": "1.0.0",
  "private": true,
  "dependencies": {}
}
EOF
    done

    # Scenario 5 audit apps (nested)
    local -a audit_apps=(
        "team-a-audit"
        "team-b-audit"
        "team-c-audit"
    )

    for app in "${audit_apps[@]}"; do
        cat > "$repo_root/apps/scenario-5-audit/$app/package.json" << EOF
{
  "name": "$app",
  "version": "1.0.0",
  "private": true,
  "dependencies": {}
}
EOF
    done

    # Scenario 3 merge conflict (nested)
    cat > "$repo_root/apps/scenario-3-merge-conflict/branch-a/package.json" << 'EOF'
{
  "name": "branch-a",
  "version": "1.0.0",
  "private": true,
  "dependencies": {}
}
EOF

    echo "✅ All apps reset to empty dependencies"
}

# Cleanup: 清理所有 node_modules 和 lock 文件
cleanup_all() {
    local repo_root=$(get_repo_root)
    
    echo "🧹 Cleaning up all node_modules and lock files..."
    
    # 清理根目录
    rm -rf "$repo_root/node_modules" "$repo_root/yarn.lock" 2>/dev/null || true
    
    # 清理所有 packages
    find "$repo_root/packages" -maxdepth 2 -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$repo_root/packages" -maxdepth 2 -name "yarn.lock" -type f -delete 2>/dev/null || true
    
    # 清理所有 apps
    find "$repo_root/apps" -maxdepth 3 -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$repo_root/apps" -maxdepth 3 -name "yarn.lock" -type f -delete 2>/dev/null || true
    
    echo "✅ Cleanup complete"
}

# Cleanup: 清理特定 app
# Usage: cleanup_app "team-a"
cleanup_app() {
    local app_name=$1
    
    if [ -z "$app_name" ]; then
        echo "❌ ERROR: cleanup_app requires app_name"
        return 1
    fi
    
    local repo_root=$(get_repo_root)
    
    rm -rf "$repo_root/apps/$app_name/node_modules" \
           "$repo_root/apps/$app_name/yarn.lock" \
           2>/dev/null || true
    
    echo "✅ Cleaned up app: $app_name"
}

# Setup: 重置到初始状态（所有场景开始前）
reset_to_initial_state() {
    echo "🔄 Resetting to initial state..."
    
    local repo_root=$(get_repo_root)
    
    cleanup_all
    reset_all_apps_to_empty
    setup_shared_dep_version "10.1.0" "v10.1.0/index.js"
    
    # 使用 subshell 避免改变当前目录
    (cd "$repo_root" && yarn install --silent 2>&1 | grep -v "warning" | head -3)
    
    echo "✅ Initial state ready"
}

# Verify: 验证 shared-dep 版本
# Usage: verify_shared_dep_version "10.1.0"
verify_shared_dep_version() {
    local expected_version=$1
    
    if [ -z "$expected_version" ]; then
        echo "❌ ERROR: verify_shared_dep_version requires expected_version"
        return 1
    fi
    
    local repo_root=$(get_repo_root)
    local package_json="$repo_root/packages/shared-dep/package.json"
    
    if [ ! -f "$package_json" ]; then
        echo "❌ ERROR: $package_json not found"
        return 1
    fi
    
    local actual_version=$(node -e "console.log(require('$package_json').version)" 2>/dev/null)
    
    if [ "$actual_version" != "$expected_version" ]; then
        echo "❌ ERROR: Expected @demo/shared-dep@$expected_version, got $actual_version"
        return 1
    fi
    
    echo "✅ Verified @demo/shared-dep@$expected_version"
}

# Cleanup: 清理根目录的 node_modules 和 lock
cleanup_root() {
    local repo_root=$(get_repo_root)
    
    rm -rf "$repo_root/node_modules" "$repo_root/yarn.lock" 2>/dev/null || true
    
    echo "✅ Cleaned up root directory"
}

# Helper: 静默安装（减少输出噪音）
silent_install() {
    yarn install --silent 2>&1 | grep -v "warning" | head -5
}
