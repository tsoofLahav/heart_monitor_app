# Presentation snapshot

Prepared on 2026-09-10 from the current working frontend and backend, including uncommitted source changes. The current files form a presentation snapshot, with both projects' development histories imported as ancestry. It is not a mirror of the deployed service or a claim that all included changes are live.

Included: application source, Flutter assets and voice clips, tests, platform projects, SQL migrations, documentation, and the inference checkpoint.

Excluded: source repositories' `.git` metadata, CI/deployment workflows, private keys and signing files, environment files, local IDE configuration, Python bytecode, dependency caches, native Pods, generated binaries and build outputs.

Presentation-only adjustments:

- Both projects are ordinary folders in a single repository, with updated navigation links.
- The frontend API endpoint is supplied with `--dart-define=BACKEND_URL=...`; the live deployment address was replaced with a placeholder.
- Android build instructions use portable SDK paths and require the reader's own signing files.
- Optional screenshot-test font paths use `FLUTTER_ROOT` instead of the original developer's home directory.

Updates are manual. Copy reviewed source changes into the corresponding folder, retain these presentation-only settings, check for credentials and participant data, and commit a new snapshot. The original remotes and Azure deployment connection are unchanged.

No new license or claim of sole authorship is added by this snapshot. Preserve applicable contributor and third-party notices.

## Imported development history

The original backend main history (22 commits) and frontend main history (4 commits) are imported under their respective subdirectories. Original authors, timestamps and commit messages are retained. Hashes change because paths are rewritten and private-key files, deployment workflows and Python bytecode are excluded from history. Empty commits are retained to preserve the development chronology.

The two import merges intentionally retain the existing presentation files: those files already combine the source projects' committed and uncommitted development changes with presentation-specific configuration. The imported branches provide historical context rather than reverting that snapshot. Git's simplified per-file history can omit side ancestry; use `git log --all --graph` or `git log --full-history -- backend/ frontend/` to explore it.

The original repositories and deployment remotes were not modified. This import adds ancestry through ordinary merge commits and does not force-rewrite the published presentation branch.
