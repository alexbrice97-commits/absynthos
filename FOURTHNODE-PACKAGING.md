# FOURTHNODE packaging contract (agreed between the distro and browser threads)

Absynth OS is Fedora Atomic (rpm-ostree). FOURTHNODE ships as an **RPM** layered into the image.

| Item | Requirement |
|---|---|
| Package name | `fourthnode` |
| Format | x86_64 RPM, built in the FOURTHNODE repo's own CI |
| Distribution | A signed dnf repo (GitHub Pages or Releases + `fourthnode.repo` file). Not COPR: COPR only accepts open-source, and FOURTHNODE is closed freeware. |
| Install path | **`/usr/lib/fourthnode/`** (or `/usr/lib64/`). **Not `/opt`**: on Atomic, `/opt` points to `/var/opt` and RPM files there are not part of the image. |
| Launcher | `/usr/bin/fourthnode` |
| Desktop file | `/usr/share/applications/fourthnode.desktop`, with `MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;application/xhtml+xml;` and `%U` in `Exec` |
| Icons | `/usr/share/icons/hicolor/<size>/apps/fourthnode.png` (+ scalable SVG) |
| Sandbox | Chromium's own sandbox (namespaces), no setuid helper needed on Fedora |
| Updates | Every image rebuild (daily) pulls the newest RPM, so a Chromium security fix reaches users once the RPM is published. Target: rebuild FOURTHNODE within days of each Chromium stable security release. |
| Default browser | Handled by the distro via `/etc/xdg/mimeapps.list` (already in the draft). Firefox stays as fallback. |
| Policies | Browser ships `/etc/fourthnode/policies/{managed,recommended}/` as `%config(noreplace)`. Absynth OS adds `managed/50-absynth-os.json` (no metrics, no default-browser nag, no background mode; no Safe Browsing keys, since FOURTHNODE compiles Safe Browsing out). |
| Status (Nov 20) | Browser repo drafted at `fourthnode/repo/` to this contract; `.repo` URL is a placeholder until its GitHub Pages site exists. |
