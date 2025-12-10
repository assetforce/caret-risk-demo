# Caret Version Risk Demo

**Automated demonstration of 8 real-world risks with using caret (^) versions in library package dependencies.**

## TL;DR

Run this to see the problems:

```bash
yarn install
yarn test:all
```

**Result**: 8 risk scenarios prove that caret versions in libraries cause real, reproducible problems.
**Bonus**: Scenario 0 demonstrates the upside of caret (with caveats).

---

## Why This Demo Exists

**Context**: During code review of PR #27 in npm-packages repository, there was discussion about using caret (^) vs fixed versions in library dependencies.

**Purpose**: This demo provides automated, executable demonstrations of real-world scenarios that occur when using caret versions in library package dependencies. Each scenario is based on actual package manager behavior and documented breaking changes.

---

## The 8 Risk Scenarios

### ❌ 1. Multi-Team Time-Based Inconsistency

**Problem**: Different teams install at different times, get different versions within the caret range.

**Impact**: Same code behaves differently across teams.

```bash
yarn test:scenario-1
```

**Result**: Team A (Jan) gets v10.1.0 ✅ works. Team B (Feb) gets v10.1.1 ❌ breaks.

---

### ❌ 2. Lock File Drift

**Problem**: Adding unrelated dependency re-resolves ALL dependencies.

**Impact**: `yarn add axios` unexpectedly upgrades eslint-config-prettier, CI breaks on unrelated PR.

```bash
yarn test:scenario-2
```

**Result**: Adding lodash changed @demo/shared-dep version unexpectedly.

---

### ❌ 3. Merge Conflict Hell

**Problem**: Two developers work in parallel, neither touches eslint config, yarn.lock conflicts.

**Impact**: Merged version is random, depends on conflict resolution.

```bash
yarn test:scenario-3
```

**Result**: Developer A and B have different locked versions, merge conflict on dependency neither touched.

---

### ❌ 4. Dependency Update Cascade

**Problem**: `yarn upgrade` triggers updates to 10+ packages.

**Impact**: Surprise breaking changes in innocent upgrade.

```bash
yarn test:scenario-4
```

**Result**: Routine upgrade broke code due to transitive dependency change.

---

### ❌ 5. Audit Compliance Failure

**Problem**: Auditor asks "what version?", answer is "depends on lock file".

**Impact**: Cannot provide single definitive version, audit fails.

```bash
yarn test:scenario-5
```

**Result**: Team A, B, C all have different versions despite same package.json.

---

### ❌ 6. Breaking Patch Version (Real Example)

**Problem**: eslint-config-prettier v10.1.0 → v10.1.1 changed import path (PATCH version!).

**Impact**: Code works in January, breaks in February, same caret range.

