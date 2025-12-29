# Publishing Mojofix to Pixi/Prefix.dev

## Prerequisites

1. **Create a prefix.dev account**
   - Go to https://prefix.dev
   - Sign up for a free account

2. **Install pixi CLI** (you already have this)

## Step-by-Step Publishing Guide

### 1. Login to prefix.dev

```bash
pixi auth login
```

This will open a browser window to authenticate. Follow the prompts.

### 2. Verify Your Package Structure

Your `pixi.toml` should have all required metadata (✅ already done):
- name
- version
- description
- license
- repository
- homepage

### 3. Build the Package

```bash
cd /home/matteo/mojofix
pixi build
```

This creates a conda package from your project.

### 4. Publish to prefix.dev

```bash
pixi upload
```

Or specify the channel explicitly:

```bash
pixi upload --channel prefix.dev
```

### 5. Verify Publication

Once published, users can install with:

```bash
pixi add mojofix
```

## Alternative: Publish to conda-forge (More Visibility)

For wider distribution, you can also publish to conda-forge:

1. **Fork conda-forge/staged-recipes**
   - Go to https://github.com/conda-forge/staged-recipes
   - Click "Fork"

2. **Create a recipe**
   - Add a new folder: `recipes/mojofix/`
   - Create `meta.yaml` with package metadata

3. **Submit Pull Request**
   - The conda-forge team will review
   - Once merged, your package is on conda-forge!

## Quick Start (Recommended)

For now, the fastest way is prefix.dev:

```bash
# 1. Login
pixi auth login

# 2. Build
pixi build

# 3. Publish
pixi upload
```

## Notes

- **First time**: You may need to create a channel on prefix.dev
- **Updates**: Just increment version in `pixi.toml` and re-run `pixi build && pixi upload`
- **Visibility**: prefix.dev packages are immediately available to all pixi users

## Current Limitation

⚠️ **Mojo packages on pixi**: Since Mojo is still in early development, there might not be official support for Mojo packages on prefix.dev yet. You may need to:

1. Package as a source distribution (users clone and build)
2. Wait for official Mojo package support
3. Use GitHub as the primary distribution method for now

For now, users can install by cloning:
```bash
git clone https://github.com/asdrubale88/mojofix
cd mojofix
pixi install
```
