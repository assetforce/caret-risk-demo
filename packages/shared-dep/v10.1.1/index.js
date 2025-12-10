// Simulates eslint-config-prettier 10.1.1 (BREAKING CHANGE in PATCH version)
module.exports = {
  version: '10.1.1',
  importPath: 'flat',
  config: function() {
    // Simulate the REAL breaking change from v10.1.0 -> v10.1.1
    // Ref: https://github.com/prettier/eslint-config-prettier/blob/07829b4912d173986610a4985247896b09f9fcaf/CHANGELOG.md#patch-changes-4
    throw new Error('❌ ERROR: Import path changed! Must use "eslint-config-prettier/flat" instead of "eslint-config-prettier"');
  },
  test: function() {
    console.log('Testing v10.1.1...');
    try {
      this.config();
      return { success: true, version: this.version };
    } catch (e) {
      return { success: false, error: e.message, version: this.version };
    }
  }
};