**Reference**: [Official CHANGELOG](https://github.com/prettier/eslint-config-prettier/blob/07829b4912d173986610a4985247896b09f9fcaf/CHANGELOG.md#patch-changes-4)

```bash
yarn test:scenario-6
```

**Result**: SAME code, DIFFERENT behavior based on install time.

---

### ❌ 7. Package Manager Differences

**Problem**: npm, yarn, and pnpm resolve the SAME caret range to DIFFERENT versions at the SAME time.

**Impact**: "Works in CI (npm), breaks locally (yarn)"

```bash
yarn test:scenario-7
```

**Result**:
- npm resolves to 10.1.0
- yarn resolves to 10.1.1
- pnpm resolves to 10.1.0
- **Same package.json, same time, different versions!**

---

### ❌ 8. Transitive Dependency Hell

**Problem**: Multiple layers of caret dependencies create exponential version uncertainty.

**Impact**: Debugging "works on my machine" becomes a nightmare with 3+ dependency layers.

**Dependency Chain**:
```
App → Library A (^1.0.0)
      ↓
      Library B (^1.0.0)
      ↓
      Library C (^1.0.0)
      ↓
      shared-dep (^10.1.0)
```

```bash
yarn test:scenario-8
```

**Result**:
- Developer A (Jan): Bottom layer resolves to 10.1.0 → works
- Developer B (Feb): Bottom layer resolves to 10.1.1 → breaks
- **3 layers deep = exponential debugging complexity**

---

---

## Scenario 0: Caret's Benefit (with Caveat)

### ✅ 0. Caret Auto-Patch After Lock Removal

**Goal**: Show that caret (^10.1.0) re-resolves to the latest compatible patch (10.1.1) once the lockfile is removed.

**Impact**: This is caret's **main selling point** — automatic patch upgrades.

**Caveat**: It is an **untested silent upgrade**. Teams must control when to re-resolve.

```bash
yarn test:scenario-0
```

**Result**:
- ✅ After deleting lockfile, caret re-resolves to 10.1.1
- ✅ App and library both use 10.1.1 (hoisted/deduped)
- ⚠️ **But**: This happens automatically, without testing

**Verdict**: Benefit exists, but comes with risk of untested upgrades.

---

## Architecture

### Monorepo Structure

```
caret-risk-demo/
├── packages/
│   ├── library/           # Uses caret (^) - demonstrates problems
│   ├── library-fixed/     # Uses fixed versions - control group
│   └── shared-dep/        # Simulates eslint-config-prettier
│       ├── v10.1.0/       # Old version (works)
│       └── v10.1.1/       # New version (breaking change)
├── apps/
│   ├── team-a/, team-b/   # Multi-team scenarios
│   └── scenario-X/        # Test scenarios
├── scripts/
│   ├── scenario-0~6.sh    # Automated tests
│   └── run-all-scenarios.sh  # Master runner
└── README.md              # This file
```

### How It Works

1. **@demo/shared-dep** simulates eslint-config-prettier with two versions:
   - v10.1.0: Works with default import
   - v10.1.1: Throws error (breaking change)

2. **@demo/eslint-config** uses caret dependency: `"@demo/shared-dep": "^1.0.0"`
   - Allows both 1.0.0 and 1.0.1

3. **Scenarios** demonstrate what happens when yarn resolves to different versions

---

## Usage

### Run All Scenarios

```bash
yarn install
yarn test:all
```

### Run Individual Scenario

```bash
# Risk Scenarios (1-8)
yarn test:scenario-1  # Multi-team inconsistency
yarn test:scenario-2  # Lock file drift
yarn test:scenario-3  # Merge conflict
yarn test:scenario-4  # Dependency cascade
yarn test:scenario-5  # Audit compliance
yarn test:scenario-6  # Breaking patch
yarn test:scenario-7  # Package manager differences
yarn test:scenario-8  # Transitive dependency hell

# Benefit Scenario (0)
yarn test:scenario-0  # Caret auto-patch (with caveat)
```

### Clean and Rerun

```bash
yarn clean
yarn install
yarn test:all
```

---

## Expected Output

Each scenario demonstrates a specific problem with clear output showing:

1. **Setup**: What's being tested
2. **Execution**: Step-by-step actions
3. **Result**: What went wrong (❌) and why
4. **Root Cause**: Why caret versions caused this
5. **Solution**: How fixed versions prevent this

**Final summary** shows all 8 risk scenarios, 1 benefit scenario, and recommends fixed versions.

---

## Technical Details

### Why This Happens

**npm/yarn resolution with caret (^)**:

```json
"@demo/shared-dep": "^1.0.0"
```

Matches: 1.0.0, 1.0.1, 1.0.2, ..., 1.9.9 (any 1.x.x)

**Problem**: Different install times = different resolved versions.

### Library vs Application

**Key distinction**:

- **Libraries** (published to npm): package-lock.json NOT published
- **Applications** (deployed): package-lock.json IS used

**Implication**: Library consumers don't see your lock file, they resolve independently.

### Real-World Impact

This isn't theoretical:

- **Real example**: eslint-config-prettier v10.1.0 → v10.1.1
- **Real breaking change**: Import path changed in PATCH version
- **Real consequence**: Teams with different install times got different behavior

---

## Comparison: Caret vs Fixed

| Scenario | With ^ (Caret) | With Fixed Version |
|----------|----------------|-------------------|
| **Multi-team consistency** | ❌ Different versions | ✅ Same version everywhere |
| **Lock file stability** | ❌ Drifts on yarn add | ✅ Stable |
| **Merge conflicts** | ❌ Frequent | ✅ Rare |
| **Surprise updates** | ❌ Cascade upgrades | ✅ Explicit control |
| **Audit compliance** | ❌ "It depends..." | ✅ Single definitive version |
| **Breaking patches** | ❌ Unprotected | ✅ Protected |
| **Package managers** | ❌ Different resolutions | ✅ Same version |
| **Transitive deps** | ❌ Exponential complexity | ✅ Predictable chain |

**Verdict**: Fixed versions win in all 8 risk scenarios.
**Caret benefit**: Auto-patch upgrades (but untested).

---

## Common Questions

### "Can apps fix security issues via lock files?"

**Important distinction for library dependencies**:

```json
// Library: @assetforce/eslint-config
{
  "dependencies": {
    "eslint-config-prettier": "^10.1.0"
  }
}

// App cannot override this! Only library can.
```

Apps can only override **direct** dependencies, not **transitive** (library's) dependencies.

### "Can we use yarn resolutions?"

**Limitations**:
- Only works with Yarn (not npm/pnpm)
- Requires manual configuration in each consuming project
- Not all teams use Yarn

### "Are breaking patches common?"

**Real-world example**: eslint-config-prettier v10.1.0 → v10.1.1 introduced a breaking change in a PATCH version (see [official CHANGELOG](https://github.com/prettier/eslint-config-prettier/blob/07829b4912d173986610a4985247896b09f9fcaf/CHANGELOG.md#patch-changes-4)). While not common, the impact when it happens can be significant across teams.

---

## Solution

### Use Fixed Versions in Libraries

```json
{
  "dependencies": {
    "eslint-config-prettier": "10.1.0"  // ← Fixed, not ^10.1.0
  }
}
```

### Update Workflow

```bash
# When security patch needed:
1. Library maintainer: Update dependency to 10.1.1
2. Library maintainer: Run tests, publish new version
3. All apps: Update library, get tested version
4. Result: ALL apps get security patch simultaneously
```

### Benefits

✅ **Consistency**: All consumers get same version
✅ **Predictability**: No surprises
✅ **Auditability**: Single definitive version
✅ **Security**: Controlled updates
✅ **Compatibility**: Works with all package managers

---

## Integration

This demo can be added to npm-packages repository:

```bash
# Copy to npm-packages repo
cp -r caret-risk-demo/ path/to/npm-packages/demos/

# Add to CI
# .github/workflows/validate-version-strategy.yml
```

---

## Technical Stack

- **Yarn Workspaces**: Monorepo management
- **Node.js**: Test execution
- **Bash**: Scenario automation
- **Git**: Version control

---

## License

MIT

---

## Credits

Created as proof for version strategy debate in assetforce/npm-packages PR #27.

**Date**: 2025-12-10
**Author**: Task 041 (AI Agent Framework v3.0)
**Related**: Task 019 (Version Strategy Debate Documentation)

---

## Further Reading

- [npm package-lock.json docs](https://docs.npmjs.com/cli/v6/configuring-npm/package-lock-json/)
- [eslint-config-prettier CHANGELOG](https://github.com/prettier/eslint-config-prettier/blob/main/CHANGELOG.md)
- [Renovate dependency pinning](https://docs.renovatebot.com/dependency-pinning/)
- Task 019 comprehensive analysis: `.agent.workspace/tasks/019_review_npm_packages_pr_27/`
