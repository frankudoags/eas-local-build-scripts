# Deployment Scripts

Bash script versions of GitHub Actions workflows for local deployment.

## Prerequisites

1. **GitHub CLI (gh)** - For creating releases

   ```bash
   brew install gh
   gh auth login
   ```

2. **EAS CLI** - For building and submitting apps

   ```bash
   pnpm add -g eas-cli
   eas login
   ```

3. **Environment Setup** - Ensure you have:
   - Xcode installed (for iOS builds)
   - EAS configured with your Apple/Google credentials

## Quick Start with npm Scripts

You can run deployment scripts using convenient npm commands from the project root:

```bash
# Preview deployments
pnpm deploy:preview                 # Deploy both platforms to preview
pnpm deploy:preview:ios             # Deploy iOS only to TestFlight
pnpm deploy:preview:android         # Deploy Android only to Google Play
pnpm deploy:preview:skip-tests      # Deploy without running tests

# Production deployments
pnpm deploy:prod                    # Deploy both platforms to production
pnpm deploy:prod:ios                # Deploy iOS only to App Store
pnpm deploy:prod:android            # Deploy Android only to Google Play Store
pnpm deploy:prod:skip-tests         # Deploy without tests (not recommended)

# Create GitHub releases
pnpm release:preview                # Create draft preview release
pnpm release:prod                   # Create public production release
pnpm release:dev                    # Create draft development release

# Version bumping
pnpm version:major                  # Bump major version (1.0.0 -> 2.0.0)
pnpm version:minor                  # Bump minor version (1.0.0 -> 1.1.0)
pnpm version:patch                  # Bump patch version (1.0.0 -> 1.0.1)
```

---

## Scripts

### 🔵 Preview Deployment (`deploy-preview.sh`)

Builds and submits preview versions to TestFlight and Google Play.

**Direct usage:**

```bash
# Deploy both platforms
./scripts/deploy-preview.sh

# Deploy only iOS
./scripts/deploy-preview.sh --platform ios

# Deploy only Android
./scripts/deploy-preview.sh --platform android

# Skip tests (faster)
./scripts/deploy-preview.sh --skip-tests

# Combined options
./scripts/deploy-preview.sh --platform ios --skip-tests
```

**npm script usage:**

```bash
pnpm deploy:preview                 # Both platforms
pnpm deploy:preview:ios             # iOS only
pnpm deploy:preview:android         # Android only
pnpm deploy:preview:skip-tests      # Skip tests
```

**What it does:**

1. ✅ Runs lint, TypeScript, Prettier, and tests (unless skipped)
2. 📱 Builds iOS/Android with EAS
3. 📤 Submits to TestFlight/Google Play
4. 📝 Generates changelog from git commits
5. 🏷️ Creates a **draft** GitHub release with tag `preview-vX.X.X-TIMESTAMP`

---

### 🔴 Production Deployment (`deploy-production.sh`)

Builds and submits production versions to App Store and Google Play Store.

**Direct usage:**

```bash
# Deploy both platforms
./scripts/deploy-production.sh

# Deploy only iOS
./scripts/deploy-production.sh --platform ios

# Deploy only Android
./scripts/deploy-production.sh --platform android

# Skip tests (faster, but not recommended for production)
./scripts/deploy-production.sh --skip-tests

# Combined options
./scripts/deploy-production.sh --platform ios --skip-tests
```

**npm script usage:**

```bash
pnpm deploy:prod                    # Both platforms
pnpm deploy:prod:ios                # iOS only
pnpm deploy:prod:android            # Android only
pnpm deploy:prod:skip-tests         # Skip tests (not recommended)
```

**What it does:**

1. ⚠️ Prompts for confirmation (production is serious!)
2. ✅ Runs lint, TypeScript, Prettier, and tests (unless skipped)
3. 📱 Builds iOS/Android with EAS
4. 📤 Submits to App Store/Google Play Store
5. 📝 Generates changelog from git commits
6. 🏷️ Creates a **public** GitHub release with tag `vX.X.X-TIMESTAMP`

---

### 🏷️ GitHub Release Creation (`create-release.sh`)

Creates GitHub releases with tags and changelogs. Can be run separately from deployments.

**Direct usage:**

```bash
# Create draft preview release
./scripts/create-release.sh --type preview

# Create public production release
./scripts/create-release.sh --type production

# Create draft development release
./scripts/create-release.sh --type development

# Create public release (for any type)
./scripts/create-release.sh --type preview --public
```

**npm script usage:**

```bash
pnpm release:preview                # Draft preview release
pnpm release:prod                   # Public production release
pnpm release:dev                    # Draft development release
```

**What it does:**

