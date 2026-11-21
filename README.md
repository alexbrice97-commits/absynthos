# Absynth OS (draft)

Custom Fedora Atomic image for Absynth Laboratories: FL Studio via Wine, FOURTHNODE as default browser,
WireGuard VPN, security suite. Built with BlueBuild. **Not built or published yet.**

- `recipes/recipe.yml` — what goes into the OS
- `files/system/` — config copied onto the OS root
- `.github/workflows/build.yml` — GitHub Actions builds and signs the image daily
- `FOURTHNODE-PACKAGING.md` — what the browser must ship so it slots in

To go live: the repo exists; `cosign.pub` is committed. Add the private key
as the `SIGNING_SECRET` Actions secret, then run the workflow.
Install: from any Fedora Atomic system, `rpm-ostree rebase ostree-unverified-registry:ghcr.io/alexbrice97-commits/absynthos:latest`.
