# Contributing

## Setup

```bash
script/setup
```

This installs `xcodegen` if needed and generates `rmote.xcodeproj`.

## Test

```bash
script/test
```

`script/cibuild` runs the same tests.

## Package

```bash
script/package
```

Writes `dist/rmote-<version>.dmg` with an ad-hoc signed app. Set `CODE_SIGN_IDENTITY` and `DEVELOPMENT_TEAM` to use your own certificate.
