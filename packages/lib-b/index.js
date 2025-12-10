// Library B - Mid-level service
const libC = require('@demo/lib-c');

module.exports = {
  name: '@demo/lib-b',
  libCVersion: libC.name,
  sharedDepVersion: libC.sharedDepVersion,
  service: function() {
    const utilResult = libC.utility();
    return {
      success: true,
      message: 'Library B service',
      libC: utilResult,
      sharedDepFromC: libC.sharedDepVersion
    };
  }
};
