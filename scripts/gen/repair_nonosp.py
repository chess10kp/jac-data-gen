#!/usr/bin/env python3
"""Scan and mechanically repair non-OSP units that fail `jac check`.

Datasets (audit_all_generated.DATASETS semantics):
  composer_dataset           data/composer_dataset.jsonl      field "jac"
  js2jac_dataset_idiomatic   data/js2jac_dataset_idiomatic.jsonl  field "jac"
  farm_dataset               data/farm_dataset.jsonl          archetype+walkers
  farm_handler_dataset       data/farm_handler_dataset.jsonl  archetype+walkers
  osp_examples               data/osp_examples/**/*.jac       files

Subcommands:
  scan         check every unit -> data/repair_nonosp_failures.jsonl (+ summary)
  fix-keyword  E0013 backtick/bracket escapes, compiler-in-the-loop
  fix-any      composer-style Unknown/Any annotation + cast repair
  verify       full re-scan, overwrite data/audit_nonosp_report.json

Every fix is verified in-the-loop with the vendored compiler; a unit is only
written back when `jac check` exits 0 on the repaired text.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()
FAIL_OUT = REPO / "data" / "repair_nonosp_failures.jsonl"

FIELD_DATASETS = {
    "composer_dataset": REPO / "data" / "composer_dataset.jsonl",
    "js2jac_dataset_idiomatic": REPO / "data" / "js2jac_dataset_idiomatic.jsonl",
    "farm_dataset": REPO / "data" / "farm_dataset.jsonl",
    "farm_handler_dataset": REPO / "data" / "farm_handler_dataset.jsonl",
}
EXAMPLES_GLOB = "data/osp_examples/**/*.jac"

ERR_CODE = re.compile(r"error\[(E\d+)\]")
DIAG_RE = re.compile(
    r"error\[(E\d+)\]:.*?\n\s*--> (\S+):(\d+):(\d+)", re.S)
E0013_NAME = re.compile(r"error\[E0013\]: '(\w+)' is a keyword")
E1053_TYPE = re.compile(r"error\[E1053\]:.*?of type (\S+)")
E1001_TYPE = re.compile(r"error\[E1001\]: Cannot assign \S+ to (.+?)\s*$",
                        re.M)
RETRYABLE = ("no writable cache directory", "Setting up Jac for first use")

TYPE_CODES = {"E1032", "E1055", "E1054", "E1053", "E1001", "E1002", "E1010",
              "E1011", "E1051", "E1052", "E1030", "E1040"}


# ---------------------------------------------------------------- harness

XDG_CACHE = Path("/tmp/jac_repair_xdg_cache")


def run_jac(cmd: list[str], work: Path, timeout: int = 180) -> tuple[int, str]:
    """One gate command; whole process group killed on timeout (audit semantics).

    Uses a private XDG cache so concurrent compiler-test workloads elsewhere
    on this box (which churn ~/.cache/jac) cannot stall our checks.
    """
    env = dict(os.environ)
    env["XDG_CACHE_HOME"] = str(XDG_CACHE)
    for _ in range(2):
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, text=True, cwd=work,
                             start_new_session=True, env=env)
        try:
            out_b, err_b = p.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            p.kill()
            p.communicate()
            return 124, "timeout"
        out = (out_b or "") + (err_b or "")
        if p.returncode == 0 or not any(s in out for s in RETRYABLE):
            return p.returncode, out
    return p.returncode, out


def warm_cache() -> None:
    """Serialize the one-time compiler cache build before the pool races."""
    XDG_CACHE.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="jac_warm_") as td:
        work = Path(td)
        (work / "warm.jac").write_text("obj Warm { has x: int = 0; }\n")
        run_jac([JAC, "check", "warm.jac"], work, timeout=300)


def check_code(code: str) -> tuple[int, str]:
    """jac check one text in a scratch dir -> (rc, full output)."""
    with tempfile.TemporaryDirectory(prefix="rep_chk_") as td:
        work = Path(td)
        (work / "main.jac").write_text(code)
        return run_jac([JAC, "check", "main.jac"], work)


def diagnostics(out: str) -> list[dict]:
    """[(code, line, col, name, type)] deduped, stable order."""
    seen, outv = set(), []
    for m in DIAG_RE.finditer(out):
        code, ln, col = m.group(1), int(m.group(3)), int(m.group(4))
        nm = E0013_NAME.search(m.group(0))
        ty = E1053_TYPE.search(m.group(0))
        ty1001 = E1001_TYPE.search(m.group(0)) if m.group(1) == "E1001" else None
        tyx = ty.group(1) if ty else \
            (ty1001.group(1).strip() if ty1001 else None)
        if code == "E2055" and "finally" in m.group(0):
            tyx = "finally"
        key = (code, ln, col)
        if key not in seen:
            seen.add(key)
            outv.append({"code": code, "line": ln, "col": col,
                         "name": nm.group(1) if nm else None,
                         "type": tyx})
    return outv


# ---------------------------------------------------------------- units

def load_units(datasets: list[str]) -> list[dict]:
    """Flatten chosen datasets into unit dicts.

    unit = {"ds", "kind", "idx", "key", "code"}
    farm rows are checked as the combined archetype+walkers text (audit
    semantics) and repaired per-field by the fix passes.
    """
    units: list[dict] = []
    for ds in datasets:
        path = FIELD_DATASETS.get(ds)
        if path:
            for i, ln in enumerate(path.read_text().splitlines()):
                if not ln.strip():
                    continue
                r = json.loads(ln)
                if ds.startswith("farm"):
                    code = ((r.get("archetype") or "") + "\n" +
                            (r.get("walkers") or "")).strip()
                else:
                    code = r.get("jac") or ""
                if code.strip():
                    units.append({"ds": ds,
                                  "kind": "farm" if ds.startswith("farm")
                                  else "field",
                                  "idx": i, "key": r.get("id", f"row{i}"),
                                  "code": code})
        elif ds == "osp_examples":
            for p in sorted(REPO.glob(EXAMPLES_GLOB)):
                code = p.read_text()
                if code.strip():
                    units.append({"ds": ds, "kind": "files",
                                  "idx": 0, "key": str(p.relative_to(REPO)),
                                  "code": code, "path": str(p)})
        else:
            raise SystemExit(f"unknown dataset {ds}")
    return units


def scan_unit(unit: dict) -> dict:
    rc, out = check_code(unit["code"])
    codes = ERR_CODE.findall(out)
    return {"ds": unit["ds"], "kind": unit["kind"], "idx": unit["idx"],
            "key": unit["key"], "rc": rc,
            "codes": sorted(set(codes)), "diag": out[-2500:] if codes else ""}


def cmd_scan(args: argparse.Namespace) -> int:
    units = load_units(args.datasets)
    warm_cache()
    print(f"scanning {len(units)} units across {args.datasets} with {JAC}",
          flush=True)
    with FAIL_OUT.open("w") as fo:
        nfail = 0
        with ProcessPoolExecutor(max_workers=args.workers) as ex:
            futs = {ex.submit(scan_unit, u): u for u in units}
            for done, fut in enumerate(as_completed(futs), 1):
                r = fut.result()
                if r["rc"] != 0:
                    fo.write(json.dumps(r) + "\n")
                    nfail += 1
                if done % 1000 == 0:
                    print(f"  {done}/{len(units)} ({nfail} fail)", flush=True)
    print(f"failures: {nfail} -> {FAIL_OUT}", flush=True)
    return 0


# ---------------------------------------------------------------- keyword fix

def _ident_at(s: str, col: int) -> str | None:
    m = re.match(r"\w+", s[col:])
    return m.group(0) if m else None


def apply_keyword_edits(text: str, diags: list[dict]) -> tuple[str, list[str]]:
    """E0013: backtick-escape identifiers; `.kw` -> `["kw"]`."""
    lines = text.split("\n")
    edits: list[str] = []
    by_line: dict[int, list[dict]] = {}
    for d in diags:
        if d["code"] == "E0013":
            by_line.setdefault(d["line"], []).append(d)
    for ln, ds in sorted(by_line.items(), reverse=True):
        if ln - 1 >= len(lines):
            continue
        s = lines[ln - 1]
        for d in sorted(ds, key=lambda d: -d["col"]):
            col = d["col"] - 1
            nm = d["name"] or _ident_at(s, col)
            if nm is None or s[col - 1:col] == "`":
                continue
            if col > 0 and s[col - 1] == ".":
                end = col + len(nm)
                s = s[:col - 1] + f'["{nm}"]' + s[end:]
                edits.append(f'attr->["{nm}"]@{ln}:{col}')
            else:
                s = s[:col] + "`" + s[col:]
                edits.append(f"tick->{nm}@{ln}:{col}")
        lines[ln - 1] = s
    return "\n".join(lines), edits


def repair_keywords(text: str) -> tuple[str, list[str], str]:
    """Compiler-in-the-loop E0013 repair. Returns (text, edits, bail)."""
    all_edits: list[str] = []
    for _ in range(6):
        rc, out = check_code(text)
        if rc == 0:
            return text, all_edits, ""
        diags = [d for d in diagnostics(out) if d["code"] == "E0013"]
        if not diags:
            return text, all_edits, "no-E0013-diag"
        text, edits = apply_keyword_edits(text, diags)
        if not edits:
            return text, all_edits, "no-edit-applied"
        all_edits.extend(edits)
    return text, all_edits, "max-rounds"


# ---------------------------------------------------------------- writeback

ATTR_KIND: dict[str, dict[str, set[str]]] = {
    "dict": {"get", "keys", "values", "items", "setdefault", "update",
             "popitem", "copy", "fromkeys", "pop"},
    "list": {"append", "extend", "insert", "remove", "sort", "reverse",
             "index", "count"},
    "str": {"split", "rsplit", "strip", "lstrip", "rstrip", "replace",
            "startswith", "endswith", "lower", "upper", "title", "capitalize",
            "casefold", "encode", "zfill", "ljust", "rjust",
            "partition", "rpartition", "join", "format", "isalpha", "isdigit",
            "isspace", "isnumeric", "isalnum", "find", "rfind", "center",
            "expandtabs", "removeprefix", "removesuffix", "swapcase",
            "islower", "isupper", "istitle", "splitlines"},
}
STR_METHODS = ATTR_KIND["str"]

NUM_RE_T = r"\b{name}\s*(?://|[%*/+-])\s*[\d.]"
ISINST_T = (r"isinstance\s*\(\s*{name}\s*,\s*"
            r"(dict|list|str|tuple|int|float|set)\s*\)")
CONV_T = r"\b(int|float)\s*\(\s*{name}\s*\)"
STR_LIT_SUB_T = r"{name}\[\s*(['\"])"


def _param_spans(text: str) -> list[tuple[int, int, str]]:
    """(ann_start, ann_end, name) for every `name: Any` inside a def
    parameter list. String-aware paren balancing."""
    spans = []
    for m in re.finditer(r"\bdef\s+\w+\s*\(", text):
        i, depth, n = m.end() - 1, 0, len(text)
        j = i
        while j < n:
            c = text[j]
            if c in "\"'":
                q = c
                j += 1
                while j < n and text[j] != q:
                    j += 2 if text[j] == "\\" else 1
            elif c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        params = text[m.end():j]
        for pm in re.finditer(r"(\*\*?\s*)?(\w+)\s*:\s*(Any)\b", params):
            if pm.group(1):
                continue  # *args/**kwargs: leave alone
            spans.append((m.end() + pm.start(3), m.end() + pm.end(3),
                          pm.group(2)))
    return spans


DOC_PARAM_T = r":param\s+{name}\s*:\s*(\w+)"
DOC_TYPE_MAP = {"float": "num", "int": "num", "str": "str", "string": "str",
                "dict": "dict", "list": "list", "tuple": "list",
                "bool": "num", "ndarray": "list", "array": "list",
                "set": "list"}


def _infer_param_type(text: str, name: str) -> str | None:
    """Concrete annotation for param `name` from body usage, or None."""
    w: dict[str, int] = {"dict": 0, "list": 0, "str": 0, "num": 0, "bytes": 0}
    for m in re.finditer(DOC_PARAM_T.format(name=name), text):
        k = DOC_TYPE_MAP.get(m.group(1).lower())
        if k:
            w[k] += 3
    for m in re.finditer(ISINST_T.format(name=name), text):
        k = m.group(1)
        kk = {"tuple": "list", "set": "list", "int": "num", "float": "num",
              "bool": "num"}.get(k, k)
        if kk in w:
            w[kk] += 3
    for m in re.finditer(rf"\b{name}\.(\w+)\s*\(", text):
        for kind, attrs in ATTR_KIND.items():
            if m.group(1) in attrs:
                w[kind] += 2
    if re.search(rf"\b{name}\.decode\(", text):
        w["bytes"] += 2
    if re.search(rf"\bopen\s*\(\s*{name}\s*[,)]", text):
        w["str"] += 2
    if re.search(rf"\b{name}\s*[/%*]\s*[A-Za-z_]", text):
        w["num"] += 2
    if re.search(rf"\b{name}\s*[+-]\s*[A-Za-z_]", text):
        w["num"] += 1
    if re.search(NUM_RE_T.format(name=name), text):
        w["num"] += 2
    if re.search(STR_LIT_SUB_T.format(name=name), text):
        w["dict"] += 2
    if re.search(rf"\b{name}\[\s*[\w.+-]+\s*\]", text):
        w["list"] += 1
    if re.search(CONV_T.format(name=name), text):
        w["num"] += 1
    best = max(w, key=lambda k: w[k])
    if w[best] == 0:
        return None
    others = [k for k, v in w.items() if k != best and v >= w[best]]
    if others:
        return None  # conflicting evidence: don't guess
    if best == "num":
        return "float" if re.search(rf"\b{name}\s*/[^/]|[.]?\d[.)]", text) \
            else "int"
    return best


def _sub_params(text: str, subs: dict[str, str]) -> str:
    """Rewrite `name: Any` -> `name: T` for def params; right-to-left."""
    spans = [s for s in _param_spans(text) if s[2] in subs]
    for st, en, name in sorted(spans, reverse=True):
        text = text[:st] + subs[name] + text[en:]
    return text


# ---- stage B: per-site casts from live diagnostics ----

CAST_ATTR_TYPE: dict[str, str] = {}
for _k, _attrs in ATTR_KIND.items():
    for _a in _attrs:
        CAST_ATTR_TYPE.setdefault(_a, _k)

_IDENT_BACK_RE = re.compile(r"\w+$")


def _wrap_attr_cast(text: str, ln: int, col: int, attr: str) -> str | None:
    """`BASE.attr` at ln:col -> `(BASE as T).attr` (col 1-indexed at attr)."""
    lines = text.split("\n")
    if ln - 1 >= len(lines):
        return None
    s = lines[ln - 1]
    a0 = col - 1
    if s[a0:a0 + len(attr)] != attr or a0 < 1 or s[a0 - 1] != ".":
        return None
    j = a0 - 2  # char before the dot
    if j < 0:
        return None
    if s[j] == "]":
        depth, k = 0, j
        while k >= 0:
            if s[k] in "\"'":
                q = s[k]
                k -= 1
                while k >= 0 and s[k] != q:
                    k -= 2 if s[k - 1] == "\\" else 1
            elif s[k] == "]":
                depth += 1
            elif s[k] == "[":
                depth -= 1
                if depth == 0:
                    break
            k -= 1
        if k < 0:
            return None
        j = k - 1
    if j < 0:
        return None
    m = _IDENT_BACK_RE.search(s[:j + 1])
    if not m:
        return None
    base = s[m.start():j + 1]
    t = CAST_ATTR_TYPE.get(attr)
    if t is None:
        return None
    lines[ln - 1] = (s[:m.start()] + "(" + base + " as " + t + ")" +
                     s[j + 1:])
    return "\n".join(lines)


def _wrap_arg_cast(text: str, ln: int, col: int, ty: str) -> str | None:
    """Wrap the argument starting at ln:col: `ARG` -> `(ARG as ty)`."""
    lines = text.split("\n")
    if ln - 1 >= len(lines):
        return None
    s = lines[ln - 1]
    i = col - 1
    if i >= len(s) or not re.match(r"[\w('\"+\-[]", s[i]):
        return None
    depth, k, n, in_str = 0, i, len(s), None
    while k < n:
        c = s[k]
        if in_str:
            if c == "\\":
                k += 2
                continue
            if c == in_str:
                in_str = None
        elif c in "\"'":
            in_str = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            if depth == 0:
                break
            depth -= 1
        elif c == "," and depth == 0:
            break
        k += 1
    arg = s[i:k].strip()
    if not arg:
        return None
    jac_ty = ty.replace("NoneType", "None")
    lines[ln - 1] = s[:i] + "(" + arg + " as " + jac_ty + ")" + s[k:]
    return "\n".join(lines)


def _norm_ty(ty: str) -> str:
    return ty.replace("<any>", "any").replace("NoneType", "None").strip()


def _wrap_assign_cast(text: str, ln: int, col: int, ty: str) -> str | None:
    """E1001 at an assignment: cast the RHS to the expected type.

    `x = RHS;` at ln:col (statement start) -> `x = (RHS as TY);`
    """
    lines = text.split("\n")
    if ln - 1 >= len(lines):
        return None
    s = lines[ln - 1]
    i = j = col - 1
    n = len(s)
    eq = -1
    depth = 0
    in_str = None
    while j < n:
        c = s[j]
        if in_str:
            if c == "\\":
                j += 2
                continue
            if c == in_str:
                in_str = None
        elif c in "\"'":
            in_str = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "=" and depth == 0:
            if s[j - 1] in "=+-*/%<>!" or (j + 1 < n and s[j + 1] == "="):
                j += 1
                continue
            eq = j
            break
        j += 1
    if eq < 0:
        return None
    k = eq + 1
    depth, in_str = 0, None
    end = n
    while k < n:
        c = s[k]
        if in_str:
            if c == "\\":
                k += 2
                continue
            if c == in_str:
                in_str = None
        elif c in "\"'":
            in_str = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == ";" and depth == 0:
            end = k
            break
        elif c == "#" and depth == 0:
            end = k
            break
        k += 1
    rhs = s[eq + 1:end].strip()
    if not rhs or len(rhs) > 300 or " as " in rhs:
        return None
    lines[ln - 1] = (s[:eq + 1] + " (" + rhs + " as " + _norm_ty(ty) + ")"
                     + s[end:])
    return "\n".join(lines)


def _retype_subscript_container(text: str, ln: int, ty: str = "list[str]") -> str | None:
    """`NAME[...] = expr` E1001-LiteralString -> retype NAME's decl RHS.

    `parts = wheelname.split('-')` gets `as list[str]`: str methods return
    list[LiteralString], which rejects runtime str writes.
    """
    lines = text.split("\n")
    if ln - 1 >= len(lines):
        return None
    m = re.match(r"\s*([A-Za-z_]\w*)\s*\[", lines[ln - 1])
    if not m:
        return None
    name = m.group(1)
    pat = re.compile(rf"^(\s*){name}\s*=[^=]")
    for i in range(ln - 2, -1, -1):
        dm = pat.match(lines[i])
        if not dm:
            continue
        wrapped = _wrap_assign_cast("\n".join(lines), i + 1,
                                    len(dm.group(1)) + 1, ty)
        return wrapped
    return None


FINALLY_HEAD_RE = re.compile(r"^(\s*)(\}\s*)?finally\s*\{\s*$")


def _unwrap_finally(text: str, ln: int) -> str | None:
    """E2055: hoist `finally {` body out of the try statement.

    try {A} except {B} finally {C}  ->  try {A} except {B} C
    Deletes the finally header and its matching close brace only; the body
    (which contains the offending return at ln) stays in place.
    """
    lines = text.split("\n")
    if ln - 1 >= len(lines):
        return None
    head = None
    for i in range(ln - 1, -1, -1):
        if FINALLY_HEAD_RE.match(lines[i]):
            head = i
            break
    if head is None:
        return None
    # find matching close brace of the finally block; the block is already
    # open at the head line, so scan the body with depth starting at 1
    depth, j, n = 1, head + 1, len(lines)
    close = None
    while j < n and close is None:
        s = lines[j]
        k = 0
        while k < len(s):
            c = s[k]
            if c in "\"'":
                q = c
                k += 1
                while k < len(s) and s[k] != q:
                    k += 2 if s[k] == "\\" else 1
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    close = (j, k)
                    break
            k += 1
        j += 1
    if close is None:
        return None
    cj, ck = close
    if lines[cj].strip() != "}":
        return None  # closer shares a line with code: too risky
    if FINALLY_HEAD_RE.match(lines[head]).group(2):
        # `} finally {` -> `}` (keep closing the previous block)
        lines[head] = re.sub(r"^(\s*)\}.*$", r"\1}", lines[head])
    else:
        del lines[head]
        cj -= 1  # a line was removed above the closer
    del lines[cj]
    return "\n".join(lines)


def cast_rounds(text: str, max_rounds: int = 3) -> tuple[str, list[str], str]:
    """Stage B: iterate diagnostics -> per-site casts until clean."""
    edits: list[str] = []
    for _ in range(max_rounds):
        rc, out = check_code(text)
        if rc == 0:
            return text, edits, ""
        diags = diagnostics(out)
        changed = False
        # apply last-position-first to keep earlier positions valid
        for d in sorted(diags, key=lambda d: (d["line"], d["col"]),
                        reverse=True):
            if d["code"] == "E1032" and d["name"] is None:
                line = text.split("\n")[d["line"] - 1] \
                    if d["line"] - 1 < len(text.split("\n")) else ""
                m = re.match(r"\w+", line[d["col"] - 1:])
                if not m:
                    continue
                new = _wrap_attr_cast(text, d["line"], d["col"], m.group(0))
            elif d["code"] == "E1053" and d["type"] \
                    and re.fullmatch(r"[A-Za-z_][\w.]*", d["type"]) \
                    and d["type"] not in ("Sized", "object"):
                new = _wrap_arg_cast(text, d["line"], d["col"], d["type"])
            elif d["code"] == "E1001":
                if d["type"] == "LiteralString":
                    new = _retype_subscript_container(text, d["line"])
                elif d["type"] and re.fullmatch(r"[\w.]+(\[.+)?", d["type"]):
                    new = _wrap_assign_cast(text, d["line"], d["col"],
                                            d["type"])
                else:
                    new = None
            elif d["code"] == "E2055" and d["type"] == "finally":
                new = _unwrap_finally(text, d["line"])
            else:
                new = None
            if new is not None:
                text = new
                edits.append(f"cast@{d['line']}:{d['col']}:{d['code']}")
                changed = True
        if not changed:
            return text, edits, "casts-exhausted"
    rc, _ = check_code(text)
    return text, edits, ("" if rc == 0 else "max-rounds")


CAND_DEFAULT = ["str", "dict", "list", "int"]


def _weak_candidates(text: str, name: str) -> list[str]:
    cands: list[str] = []
    if re.search(rf"\b{name}\.decode\(", text):
        cands += ["bytes", "str | bytes"]
    if re.search(rf"\bopen\s*\(\s*{name}\s*[,)]", text):
        cands += ["str"]
    if re.search(NUM_RE_T.format(name=name), text) \
            or re.search(CONV_T.format(name=name), text) \
            or re.search(rf"\b{name}\s*[/%*+-]\s*[A-Za-z_]", text):
        cands += ["int", "float"]
    if re.search(rf"\b{name}\[", text) or re.search(rf"\b{name}\s*[=!<>]=?", text) \
            or f"len({name})" in text:
        cands += ["str", "list", "dict"]
    out = list(dict.fromkeys(cands)) or CAND_DEFAULT
    return out


def _stage_a2(text: str, base_err: int) -> tuple[str, int, list[str]]:
    """Greedy per-param annotation trials with error-count attrition.

    Returns (best_text, best_err, applied). Only the rc==0 result of the
    caller matters; a non-zero best is discarded by the caller.
    """
    cur, cur_err, budget = text, base_err, 12
    applied: list[str] = []
    while budget > 0:
        improved = False
        for st, en, nm in _param_spans(cur):
            for cand in _weak_candidates(cur, nm):
                if budget <= 0:
                    break
                trial = cur[:st] + cand + cur[en:]
                rc, out = check_code(trial)
                budget -= 1
                if rc == 0:
                    return trial, 0, applied + [f"{nm}:{cand}"]
                e = _errcount(out)
                if e < cur_err:
                    cur, cur_err = trial, e
                    applied.append(f"{nm}:{cand}")
                    improved = True
                    break
        if not improved:
            break
    return cur, cur_err, applied


HOPELESS_CODES = {"E1054", "E1099", "E1051", "E1110", "E1111", "E1020",
                  "E1004", "E2055"}


def fix_any_worker(unit: dict) -> dict:
    """One row: fresh check -> keyword pass -> param annotations -> casts."""
    res: dict = {"ds": unit["ds"], "kind": unit["kind"], "idx": unit["idx"],
                 "key": unit["key"], "status": "bail", "fields": {},
                 "edits": [], "bail": ""}
    if unit["kind"] == "farm":
        r = _load_row(unit["ds"], unit["idx"])
        texts = {fld: r[fld] for fld in ("archetype", "walkers")
                 if (r.get(fld) or "").strip()}
    elif unit["kind"] == "files":
        texts = {"text": unit["code"]}
    else:
        texts = {"jac": unit["code"]}

    for fld, text in texts.items():
        rc, out = check_code(text)
        if rc == 0:
            continue
        codes = set(ERR_CODE.findall(out))
        if "E0013" in codes:
            text, ed, bail = repair_keywords(text)
            res["edits"] += [f"{fld}:{e}" for e in ed]
            if bail:
                return {**res, "bail": f"{fld}:{bail}"}
            rc, out = check_code(text)
            if rc == 0:
                texts[fld] = text
                continue
            codes = set(ERR_CODE.findall(out))
        # fast triage: structural errors and no parameters to retype
        if codes <= HOPELESS_CODES and not _param_spans(text) \
                and "max(" not in text:
            return {**res, "bail": f"{fld}:structural"}
        # stage A: concrete param annotations
        subs = {}
        for _st, _en, nm in _param_spans(text):
            inf = _infer_param_type(text, nm)
            if inf:
                subs[nm] = inf
        cand = _sub_params(text, subs) if subs else text
        rc1, out1 = check_code(cand)
        if rc1 == 0:
            texts[fld] = cand
            continue
        if subs and _errcount(out1) >= _errcount(out):
            cand = text  # inference did not help: restart from original
            rc1, out1 = rc, out
        # stage A2: greedy weak-evidence annotation trials
        cand, err2, _a2edits = _stage_a2(cand, _errcount(out1))
        rc2, _ = check_code(cand)
        if rc2 == 0:
            texts[fld] = cand
            continue
        # stage B: per-site casts
        text2, ed, bail = cast_rounds(cand)
        res["edits"] += [f"{fld}:{e}" for e in ed]
        rc3, _ = check_code(text2)
        if rc3 != 0:
            return {**res, "bail": f"{fld}:{bail or 'still-failing'}"}
        texts[fld] = text2
    res["status"], res["fields"] = "pass", texts
    return res


def _errcount(out: str) -> int:
    return len(ERR_CODE.findall(out))


def _load_row(ds: str, idx: int) -> dict:
    lines = FIELD_DATASETS[ds].read_text().splitlines()
    return json.loads(lines[idx])


def _jdumps(rec: dict) -> str:
    return json.dumps(rec, ensure_ascii=False)


FIXANY_JOURNAL = REPO / "data" / "repair_nonosp_fixany_results.jsonl"


def _jkey(r: dict) -> str:
    """Journal key: osp_examples units share idx=0, so key matters."""
    return json.dumps([r["ds"], r["idx"], str(r["key"])],
                      separators=(",", ":"))

LLM_SYSTEM = """You fix Jac (0.36.1) source so `jac check` passes. Return ONLY \
the corrected complete Jac source in a ```jac fence. Rules:
- Params/fields need concrete annotations; bare generics (dict, list) are OK.
- `Any` flows into typed ops -> E1032/E1053/E1055; annotate the param with the \
type its usage implies, or `value as Type` casts at use sites (runtime no-op).
- Keywords (`test`, `glob`, `entry`, `exit`, `for`, `class`, ...) as \
identifiers escape with a leading backtick: `test. Attribute: obj["test"].
- Keep runtime semantics identical; never delete code to satisfy the checker.
- No `-> None` on no-return defs; lowercase any as the gradual type only when \
nothing else works."""


def llm_worker(job: tuple[dict, str], backend_name: str, model: str) -> dict:
    """Stage C: LLM repair with compiler-in-the-loop validation."""
    unit, diag = job
    from llm_backend import get_backend  # noqa: PLC0415 (heavy import)
    res: dict = {"ds": unit["ds"], "kind": unit["kind"], "idx": unit["idx"],
                 "key": unit["key"], "status": "bail", "fields": {},
                 "edits": ["llm"], "bail": "llm-fail"}
    if unit["kind"] == "farm":
        row = _load_row(unit["ds"], unit["idx"])
        fields = {fld: (row.get(fld) or "") for fld in
                  ("archetype", "walkers") if (row.get(fld) or "").strip()}
    else:
        fields = {"text" if unit["kind"] == "files" else "jac":
                  unit["code"]}
    for fld, text in fields.items():
        rc, out = check_code(text)
        if rc == 0:
            res["fields"][fld] = text
            continue
        user = ("Make this pass `jac check`. Current diagnostics:\n\n" +
                out[-2500:] + "\n\nSource:\n\n```jac\n" + text + "\n```")
        cand, err, _u = get_backend(backend_name, model).call(
            LLM_SYSTEM, user, model, timeout=240, tries=2)
        if not cand:
            return {**res, "bail": f"llm-error:{err}"}
        m = re.search(r"```(?:jac)?\n(.*)```", cand, re.S)
        cand = m.group(1).strip() if m else cand.strip()
        if len(cand) < max(40, len(text) // 3):
            return {**res, "bail": "llm-truncated"}
        if check_code(cand)[0] != 0:
            return {**res, "bail": "llm-check-fail"}
        res["fields"][fld] = cand
    return {**res, "status": "pass"}


def cmd_llm(args: argparse.Namespace) -> int:
    """LLM fallback for rows the mechanical stages bailed on."""
    sys.path.insert(0, str(REPO / "scripts" / "lib"))
    units = {_jkey(u): u for u in load_units(args.datasets)}
    targets = []
    for r in _journal_rows():
        if r["status"] != "bail":
            continue
        u = units.get(_jkey(r))
        if u is None:
            continue
        rc, out = check_code(u["code"])
        if rc != 0:
            targets.append((u, out[-2500:]))
    targets = targets[:args.limit] if args.limit else targets
    print(f"llm fallback: {len(targets)} rows via {args.backend}/{args.model}",
          flush=True)
    from concurrent.futures import ThreadPoolExecutor
    done = passed = 0
    with FIXANY_JOURNAL.open("a") as jo:
        with ThreadPoolExecutor(max_workers=args.llm_workers) as ex:
            for r in ex.map(lambda j: llm_worker(j, args.backend, args.model),
                            targets):
                jo.write(_jdumps(r) + "\n")
                jo.flush()
                done += 1
                passed += r["status"] == "pass"
                if done % 25 == 0:
                    print(f"  {done}/{len(targets)} ({passed} pass)", flush=True)
    print(f"llm pass {passed}/{done}", flush=True)
    return 0


def cmd_fix_any(args: argparse.Namespace) -> int:
    """Parallel stage-A/B repair; results append to a crash-safe journal."""
    warm_cache()
    fails = [json.loads(l) for l in FAIL_OUT.read_text().splitlines()
             if l.strip()]
    fail_keys = {(f["ds"], f["idx"], str(f["key"])) for f in fails}
    units = [u for u in load_units(args.datasets)
             if (u["ds"], u["idx"], str(u["key"])) in fail_keys]
    print(f"fix-any: {len(units)} failing units", flush=True)
    applied = {_jkey(r) for r in _journal_rows() if r["status"] == "pass"}
    targets = [u for u in units if _jkey(u) not in applied]
    print(f"  {len(targets)} left after journal replay", flush=True)
    done = 0
    with FIXANY_JOURNAL.open("a") as jo:
        with ProcessPoolExecutor(max_workers=args.workers) as ex:
            futs = {ex.submit(fix_any_worker, u): u for u in targets}
            for fut in as_completed(futs):
                u = futs[fut]
                try:
                    r = fut.result()
                except Exception as e:  # one bad row must not kill the sweep
                    r = {"ds": u["ds"], "kind": u["kind"], "idx": u["idx"],
                         "key": u["key"], "status": "bail", "fields": {},
                         "edits": [], "bail": f"worker-crash: {e!r}"}
                jo.write(_jdumps(r) + "\n")
                jo.flush()
                done += 1
                if done % 200 == 0:
                    npass = sum(1 for x in _journal_rows()
                                if x["status"] == "pass")
                    print(f"  {done}/{len(targets)} "
                          f"(journal passes so far: {npass})", flush=True)
    npass = sum(1 for x in _journal_rows() if x["status"] == "pass")
    print(f"fix-any pass {npass}/{len(targets)}", flush=True)
    return 0


def _journal_rows() -> list[dict]:
    if not FIXANY_JOURNAL.exists():
        return []
    return [json.loads(l) for l in FIXANY_JOURNAL.read_text().splitlines()
            if l.strip()]


def cmd_apply(args: argparse.Namespace) -> int:
    """Apply journal passes to the dataset files (last result wins)."""
    rows: dict[str, dict] = {}
    for r in _journal_rows():
        if r["status"] == "pass":
            rows[_jkey(r)] = r
    by_ds: dict[str, list] = {}
    for k, r in rows.items():
        if any(v == "PASSTHROUGH" or len(v) < 40
               for v in r["fields"].values()):
            rows.pop(k)  # degenerate: never write junk back
            continue
        by_ds.setdefault(r["ds"], []).append((r["idx"], r))
    total = 0
    for ds, items in by_ds.items():
        items.sort(key=lambda t: t[0])
        path = FIELD_DATASETS.get(ds)
        if path:
            lines = path.read_text().splitlines()
            for idx, r in items:
                rec = json.loads(lines[idx])
                for fld, text in r["fields"].items():
                    if fld == "text":
                        continue
                    rec[fld] = text
                lines[idx] = _jdumps(rec)
            shutil.copy2(path, str(path) + ".bak")
            path.write_text("\n".join(lines) + "\n")
        else:  # osp_examples files
            for idx, r in items:
                rec_path = REPO / r["key"]
                rec_path.write_text(r["fields"]["text"])
        total += len(items)
    print(f"applied {total} repaired rows across {sorted(by_ds)}", flush=True)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("cmd", choices=["scan", "fix-any", "apply", "llm",
                                    "verify"])
    ap.add_argument("--datasets", type=str,
                    default="composer_dataset,js2jac_dataset_idiomatic,"
                            "farm_dataset,farm_handler_dataset,osp_examples")
    ap.add_argument("--workers", type=int, default=14)
    ap.add_argument("--backend", type=str, default="auto")
    ap.add_argument("--model", type=str, default="composer-2.5")
    ap.add_argument("--llm-workers", type=int, default=6)
    ap.add_argument("--limit", type=int, default=None)
    args = ap.parse_args()
    args.datasets = args.datasets.split(",")
    if args.cmd == "scan":
        return cmd_scan(args)
    if args.cmd == "fix-any":
        return cmd_fix_any(args)
    if args.cmd == "apply":
        return cmd_apply(args)
    if args.cmd == "llm":
        return cmd_llm(args)
    return 1


if __name__ == "__main__":
    sys.exit(main())
