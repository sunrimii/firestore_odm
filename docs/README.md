# Firestore ODM Documentation

This directory contains the VitePress documentation site for Firestore ODM.

## Development

To run the documentation site locally:

```bash
cd docs
npm install
npm run dev
```

## Building

To build the documentation:

```bash
cd docs
npm run build
```

The built site will be in `docs/.vitepress/dist/`.

## Deployment

The documentation is automatically deployed to GitHub Pages when changes are pushed to the `main` branch in the `docs/` directory.

The deployment is handled by the GitHub Actions workflow at `.github/workflows/deploy-docs.yml`.

## Site URL

Once deployed, the documentation will be available at:
https://sylphxltd.github.io/firestore_odm/