// Library C - Low-level utility
const sharedDep = require('@demo/shared-dep');

module.exports = {
  name: '@demo/lib-c',
  sharedDepVersion: sharedDep.version,
  utility: function() {
    return {
      success: true,
      message: 'Library C utility',
      dependency: sharedDep.version
    };
  }
};
