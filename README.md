# TV Remote

A lean macOS menu bar app for controlling Apple TV over the local network. Click the menu bar icon to open the remote panel; click elsewhere to dismiss it.

## Requirements

- macOS 14.0 or later
- Xcode 15+ with Command Line Tools
- [Homebrew](https://brew.sh) (for `xcodegen` via bootstrap)

## Build and run

```bash
script/setup    # install xcodegen if needed, generate Xcode project
script/server   # build Debug and launch the app
script/install  # Release build → /Applications/TV Remote.app and launch
```

`script/install` signs with your Apple Development identity (team `L2F9LC837N` by default). Override with `CODE_SIGN_IDENTITY` / `DEVELOPMENT_TEAM` if needed.

Regenerate menu bar and app icon PNGs with `script/generate-icons` (installs Pillow on first run; catalog `Contents.json` files are committed separately).

## Tests

```bash
script/test
```

## Usage

1. Launch the app — it appears in the menu bar (no Dock icon).
2. Look for the **TV Remote** menu bar icon — a custom Siri Remote silhouette — usually near the right side with other menu extras (Wi‑Fi, battery, Control Center). It may sit just left of the Control Center clock area.
3. **Click the icon** to open the remote window. Click anywhere outside the window to dismiss it.
4. Use the **Select Apple TV** menu inside the window to pick a device and connect.

## Pairing

When pairing for the first time:

1. Open the remote window from the menu bar icon.
2. Choose your Apple TV from **Select Apple TV**.
3. A 4-digit PIN appears on the TV — enter it in the remote window.
4. On the Apple TV, go to **Settings → Remotes and Devices → Remote App and Devices** and allow the connection if prompted.

Credentials are stored in the macOS Keychain for reconnecting on later launches.

## Troubleshooting

- **No Apple TVs found:** Ensure the Mac and Apple TV are on the same network. Use **Rescan** from the menu.
- **Pairing fails:** Remove the app from **Remote App and Devices** on the Apple TV and try again.
- **Connection errors:** Check that local network access was granted when macOS prompted on first launch.

## Protocol

All discovery, pairing, and remote protocol logic comes from [ItsytvCore](https://github.com/nickustinov/itsytv-core) (pinned in `project.yml`).

## License

MIT