1. 📋 Extracts version from `app.config.ts`
2. 🔢 Generates build number from timestamp
3. 📝 Creates changelog from git commits since last tag
4. 🏷️ Creates GitHub release with appropriate tag
5. 🔗 Provides URL to view the release

**Tag format:**

- Preview: `preview-v1.0.0-202501171200`
- Production: `v1.0.0-202501171200`
- Development: `dev-v1.0.0-202501171200`

---

### 🔢 Version Bumping (`bump-version.sh`)

Automatically increments version numbers in `app.config.ts` and `package.json`.

**Direct usage:**

```bash
# Bump major version (breaking changes)
./scripts/bump-version.sh major    # 1.0.0 -> 2.0.0

# Bump minor version (new features)
./scripts/bump-version.sh minor    # 1.0.0 -> 1.1.0

# Bump patch version (bug fixes)
./scripts/bump-version.sh patch    # 1.0.0 -> 1.0.1
```

**npm script usage:**

```bash
pnpm version:major                 # Bump major version
pnpm version:minor                 # Bump minor version
pnpm version:patch                 # Bump patch version
```

**What it does:**

1. 📖 Reads current version from `app.config.ts`
2. 🔢 Calculates new version based on bump type
3. ✅ Prompts for confirmation
4. 📝 Updates version in both `app.config.ts` and `package.json`
5. 💾 Optionally commits the changes with descriptive message

**Semantic Versioning Guide:**

- **Major (X.0.0)**: Breaking changes, incompatible API changes
- **Minor (x.X.0)**: New features, backwards-compatible

- **Patch (x.x.X)**: Bug fixes, backwards-compatible

**Workflow example:**

```bash
# Fix a bug
pnpm version:patch              # 1.0.0 -> 1.0.1
git push

# Add new feature
pnpm version:minor              # 1.0.1 -> 1.1.0
git push

# Deploy to production
pnpm deploy:prod
pnpm release:prod
```

---

## Environment Variables

The scripts use the same credentials as GitHub Actions. Make sure these are configured in EAS:

- **EXPO_TOKEN** - From Expo dashboard
- **EXPO_APPLE_ID** - Your Apple ID email
- **EXPO_APPLE_PASSWORD** - App-specific password
- **EXPO_TEAM_ID** - From Apple Developer
- **GOOGLE_PLAY_SERVICE_ACCOUNT** - From Google Play Console

Configure them with:

```bash
eas secret:create --scope project --name EXPO_APPLE_PASSWORD --value "xxxx-xxxx-xxxx-xxxx"
```

Or in your `eas.json` submit configuration.

---

## GitHub Release Notes

The scripts automatically:

- Extract version from `app.config.ts`
- Generate build number from timestamp
- Create git tags
- Generate changelog from commits since last tag
- Upload `.ipa` and `.aab` files to the release
- Use GitHub CLI (`gh`) to create releases

**Note:** The scripts use `gh` CLI which requires authentication. Run `gh auth login` first.

---

## Output Files

After running the scripts, you'll have:

**Preview:**

- `android-preview.aab`
- `ios-preview.ipa`
- `changelog.md`
- Git tag: `preview-vX.X.X-TIMESTAMP`

**Production:**

- `android-prod.aab`
- `ios-prod.ipa`
- `changelog.md`
- Git tag: `vX.X.X-TIMESTAMP`

---

## Troubleshooting

### "gh: command not found"

```bash
brew install gh
gh auth login
```

### "eas: command not found"

```bash
pnpm add -g eas-cli
```

### iOS build fails

- Ensure Xcode is installed
- Run `eas build:configure` to set up iOS credentials
- Check that you're logged in to EAS: `eas whoami`

### Android build fails

- Ensure you have Android SDK installed
- Check Google Play credentials in `eas.json`

### Release creation fails

- Ensure `gh` is authenticated: `gh auth status`
- Check you have write permissions to the repository
- Verify the tag doesn't already exist: `git tag -l`

---

## Comparison with GitHub Actions

| Feature         | GitHub Actions   | Local Scripts    |
| --------------- | ---------------- | ---------------- |
| Runs on         | GitHub runners   | Your Mac         |
| iOS builds      | ✅ macOS runner  | ✅ Local Xcode   |
| Android builds  | ✅ Ubuntu runner | ✅ Local or EAS  |
| GitHub releases | ✅ Automatic     | ✅ Via `gh` CLI  |
| Secrets         | GitHub Secrets   | EAS/local config |
| Speed           | ~15-30 min       | ~10-20 min       |
| Cost            | GitHub minutes   | Free (local)     |

**Advantage of local scripts:** Faster feedback, no CI minutes consumed, full control over the process.
