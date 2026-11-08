const Parse = require('parse/node');

Parse.Cloud.define('sdkEcho', request => ({
  value: request.params.value,
  userId: request.user ? request.user.id : null,
}));

Parse.Cloud.job('sdkJob', async request => {
  await request.message('completed by the SDK integration fixture');
  return 'completed';
});
