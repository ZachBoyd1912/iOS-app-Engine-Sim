import type { CapacitorConfig } from '@capacitor/cli'

// The game ships fully inside the app bundle: no remote URL, no code downloaded after
// install. That is what keeps it clear of App Review guidelines 2.5.2 and 4.7.
const config: CapacitorConfig = {
  // PROPOSED bundle ID. It becomes permanent the moment the app record is created in
  // App Store Connect, so Zach confirms it before that step (docs/ios-release.md).
  appId: 'ie.zbautomations.pistonforge',
  appName: 'Piston Forge',
  webDir: 'dist',
  backgroundColor: '#080b0c',
  ios: {
    // The page handles the notch and home indicator itself with env(safe-area-inset-*).
    contentInset: 'never',
    backgroundColor: '#080b0c',
    // The game is a fixed canvas plus panels that scroll on their own.
    scrollEnabled: false,
    allowsLinkPreview: false,
  },
}

export default config
