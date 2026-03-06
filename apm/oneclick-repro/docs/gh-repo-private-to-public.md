# How to change a GitHub repository from private to public with `gh`

This quick guide shows how to switch repository visibility using GitHub CLI, so you do not need to navigate the GitHub web UI.

## Why this article exists

Changing visibility in the GitHub UI can be easy to forget and takes time to re-find. This article exists as a time saver: run one command instead of spending several minutes locating the right settings page.

## Prerequisites

- GitHub CLI is installed: `gh --version`
- You are authenticated: `gh auth status`
- You have admin access to the target repository

## Command (private → public)

```bash
gh repo edit OWNER/REPO --visibility public
```

Example:

```bash
gh repo edit TomonoriSoejima/apm-oneclick --visibility public
```

If you are already inside the local repository directory, you can omit `OWNER/REPO`:

```bash
gh repo edit --visibility public
```

## Verify visibility

```bash
gh repo view OWNER/REPO --json visibility,nameWithOwner
```

For a plain one-line output:

```bash
gh api repos/OWNER/REPO --jq '.full_name + " visibility=" + .visibility'
```

## Optional rollback (public → private)

```bash
gh repo edit OWNER/REPO --visibility private
```

## Common issue

If you see an error like `unknown flag: --accept-visibility-change-consequences`, your installed `gh` version does not support that flag. Use the simpler command:

```bash
gh repo edit OWNER/REPO --visibility public
```
