# OneDrive for Business / Windows 11 hardening (local fork)

Local-fork note. Upstream superpowers does not target OneDrive-synced
workspace trees; this fork does. Everything here is manual-by-design —
no script may touch the registry (IT policy).

## The failure this prevents

npm-style dependency trees under a long OneDrive prefix exceed Windows
`MAX_PATH` (260 chars) or OneDrive for Business limits, which crashes the
OneDrive client and drops sync between workstations.

## Rules

1. Live working repos live at a short, non-OneDrive path (e.g. `C:\dev`).
   Finished artifacts only go into OneDrive.
2. `node_modules` never settles under an OneDrive path.
3. No path in this repo exceeds the 90% gate (below).

## Path-length requirement (90% gate)

OneDrive for Business documented limits, and this fork's enforced gate at
90%:

| Limit                  | OneDrive for Business | This fork's gate (90%) |
| ---------------------- | --------------------: | ---------------------: |
| Full path              | 400 characters        | **360 characters**     |
| Single file name       | 255 characters        | **229 characters**     |

Windows note: the more binding limit for dependency trees on Windows 11
is 260 characters (`MAX_PATH`) until Long Paths is enabled. The 360 gate
protects the OneDrive side; keep 260 in mind when placing dep trees.

Enforcement in this fork:

- `scripts/check-path-length.ps1` — the gate itself (no registry access,
  no dependencies). Run manually: `pwsh -NoProfile -File scripts/check-path-length.ps1`
  Optional overrides: `-MaxPathLength`, `-MaxFileName`, `-Root`.
- Pre-commit hook `onedrive-path-length-check` in `.pre-commit-config.yaml`
  (runs when pre-commit is installed).
- GitHub Actions workflow `.github/workflows/path-length.yml` (runs on
  every push/PR in the fork).

## Per-workstation setup (manual steps)

### 1. Long Paths (registry — manual, admin)

Verify (read-only, non-admin):

```powershell
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled
```

Expected: `LongPathsEnabled = 1`. To enable on a machine that does not
have it, an admin must set it (Group Policy: "Enable Win32 long path
support", or registry `LongPathsEnabled = 1` under that key) and reboot.

### 2. Git long-path support (no registry, user-scoped)

```powershell
git config --global core.longpaths true
```

### 3. Global gitignore (no registry, user-scoped)

Create `C:\Users\<you>\.gitignore_global` containing at least:

```
node_modules/
.opencode/node_modules
```

Then:

```powershell
git config --global core.excludesFile "$env:USERPROFILE\.gitignore_global"
```

Why: opencode performs a background `npm install` into `<project>\.opencode`
whenever a project contains an `.opencode` directory; the resulting
`node_modules` must never be committed or OneDrive-synced.

### 4. pnpm is the recommended package manager

This fork pins `packageManager: pnpm@12.11.2` in `package.json`
(corepack picks it up; plain `npm install` still works but is not
recommended). Reasons:

- content-addressable global store — each package version exists on disk
  once, everywhere
- project `node_modules` becomes thin junctions/hardlinks to the store —
  far fewer files and a much shallower real tree, which keeps both the
  260-char Windows limit and OneDrive happy
- no symlinks required on Windows 11 (works with Developer Mode off)

Setup (once, per workstation):

```powershell
npm install -g pnpm
pnpm config set store-dir C:\pnpm-store
```

`C:\pnpm-store` (or any short, non-OneDrive location) keeps the one real
copy of every package outside the synced tree. Do not run `npm install`
inside OneDrive folders; install dependencies only in short-path
locations.

### 5. OneDrive client hygiene

- OneDrive (for Business) settings — exclude `Programming`/`Git` from
  this workstation if the files do not need to be local (right-click the
  OneDrive folder → "Choose folders").
- Large folders that must stay synced: set "Online only" (Files
  On-Demand) so the client does not scan deep local trees.
- Consider changing the OneDrive sync folder location (OneDrive settings)
  from `C:\Users\you\OneDrive - azureford` to a shorter root (e.g.
  `C:\ODF`) — it shortens every synced path by ~50 characters.

## Updating this fork

This workspace's clone is **shallow** (`--depth 1`) and, when packaged via the
snapshot branch (`localfork`), has no shared ancestry with upstream. So a plain
`git fetch origin && git merge origin/main` will **not** work from a snapshot
checkout. To update against newer upstream superpowers:

1. Clone fresh upstream (shallow) alongside:
   ```powershell
   git clone --depth 1 https://github.com/obra/superpowers superpowers-upstream
   ```
2. Re-apply the six fork-local files from this fork into that tree:
   - `windows-onedrive-hardening.md`
   - `scripts/check-path-length.ps1`
   - `.github/workflows/path-length.yml`
   - the `onedrive-path-length-check` hook block in `.pre-commit-config.yaml`
   - the `"packageManager": "pnpm@..."` line in `package.json`
   - the `*.bundle` line in `.gitignore`
3. Commit, then re-run the gate:
   ```powershell
   git add -A
   git commit -m "Local fork: re-apply OneDrive hardening on upstream <new-version>"
   pwsh -NoProfile -File scripts/check-path-length.ps1
   ```

If you have a **non-shallow** clone with shared history, the fast path is:
```powershell
git fetch origin
git merge origin/main
```
