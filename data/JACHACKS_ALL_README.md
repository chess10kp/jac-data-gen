# JacHacks Combined Dataset (SF + Spring + 2026)

Sources:
- SF: https://jachacks-sf.devpost.com/project-gallery  — 77 projects, 41 GitHub URLs, 36 cloned
- Spring: https://jachacks-spring.devpost.com/project-gallery  — 79 projects, 65 unique URLs (63 projects), 58 cloned
- 2026: https://jachacks-2026.devpost.com/project-gallery  — 65 projects, 51 unique URLs (48 projects), 45 cloned

## Filtered (training-ready, without jaseci)

| Edition | Repos (filtered) | .jac files | Chars | Avg/file |
|---|---|---|---|---|
| SF | 40 | 752 | 5,593,621 | 7,436 |
| Spring | 64 | 305 | 2,167,054 | 7,105 |
| 2026 | 49 | 763 | 4,467,318 | 5,854 |
| **Combined** | **153** | **1,820** | **12,227,993** | 6,718 |

Full (with jaseci): SF 5,232 / Spring 4,785 / 2026 7,014 = 17,031 files (101 MB) — duplicated jaseci; use filtered for training.

## Files

Per-edition:
- `data/jachacks_{sf,spring,2026}_jac_files.jsonl` — all .jac (includes jaseci)
- `data/jachacks_{sf,spring,2026}_jac_files_filtered.jsonl` — **without any jaseci** (training-ready)
- `data/jachacks_{sf,spring,2026}_dataset.jsonl` — per-repo metadata
- `data/jachacks_{sf,spring,2026}_summary.md`, `_inventory.json`
- `data/jachacks_scrape/jachacks_{sf,spring,2026}_{github,devpost}_*.{json,csv,md,txt}` (moved from repo root 2026-09-22)

Combined:
- `data/jachacks_all_jac_files_filtered.jsonl` — 1,820 files (12.2 M chars)
- `data/jachacks_all_jac_files.jsonl` — 17,031 files (101 MB)
- `data/jachacks_all_dataset_filtered.jsonl` — 153 repos
- `data/jachacks_{sf,spring,2026}_repos/` — shallow clones, gitignored

## Edition specifics

**SF**: 77→41 GitHub, 5 failed (EarShot, odoggle, basestay, sitewise, spatium-web). Top: Shelfy 112, RAL 51.

**Spring**: 79→65 URLs, 7 failed (CONSILIUM, Reposense, MedGuardian, SamenSHossain/jachacks, autoauto, SkyJac, SwasthAI). Top: Flair 41, CivicMesh 36.

**2026**: 65→51 URLs, 6 failed (Hapi, chess10kp/jachacks, JOATBerg, Kentro-AI, OpenDAG, Vortex). 2026 filtered excludes both Jaseci-Labs/jaseci and mabusid/jaseci forks (1,776 files) to avoid bloat. Top filtered: Agewise 265, GhostWatch 86, CareAnchor 40, AlphaWalker 40 etc.

## Schema

```json
{"id":"jachacks-{sf,spring,2026}::user__repo::path.jac","entrypoint":"Func","source":"jachacks-2026","repo":"https://github.com/...","title":"...","devpost_url":"...","github_url":"...","dirname":"user__repo","file_path":"path/to/file.jac","jac":"<source>","chars":1234,"lines":42}
```

## Usage

```bash
wc -l data/jachacks_all_jac_files_filtered.jsonl  # 1820
wc -l data/jachacks_all_jac_files.jsonl           # 17031
```
