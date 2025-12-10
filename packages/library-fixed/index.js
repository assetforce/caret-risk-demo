const sharedDep = require('@demo/shared-dep-old');

module.exports = {
  name: '@demo/eslint-config-fixed',
  version: '1.0.0',
  versionStrategy: 'FIXED',
  sharedDepVersion: sharedDep.version,
  sharedDepImportPath: sharedDep.importPath,

  getConfig: function() {
    console.log(`[@demo/eslint-config-fixed] Using ${this.versionStrategy} for dependencies`);
    console.log(`[@demo/eslint-config-fixed] Resolved @demo/shared-dep to v${this.sharedDepVersion}`);
    return sharedDep.config();
  },

  test: function() {
    console.log(`\n=== Testing @demo/eslint-config-fixed (${this.versionStrategy}) ===`);
    try {
      this.getConfig();
      return {
        success: true,
        libraryVersion: this.version,
        dependencyVersion: this.sharedDepVersion,
        versionStrategy: this.versionStrategy
      };
    } catch (e) {
      return {
        success: false,
        error: e.message,
        libraryVersion: this.version,
        dependencyVersion: this.sharedDepVersion,
        versionStrategy: this.versionStrategy
      };
    }
  }
};
