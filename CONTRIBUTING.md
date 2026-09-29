# Contributing

Contributions are welcome.

## Development Environment

The current main branch targets v0.3.0:

- Windows 11
- AutoHotkey v2
- Windows PowerShell 5.1+ for startup-task scripts and test runners

## Before Making Changes

Read:

- `README.md`
- `docs/MVP_DESIGN.md`
- `docs/KNOWN_LIMITATIONS.md`

For configuration changes, also read `docs/PHASE_D_SPEC.md`.

## Tests

Run the automated test suite:

```powershell
.\tests\Run-PhaseFTests.ps1
```

When desktop interaction is required:

```powershell
.\tests\Run-PhaseFTests.ps1 -Desktop
```

For logon startup changes:

```powershell
.\tests\StartupTask.Tests.ps1
.\tests\StartupTask.Tests.ps1 -Integration
```

Changes to `scripts/install-startup-task.ps1` or `scripts/uninstall-startup-task.ps1` should preserve current-user InteractiveToken execution, least privilege, exact-task removal, quoted paths, and duplicate-instance protection.

Changes that affect input handling, Auto Bind, NumLock lifecycle, Shortcut execution, or Configuration validation should include appropriate regression coverage.

## Configuration Encoding

`KeyBindings.ini` is a local user file and is not tracked. All configuration INI files are UTF-8.

Repository INI files should be saved as UTF-8 without BOM. The runtime accepts an optional UTF-8 BOM, but UTF-16 LE / BE is not supported. `.editorconfig` declares `charset = utf-8` for `*.ini`.

## Do Not Commit Personal or Secret Data

Before committing, verify that changes do not contain:

- `C:\Users\<name>\...` or other user-specific profile paths
- personal email addresses, phone numbers, or physical addresses
- API keys, access tokens, passwords, Webhook URLs, private keys, or certificates
- private server addresses or internal hostnames
- debug logs containing window titles or other local information
- personalized Shortcut targets that reveal local directory structures

Use generic examples such as `C:\Scripts\Example.ps1` in documentation.

Do not force-add the ignored local `KeyBindings.ini`. Public examples belong under `examples/`, and personal paths or credentials must not be committed.

## Pull Requests

Keep pull requests focused. Describe:

- what changed
- why it changed
- affected behavior
- tests performed
- any new Known Limitation

Do not include runtime logs unless they are necessary and have been reviewed and redacted.
