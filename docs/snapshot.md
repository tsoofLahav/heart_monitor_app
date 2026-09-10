# Presentation snapshot

Prepared on 2026-09-10 from the current working frontend and backend, including uncommitted source changes. This is a code snapshot, not a mirror of the deployed service or a claim that all included changes are live.

Included: application source, Flutter assets and voice clips, tests, platform projects, SQL migrations, documentation, and the inference checkpoint.

Excluded: source repositories' `.git` metadata, CI/deployment workflows, private keys and signing files, environment files, local IDE configuration, Python bytecode, dependency caches, native Pods, generated binaries and build outputs.

Presentation-only adjustments:

- Both projects are ordinary folders in a single repository, with updated navigation links.
- The frontend API endpoint is supplied with `--dart-define=BACKEND_URL=...`; the live deployment address was replaced with a placeholder.
- Android build instructions use portable SDK paths and require the reader's own signing files.
- Optional screenshot-test font paths use `FLUTTER_ROOT` instead of the original developer's home directory.

Updates are manual. Copy reviewed source changes into the corresponding folder, retain these presentation-only settings, check for credentials and participant data, and commit a new snapshot. The original remotes and Azure deployment connection are unchanged.

No new license or claim of sole authorship is added by this snapshot. Preserve applicable contributor and third-party notices.
