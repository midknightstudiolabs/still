# Run Still on GitHub Pages

GitHub Pages serves the Flutter browser build. GitHub Actions installs Flutter on Linux, checks the source, runs the journey tests, builds the site, and deploys it only if those steps succeed.

## One-time setup

1. Create or choose a GitHub repository. On GitHub Free, Pages is available for public repositories. Private repositories need an eligible plan. A public repository makes the uploaded source visible; it does not upload users’ locally saved journal data.
2. Put the **contents of the `still` folder** at the repository root. Include `.github/workflows/pages.yml`, `pubspec.yaml`, `pubspec.lock`, `lib`, `test`, `assets`, and `web`. Do not upload `.dart_tool` or `build`.
3. Use `main` as the default branch, or update the workflow branch names to match your repository.
4. Open **Settings → Pages → Build and deployment → Source → GitHub Actions**.
5. Open **Actions → Test and publish Still → Run workflow**. Subsequent pushes to `main` rebuild and redeploy automatically. Pull requests run checks and compile the app without publishing it.
6. Open the URL shown by the successful **Publish to GitHub Pages** job. A project repository normally uses `https://<owner>.github.io/<repository>/`.

The workflow uses Pages metadata to set Flutter’s base path, so project repositories and root/custom-domain sites can load their assets correctly. No access token needs to be added as a repository secret; the deployment uses GitHub’s short-lived workflow credentials.

## What users get

- The same Flutter interface in a desktop or mobile browser.
- Demo mode, vision creation, proof, check-ins, Memories, and settings.
- Per-browser local storage. Photos selected in the app are kept in that local snapshot; they are not committed to the repository or sent to GitHub by the app.

This does not create an App Store or Play Store installation. Browser storage is separate from any native installation, can be cleared or evicted, and does not sync. Larger photos can exhaust browser storage sooner than native storage. Native widgets and reminders remain deferred.

## Validation

This workflow has been prepared locally but has **not yet run on GitHub**. The original Windows environment passed static analysis but could not execute Flutter’s runtime. The first cloud run must pass before the hosted app is treated as verified. Deployment intentionally stops if a test or build fails.

References: [GitHub Pages workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages), [Flutter web deployment](https://docs.flutter.dev/deployment/web).
