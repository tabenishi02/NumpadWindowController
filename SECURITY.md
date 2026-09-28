# Security Policy

## Supported Versions

Security fixes are currently provided for the latest `v0.1.x` release line.

| Version | Supported |
|---|---|
| latest `v0.1.x` | Yes |
| older versions | No |

## Reporting a Vulnerability

Do not include undisclosed vulnerability details, credentials, tokens, private file paths, logs containing personal information, or other sensitive data in a public Issue.

Preferred reporting method:

1. Use GitHub's **Report a vulnerability** / private vulnerability reporting feature when it is enabled for this repository.
2. If private vulnerability reporting is not available, open a minimal public Issue that contains no exploit details or sensitive information and request a private reporting channel.

When reporting privately, include:

- affected version or commit
- Windows / AutoHotkey version when relevant
- reproduction steps
- expected and actual behavior
- security impact
- a minimal proof of concept when needed

## Scope Notes

NumpadWindowController is a local AutoHotkey utility. The v0.1.0 runtime does not include telemetry or network communication.

Debug logs can contain window titles, process names, HWND values, and other local runtime information. Review and redact logs before sharing them publicly.
