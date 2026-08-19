"""studio - repo figure galleries. The experiments already render their graphs
to disk (matplotlib pngs under results/); the studio serves those files
verbatim as base64 data-URIs instead of re-deriving charts. Read-only,
allowlisted to the known artifact roots, capped per request."""

import base64;
import models;
import from pathlib { Path }

glob GALLERY_ROOTS: list[str] = ["model-experiments/01-sft-dpo/results", "model-experiments/02-rl-grpo", "model-experiments/03-new/results"];
glob IMG_EXTS: list[str] = [".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg"];
glob MAX_IMAGES: int = 48;
glob MAX_BYTES: int = 4_000_000;

def _is_img(p: Path) -> bool {
    return p.suffix.lower() in IMG_EXTS;
}

def _mime(p: Path) -> str {
    s = p.suffix.lower();
    if s == ".svg" { return "image/svg+xml"; }
    if s == ".jpg" or s == ".jpeg" { return "image/jpeg"; }
    if s == ".webp" { return "image/webp"; }
    if s == ".gif" { return "image/gif"; }
    return "image/png";
}

"""True iff *rel* is a clean relative path inside one of GALLERY_ROOTS."""
def _allowed(rel: str) -> bool {
    if not rel or rel.startswith("/") { return False; }
    for seg in rel.split("/") {
        if seg == ".." or seg == "" { return False; }
    }
    for rt in GALLERY_ROOTS {
        r = str(rt);
        if rel == r or rel.startswith(r + "/") { return True; }
    }
    return False;
}

"""Every dir under the artifact roots that directly contains images:
[{dir, count}], sorted by path."""
def:pub list_galleries() -> list[dict] {
    base = models.data_root();
    out: list = [];
    for rt in GALLERY_ROOTS {
        rp = base / str(rt);
        if not rp.is_dir() { continue; }
        dirs: dict = {};
        for f in rp.rglob("*") {
            if f.is_file() and _is_img(f) {
                d = str(f.parent.relative_to(base));
                cur = int(str(dirs.get(d, 0)));
                dirs[d] = cur + 1;
            }
        }
        names: list = list(dirs.keys());
        names.sort();
        for d in names {
            out.append({"dir": d, "count": dirs[d]});
        }
    }
    return out;
}

"""All images in *rel_dir* (allowlisted), name-sorted, as data-URI payloads:
[{name, mime, b64}]. Oversized files are skipped with a stub entry."""
def:pub gallery_images(rel_dir: str) -> list[dict] {
    if not _allowed(rel_dir) { return []; }
    d = models.data_root() / rel_dir;
    if not d.is_dir() { return []; }
    out: list = [];
    files: list = [];
    for f in d.iterdir() {
        if f.is_file() and _is_img(f) { files.append(f); }
    }
    files.sort(key=lambda p: Path -> str { return p.name; });
    n = 0;
    for f in files {
        if n >= MAX_IMAGES { break; }
        n += 1;
        try {
            size = int(str(f.stat().st_size));
            if size > MAX_BYTES {
                mb = int(size / 1000000);
                out.append({"name": f.name, "mime": "", "b64": "", "note": f"skipped ({mb}MB)"});
                continue;
            }
            raw = f.read_bytes();
            out.append({"name": f.name, "mime": _mime(f), "b64": base64.b64encode(raw).decode(), "note": ""});
        } except Exception {
            out.append({"name": f.name, "mime": "", "b64": "", "note": "unreadable"});
        }
    }
    return out;
}
