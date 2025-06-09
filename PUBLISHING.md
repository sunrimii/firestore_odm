# 📦 Publishing Guide

This document explains how to publish packages in the Firestore ODM monorepo using Melos and GitHub Actions.

## 🚀 Quick Start

### Method 1: GitHub Actions (Recommended)

1. **Manual Release**:
   - Go to GitHub Actions → Release & Publish
   - Click "Run workflow"
   - Choose options:
     - ✅ Run automatic versioning
     - ✅ Actually publish to pub.dev
   - Click "Run workflow"

2. **Tag-based Release**:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

### Method 2: Local Commands

```bash
# 1. Preview version changes
melos version --dry-run

# 2. Update versions
melos version

# 3. Dry-run publish test
melos run publish:dry-run

# 4. Publish to pub.dev
melos run publish:packages
```

## 🔧 Setup Requirements

### GitHub Secrets

Add these secrets to your GitHub repository:

1. **PUB_CREDENTIALS** (Required for publishing)
   ```bash
   # Generate credentials
   dart pub login
   
   # Copy credentials file content
   cat ~/.pub-cache/credentials.json
   
   # Add to GitHub Secrets as PUB_CREDENTIALS
   ```

### Repository Settings

Enable in Settings → Actions → General:
- ✅ "Allow GitHub Actions to create and approve pull requests"
- ✅ "Allow GitHub Actions to create releases"

## 📋 Publishing Process

### 1. Pre-Publishing Checklist

- [ ] All tests pass locally
- [ ] Code follows formatting standards
- [ ] Documentation is updated
- [ ] CHANGELOG.md is current
- [ ] No breaking changes without version bump

### 2. Automated Workflow

The GitHub Action automatically:

1. **Quality Checks**
   - Runs all tests
   - Validates code formatting
   - Performs static analysis
   - Dry-run publish validation

2. **Versioning**
   - Uses conventional commits for automatic versioning
   - Updates package versions
   - Updates dependencies between packages
   - Generates/updates CHANGELOG.md

3. **Publishing**
   - Publishes packages in dependency order:
     1. `firestore_odm_annotation`
     2. `firestore_odm` 
     3. `firestore_odm_builder`
   - Creates GitHub release
   - Verifies packages are available on pub.dev

### 3. Dependency Management

During development:
```yaml
dependencies:
  firestore_odm_annotation:
    path: ../firestore_odm_annotation  # ✅ Local development
```

During publishing, Melos automatically:
```yaml
dependencies:
  firestore_odm_annotation: ^1.0.0    # ✅ Published version
```

## 🔍 Troubleshooting

### Common Issues

1. **Publishing Fails**
   ```bash
   # Check credentials
   dart pub login
   
   # Test dry-run locally
   melos run publish:dry-run
   ```

2. **Version Conflicts**
   ```bash
   # Manual version bump
   melos version firestore_odm_annotation major
   ```

3. **Path Dependencies in Published Package**
   - This is automatically handled by Melos
   - Ensure you're using the GitHub Actions workflow

### Validation Commands

```bash
# Check package health
dart pub deps --style=tree

# Validate package
dart pub publish --dry-run

# Check for issues
dart analyze

# Format code
dart format .
```

## 📊 Release Strategy

### Version Numbers

We follow [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features (backward compatible)
- **Patch** (0.0.1): Bug fixes

### Conventional Commits

Use conventional commit messages for automatic versioning:

```bash
feat: add new query builder feature          # → Minor version bump
fix: resolve null pointer exception          # → Patch version bump
feat!: change API for better performance     # → Major version bump
docs: update README examples                 # → No version bump
```

### Release Branches

- `main`: Stable releases
- `develop`: Development (optional)
- `feature/*`: Feature branches
- `hotfix/*`: Critical fixes

## 🎯 Best Practices

### Development Workflow

1. Work with path dependencies for local development
2. Use `melos bootstrap` to link workspace packages
3. Run `melos run check` before committing
4. Use conventional commit messages

### Release Workflow

1. Merge changes to main branch
2. Use GitHub Actions for releasing
3. Verify packages on pub.dev
4. Update documentation if needed

### Package Quality

- Keep packages focused and lightweight
- Include comprehensive tests
- Maintain good documentation
- Follow Dart package conventions

## 🔗 Links

- [Melos Documentation](https://melos.invertase.dev/)
- [Pub.dev Publishing](https://dart.dev/tools/pub/publishing)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

## 📞 Support

If you encounter issues:

1. Check this guide first
2. Review the GitHub Actions logs
3. Open an issue on GitHub
4. Contact the maintainers

---

**Happy Publishing! 🚀**