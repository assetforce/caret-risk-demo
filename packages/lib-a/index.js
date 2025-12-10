// Library A - Top-level feature
const libB = require('@demo/lib-b');

module.exports = {
  name: '@demo/lib-a',
  libBVersion: libB.name,
  sharedDepVersion: libB.sharedDepVersion,
  feature: function() {
    const serviceResult = libB.service();
    return {
      success: true,
      message: 'Library A feature',
      libB: serviceResult,
      sharedDepFromB: libB.sharedDepVersion
    };
  }
};
