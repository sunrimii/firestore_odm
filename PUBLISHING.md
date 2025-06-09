# Publishing Guide for Firestore ODM

This guide explains how to publish new versions of the Firestore ODM packages.

## 🚀 Quick Release Process

### Automated Release (Recommended)

1. **Ensure all changes are merged to `main`**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Run quality checks**
   ```bash
   # Windows
   scripts\dev.bat check
   
   # Linux/macOS
   ./scripts/dev.sh check
   ```

3. **Create release via GitHub Actions**
   - Go to GitHub Actions > Release workflow
   - Click "Run workflow"
   - Choose version type (patch/minor/major)
   - Run the workflow

4. **Packages will be automatically published** when the release is created

### Manual Release Process

If you need to release manually:

1. **Bootstrap workspace**
   ```bash
   melos bootstrap
   ```

2. **Run all checks**
   ```bash
   melos run check
   ```

3. **Preview version changes**
   ```bash
   melos run version:check
   ```

4. **Version packages**
   ```bash
   # Patch version (1.0.0 -> 1.0.1)
   melos version --patch --yes
   
   # Minor version (1.0.0 -> 1.1.0)
   melos version --minor --yes
   
   # Major version (1.0.0 -> 2.0.0)
   melos version --major --yes
   ```

5. **Dry run publish**
   ```bash
   melos run publish:dry-run
   ```

6. **Publish packages**
   ```bash
   melos run publish
   ```

## 📦 Package Information

| Package | Description | pub.dev |
|---------|-------------|---------|
| `firestore_odm_annotation` | Pure annotations | [![pub package](https://img.shields.io/pub/v/firestore_odm_annotation.svg)](https://pub.dev/packages/firestore_odm_annotation) |
| `firestore_odm` | Core ODM functionality | [![pub package](https://img.shields.io/pub/v/firestore_odm.svg)](https://pub.dev/packages/firestore_odm) |
| `firestore_odm_builder` | Code generator | [![pub package](https://img.shields.io/pub/v/firestore_odm_builder.svg)](https://pub.dev/packages/firestore_odm_builder) |

## 🔒 Prerequisites for Publishing

### Setup pub.dev Authentication

1. **Get pub.dev token**
   - Go to [pub.dev](https://pub.dev)
   - Sign in with your Google account
   - Go to Account > Tokens
   - Create a new token

2. **Configure local publishing (for manual releases)**
   ```bash
   dart pub token add https://pub.dev
   ```

3. **Configure GitHub Secrets (for automated releases)**
   - Go to repository Settings > Secrets and variables > Actions
   - Add `PUB_TOKEN` secret with your pub.dev token

### Verify Publishing Rights

Ensure you have publishing rights for all packages:
- `firestore_odm_annotation`
- `firestore_odm`
- `firestore_odm_builder`

## 🧪 Pre-Release Checklist

Before releasing, ensure:

- [ ] All tests pass (`melos run test:all`)
- [ ] Code is properly formatted (`melos run format:check`)
- [ ] Static analysis passes (`melos run analyze`)
- [ ] Example builds successfully (`melos run build:example`)
- [ ] CHANGELOG.md is updated
- [ ] Breaking changes are documented
- [ ] Version numbers are consistent

## 📋 Version Strategy

We follow [Semantic Versioning](https://semver.org/):

- **PATCH** (1.0.0 → 1.0.1): Bug fixes, no breaking changes
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **MAJOR** (1.0.0 → 2.0.0): Breaking changes

### Pre-release Versions

For beta/alpha releases:

```bash
# Create prerelease version
melos version --prerelease --preid=beta --yes

# Example: 1.0.0 -> 1.0.1-beta.0
```

## 🔄 Release Workflow

### 1. Development Phase
- Create feature branches
- Make changes
- Add tests
- Update documentation

### 2. Pre-Release Phase
- Merge to `develop` branch (if using gitflow)
- Run comprehensive tests
- Update CHANGELOG.md
- Create release candidate

### 3. Release Phase
- Merge to `main` branch
- Create GitHub release
- Packages auto-publish to pub.dev
- Update documentation

### 4. Post-Release Phase
- Monitor for issues
- Update dependent projects
- Plan next release

## 🚨 Troubleshooting

### Common Issues

**Publishing fails with authentication error:**
```bash
# Re-authenticate
dart pub token add https://pub.dev
```

**Version conflicts:**
```bash
# Check current versions
melos list --long

# Reset to last published versions
git checkout HEAD~1 -- packages/*/pubspec.yaml
```

**Tests fail:**
```bash
# Clean and rebuild
melos run clean
melos bootstrap
melos run test:all
```

### Emergency Rollback

If you need to rollback a release:

1. **Yank the published version**
   ```bash
   dart pub uploader --add-uploader your-email@example.com firestore_odm
   dart pub admin yank firestore_odm 1.0.1
   ```

2. **Create hotfix release**
   ```bash
   git revert <problematic-commit>
   melos version --patch --yes
   melos run publish
   ```

## 📞 Support

- **GitHub Issues**: [Report bugs](https://github.com/sylphxltd/firestore_odm/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/sylphxltd/firestore_odm/discussions)
- **Email**: your-team@example.com

## 📝 Release Notes Template

When creating releases, use this template:

```markdown
## 🚀 What's New

- New feature description
- Another feature

## 🐛 Bug Fixes

- Fixed issue with X
- Resolved problem with Y

## 💥 Breaking Changes

- Changed API for Z (migration guide: ...)

## 📦 Dependencies

- Updated dependency X to version Y
- Added new dependency Z

## 🔗 Links

- [Migration Guide](link-to-migration-guide)
- [Documentation](link-to-docs)
- [Examples](link-to-examples)