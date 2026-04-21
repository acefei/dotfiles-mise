---
name: using-skillfile
description: Use when working with skillfile for daily skill management tasks such as installing, searching, adding, removing, or checking status
---

# Using Skillfile

## Overview

`skillfile` tracks AI skills declaratively in this repo via `Skillfile` and `Skillfile.lock`, then deploys them to the configured platforms.

In this repo, the active install targets are `claude-code` and `copilot`.

## When to Use

- Use when you want to install the skills declared in this repo.
- Use when you want to see what is currently tracked or deployed.
- Use when you want to search for a community skill before adding it.
- Use when you want to add or remove a local or remote skill entry from `Skillfile`.

## Quick Reference

```bash
# Install all skills pinned by Skillfile.lock
skillfile install

# Show tracked entries and current state
skillfile status

# Search community registries
skillfile search "code review"

# Add a local skill from this repo
skillfile add local skill skills/using-skillfile/SKILL.md

# Add a GitHub-hosted skill
skillfile add github skill owner/repo skills/some-skill

# Remove a tracked skill entry
skillfile remove using-skillfile

# Validate the manifest after editing Skillfile by hand
skillfile validate
```

## Repo Notes

- Local skills in this repo live under `skills/<name>/SKILL.md`.
- After adding or removing entries manually, run `skillfile validate`.
- Commit `Skillfile`, `Skillfile.lock`, and local `skills/` changes together when applicable.