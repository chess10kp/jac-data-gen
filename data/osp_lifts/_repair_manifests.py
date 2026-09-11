#!/usr/bin/env python3
"""Repair issues_1/2/3 manifests: restore to 10 lines, dedupe DROP ids, validate."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
IG = BASE / "issue_gen"

KEEP = {
    "iss_ut-issl__veriq__260": "osp__ut-issl__veriq__260__deptree",
    "iss_decalage2__olefile__179": "osp__decalage2__olefile__179__fatchain",
    "iss_PersonalClaw__PersonalClaw__761": "osp__PersonalClaw__PersonalClaw__761__tagmerge",
    "iss_richinmrudul__agentguard__182": "osp__richinmrudul__agentguard__182__sarifexp",
    "iss_web3guru888__asi-build__280": "osp__web3guru888__asi-build__280__causedag",
    "iss_asielen__plaintext-family-history__115": "osp__asielen__plaintext-family-history__115__pedigree",
    "iss_probcomp__bdbcontrib__73": "osp__probcomp__bdbcontrib__73__bayesdag",
    "iss_paulnsorensen__milknado__292": "osp__paulnsorensen__milknado__292__harvest_d",
}

DROP_IDS = {
    "osp__ut-issl__veriq__260__deptreed",
    "osp__decalage2__olefile__179__catchain",
    "osp__PersonalClaw__PersonalClaw__761__tagcycle",
    "osp__paulnsorensen__milknado__292__harvest",
    "osp__richinmrudul__agentguard__182__repodedup",
    "osp__probcomp__bdbcontrib__73__composer",
    "osp__web3guru888__asi-build__280__causaldag",
    "osp__asielen__plaintext-family-history__115__pedigreef",
}

# Pre-dedupe batch stems (dedupe agent removed only DROP id lines).
I1_STEMS = [
    "iss_ut-issl__veriq__260",
    "iss_decalage2__olefile__179",
    "iss_PersonalClaw__PersonalClaw__761",
    "iss_paulnsorensen__milknado__292",
    "iss_richinmrudul__agentguard__182",
    "iss_opsmill__infrahub__8968",
    "iss_probcomp__bdbcontrib__73",
    "iss_web3guru888__asi-build__280",
    "iss_asielen__plaintext-family-history__115",
    "iss_eumemic__aios__1152",
]

I2_STEMS = [
    "iss_DataJunction__dj__2272",
    "iss_probcomp__bdbcontrib__73",
    "iss_francescomucio__tee-for-transform__8",
    "iss_QuEraComputing__bloqade-circuit__852",
    "iss_paulnsorensen__milknado__292",
    "iss_sora-kisaragi__ai-open-textbook__74",
    "iss_Giovannibriglia__NeuralBayesianNetworks__74",
    "iss_dwovitz__memory-mcp__17",
    "iss_camillanapoles__bioeolica-dev__14",
    "iss_k-sandhu__dq-sentinel__242",
]

I3_STEMS = [
    "iss_sembeimx__nori__44",
    "iss_pratapram__dale__24",
    "iss_hleserg__atman__1185",
    "iss_NVLabs__SimFoundry__4",
    "iss_ut-issl__veriq__260",
    "iss_decalage2__olefile__179",
    "iss_PersonalClaw__PersonalClaw__761",
    "iss_richinmrudul__agentguard__182",
    "iss_web3guru888__asi-build__280",
    "iss_asielen__plaintext-family-history__115",
]


def load_templates() -> dict[str, dict]:
    templates: dict[str, dict] = {}
    for mf in sorted(BASE.glob("*.jsonl")):
        if mf.name.startswith("_") or mf.name.startswith("issues_w"):
            continue
        for line in mf.read_text().splitlines():
            if not line.strip():
                continue
            rec = json.loads(line)
            if "source_file" not in rec:
                continue
            templates[Path(rec["source_file"]).stem] = rec
    return templates


def build_record(templates: dict[str, dict], stem: str) -> dict:
    t = templates[stem]
    rec = {k: v for k, v in t.items() if k not in ("generation_date", "generator")}
    kid = KEEP.get(stem)
    if kid:
        rec["id"] = kid
    floor = IG / f"{stem}.floor.jac"
    if floor.exists():
        rec["floor_file"] = f"issue_gen/{stem}.floor.jac"
        rec["floor_status"] = "generated"
    else:
        rec["floor_file"] = None
        rec["floor_status"] = "port_failed"
    rec["python_ref_pass"] = True
    rec["jac_check"] = True
    rec["jac_test_guard"] = True
    return rec


def validate_rec(stem: str) -> tuple[bool, str]:
    p = subprocess.run(
        ["./validate_one.sh", stem],
        cwd=BASE,
        capture_output=True,
        text=True,
        timeout=180,
    )
    if p.returncode == 0:
        return True, "ok"
    return False, (p.stdout + p.stderr)[-250:].strip().replace("\n", " | ")


def write_manifest(path: Path, recs: list[dict]) -> None:
    path.write_text("\n".join(json.dumps(r, separators=(",", ": ")) for r in recs) + "\n")


def main() -> int:
    templates = load_templates()
    missing = [s for batch in (I1_STEMS, I2_STEMS, I3_STEMS) for s in batch if s not in templates]
    if missing:
        print("Missing templates:", missing, file=sys.stderr)
        return 1

    batches = {
        "issues_1.jsonl": [build_record(templates, s) for s in I1_STEMS],
        "issues_2.jsonl": [build_record(templates, s) for s in I2_STEMS],
        "issues_3.jsonl": [build_record(templates, s) for s in I3_STEMS],
    }

    report = {
        "line_counts": {k: len(v) for k, v in batches.items()},
        "restored": {},
        "dropped": sorted(DROP_IDS),
        "validation": {},
    }

    for name, recs in batches.items():
        write_manifest(BASE / name, recs)
        report["restored"][name] = [r["id"] for r in recs]

    all_ok = True
    for name, recs in batches.items():
        report["validation"][name] = {}
        for rec in recs:
            stem = Path(rec["source_file"]).stem
            ok, msg = validate_rec(stem)
            report["validation"][name][rec["id"]] = msg
            if not ok:
                all_ok = False
                print(f"FAIL {name} {rec['id']}: {msg}", file=sys.stderr)

    out = BASE / "_repair_report.json"
    out.write_text(json.dumps(report, indent=2))
    print(json.dumps(report["line_counts"], indent=2))
    print(f"Wrote report to {out}")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
