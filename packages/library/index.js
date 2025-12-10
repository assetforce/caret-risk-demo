const sharedDep = require('@demo/shared-dep');

module.exports = {
  name: '@demo/eslint-config',
  version: '1.0.0',
  versionStrategy: 'CARET (^)',
  sharedDepVersion: sharedDep.version,
  sharedDepImportPath: sharedDep.importPath,

  getConfig: function() {
    console.log(`[@demo/eslint-config] Using ${this.versionStrategy} for dependencies`);
    console.log(`[@demo/eslint-config] Resolved @demo/shared-dep to v${this.sharedDepVersion}`);
    return sharedDep.config();
  },

  test: function() {
    console.log(`\n=== Testing @demo/eslint-config (${this.versionStrategy}) ===`);
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
