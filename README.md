# rmote

A macOS menu bar app that controls Apple TV on the local network. Click the menu bar icon to open the remote; click outside it to dismiss.

## Install

Download the DMG from [GitHub Releases](https://github.com/samlambert/remote-desktop/releases) and drag `rmote` into Applications.

The first launch may be blocked because the app is not notarized. Right-click the app, choose Open, then confirm.

## Requirements

- macOS 14.0 or later
- Xcode 15+ with Command Line Tools
- [Homebrew](https://brew.sh) (for `xcodegen` via bootstrap)

## Build

```bash
script/setup    # install xcodegen if needed, generate the Xcode project
script/server   # Debug build and launch
script/install  # Release build → /Applications/rmote.app and launch
script/package  # Release build → dist/rmote-<version>.dmg
```

Signing defaults to ad-hoc (`CODE_SIGN_IDENTITY=-`) so the app builds without an Apple Developer certificate. Set `CODE_SIGN_IDENTITY` and `DEVELOPMENT_TEAM` to sign with your own identity.

## Tests

```bash
script/test
```

## Usage

1. Launch the app. It appears in the menu bar (no Dock icon).
2. Look for the remote silhouette, usually near the other menu extras (Wi-Fi, battery, Control Center).
3. Click the icon to open the remote window. Click outside the window to dismiss it.
4. Use **Select Apple TV** to pick a device and connect.
5. Select a text field on the Apple TV, then click the keyboard button to type from the Mac.

On first launch, coach marks walk through the device picker, trackpad, buttons, and keyboard. Use **Tips** to replay them.

## Pairing

When pairing for the first time:

1. Open the remote window from the menu bar icon.
2. Choose your Apple TV from **Select Apple TV**.
3. A 4-digit PIN appears on the TV. Enter it in the remote window.
4. On the Apple TV, go to **Settings → Remotes and Devices → Remote App and Devices** and allow the connection if prompted.

Credentials are stored in the macOS Keychain for later launches.

## Troubleshooting

- **No Apple TVs found:** The Mac and Apple TV must be on the same network. Use **Rescan**.
- **Pairing fails:** Remove the app from **Remote App and Devices** on the Apple TV and try again.
- **Connection errors:** Grant local network access if macOS prompted on first launch.
- **Blocked on first open:** Right-click → Open. The release DMG is not notarized.

## Protocol

Discovery, pairing, and remote commands come from [ItsytvCore](https://github.com/nickustinov/itsytv-core) (pinned in `project.yml`). The upstream README claims MIT, but the repository has no LICENSE file as of 2026-08-16.

## License

MIT. See `LICENSE`.
