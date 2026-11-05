# Update Log

## 2026-11-05
* **Updated**: the server config is now optional, and without it the build is a plain repack. Updated [overview](/overview.md), [build pipeline](/architecture/build-pipeline.md) (the two variants), [launcher](/architecture/launcher.md) (no import or connect without a config), the [private-key invariant](/invariants/deb-contains-private-key.md), and the [build and test](/playbooks/build-and-test.md) and [desktop install](/playbooks/install-from-the-desktop.md) playbooks.
* **Deprecation**: all four open questions are answered, and their pages are deleted: `questions/does-closing-the-app-disconnect.md` (it does disconnect), `questions/does-gui-install-work.md` (it works), `questions/does-the-server-accept-connections.md` (yes) and `questions/import-while-app-running.md` (the argument is dropped, which the launcher already tolerates). Answers moved into the [vendor client](/integrations/amnezia-client.md), [launcher](/architecture/launcher.md), [desktop install](/playbooks/install-from-the-desktop.md) and [overview](/overview.md) pages.

## 2026-10-29
* **Added**: [desktop install playbook](/playbooks/install-from-the-desktop.md) (App Center / GDebi, why not snap) and the open GUI install question (`questions/does-gui-install-work.md`).

## 2026-10-28
* **Initialization**: Seeded the bundle from the work that built the package: [overview](/overview.md), three modules, one invariant, the vendor integration, three gotchas, a build-and-test playbook and three open questions.
