# JacHacks SF Dataset

Source: https://jachacks-sf.devpost.com/project-gallery  (77 projects, 4 pages)
Collected: 2026-09-08

## Files

| File | Records | Size | Description |
|---|---|---|---|
| `data/jachacks_sf_jac_files.jsonl` | 5,232 | 32 MB | Every `.jac` file from 41 cloned repos (includes `jaseci-labs/jaseci` — 4,480 files, 23 MB) |
| `data/jachacks_sf_jac_files_filtered.jsonl` | **752** | 6.0 MB | Filtered — without `jaseci-labs/jaseci` duplication; **training-ready** (`id, entrypoint, source=j​achacks-sf, jac`) |
| `data/jachacks_sf_dataset.jsonl` | 41 | 304 KB | One row per repo (metadata + file list + clone status) |
| `data/jachacks_sf_dataset_filtered.jsonl` | 40 | 38 KB | Same without jaseci |
| `data/jachacks_sf_inventory.json` | — | 349 KB | Full repo inventory (chars, file lists) |
| `data/jachacks_sf_summary.md` | — | — | Human-readable table sorted by .jac count |
| `data/jachacks_sf_repos/` | 36 cloned | 372 MB | Shallow clones (`--depth 1`), gitignored |

## Stats (filtered, without jaseci)

- **40 repos** (41 unique GitHub URLs, minus 1 jaseci duplicate)
- **36 cloned ok**, 5 failed (404/private: EarShot, odoggle, basestay, sitewise, spatium-web)
- **752 `.jac` files**, 5.59 M chars, avg 7.4 KB/file
- Top contributors: Shelfy (112), RAL (51), synqit (49), comeagain- (49), JacRedact (48)

## Schema (per-file)

```json
{"id": "jachacks-sf::user__repo::path__to__file.jac", "entrypoint": "FuncName", "source": "jachacks-sf", "repo": "https://github.com/...", "title": "...", "devpost_url": "...", "github_url": "...", "dirname": "user__repo", "file_path": "path/to/file.jac", "jac": "<source>", "chars": 1234, "lines": 42}
```

## Usage

```bash
# training-ready, no jaseci bloat:
wc -l data/jachacks_sf_jac_files_filtered.jsonl  # 752
# full (includes jaseci self):
wc -l data/jachacks_sf_jac_files.jsonl           # 5232
```

## Notes

- 5 GitHub URLs returned 404 on both https and ssh (`gh repo view` → "Could not resolve") — likely private/deleted after Devpost submission. Inventory marks them `clone_failed` with 0 files.
- `jaseci-labs/jaseci` is the language itself, not a hackathon project; filtered variant excludes it to avoid duplicating the existing jaseci training signal. Keep the unfiltered file if you need the full artifact.
- `.jac` check: sample files expectedly fail `jac check` under `jac 0.36.1` due to version drift (e.g., `lambda e: AuditEvent` → `lambda (e: AuditEvent) { ... }`); raw `jac` source is preserved verbatim for idiomize/finetune.
- Clones are shallow and gitignored (`data/jachacks_sf_repos/` in `.gitignore`).
