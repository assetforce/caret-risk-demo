// Simulates eslint-config-prettier 10.1.0 (old version, works)
module.exports = {
  version: '10.1.0',
  importPath: 'default',
  config: function() {
    console.log('✅ Using v10.1.0 - default import path works');
    return {
      rules: {
        'arrow-body-style': 'off',
        'prefer-arrow-callback': 'off'
      }
    };
  },
  test: function() {
    console.log('Testing v10.1.0...');
    try {
      this.config();
      return { success: true, version: this.version };
    } catch (e) {
      return { success: false, error: e.message, version: this.version };
    }
  }
};
