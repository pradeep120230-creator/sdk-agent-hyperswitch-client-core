const {getDefaultConfig} = require('@react-native/metro-config');
const path = require('path');

const defaultConfig = getDefaultConfig(__dirname);

const linkedKlarnaPath = path.resolve(
  __dirname,
  '../react-native-hyperswitch/packages/@juspay-tech/react-native-hyperswitch-klarna',
);

module.exports = {
  ...defaultConfig,
  watchFolders: [linkedKlarnaPath],
  resolver: {
    ...defaultConfig.resolver,
    sourceExts: ['bs.js', ...defaultConfig.resolver.sourceExts],
  },
};
