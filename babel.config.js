module.exports = function (api) {
  api.cache(true);
  return {
    // Enable import.meta transform for SDK 54 static web export
    presets: [['babel-preset-expo', { unstable_transformImportMeta: true }]],
    // Reanimated v4 moved the Babel plugin to react-native-worklets
    plugins: ['react-native-worklets/plugin'], // must be last
  };
};
