# Contributing

Contributions are welcome.

## Development Environment

The current MVP targets:

- Windows 11
- AutoHotkey v2
- PowerShell for the test runner

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

Changes that affect input handling, Auto Bind, NumLock lifecycle, Shortcut execution, or Configuration validation should include appropriate regression coverage.

## Configuration Encoding

`KeyBindings.ini` and the distributed example configuration use UTF-16 LE with BOM.

Do not convert these files to UTF-8 or remove the BOM.

## Do Not Commit Personal or Secret Data

Before committing, verify that changes do not contain:

- `C:\Users\<name>\...` or other user-specific profile paths
- personal email addresses, phone numbers, or physical addresses
- API keys, access tokens, passwords, Webhook URLs, private keys, or certificates
- private server addresses or internal hostnames
- debug logs containing window titles or other local information
- personalized Shortcut targets that reveal local directory structures

Use generic examples such as `C:\Scripts\Example.ps1` in documentation.

If you temporarily put personal paths in the tracked `KeyBindings.ini`, restore the public-safe version before committing.

## Pull Requests

Keep pull requests focused. Describe:

- what changed
- why it changed
- affected behavior
- tests performed
- any new Known Limitation

Do not include runtime logs unless they are necessary and have been reviewed and redacted.
