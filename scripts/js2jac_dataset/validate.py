#!/usr/bin/env python3
"""Batch-validate the js2jac pilot corpus through bridge + jac check.

Updates pilot_manifest.json with jac_sha256 and conversion evidence.

Usage:
    ./validate.py [--pilot-dir DIR] [--manifest PATH] [--fail-fast]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PILOT = os.path.normpath(
    os.path.join(HERE, "..", "..", "jaseci", "jac", "tests", "compiler", "js2jac", "pilot")
)
DEFAULT_MANIFEST = os.path.join(HERE, "pilot_manifest.json")
JAC_DIR = os.path.normpath(
    os.path.join(HERE, "..", "..", "jaseci", "jac", "jaclang", "compiler", "js2jac")
)
JAC_REPO = os.path.normpath(os.path.join(HERE, "..", "..", "jaseci", "jac"))
RULE_SET_VERSION = "js2jac-client-v1"


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def run_bun(script: str, payload: dict) -> dict:
    proc = subprocess.run(
        ["bun", script],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"bun {os.path.basename(script)} crashed:\n{proc.stderr}")
    return json.loads(proc.stdout)


def lang_from_path(path: str) -> str:
    ext = path.rsplit(".", 1)[-1].lower()
    return {"tsx": "tsx", "jsx": "jsx", "ts": "ts", "js": "js"}[ext]


def convert_source(source: str, path: str) -> tuple[bool, str, dict, list]:
    lang = lang_from_path(path)
    ast_env = run_bun(os.path.join(JAC_DIR, "parser_bridge.mjs"), {
        "protocolVersion": 1,
        "language": lang,
        "source": source,
    })
    if not ast_env.get("ok"):
        return False, "", ast_env, ast_env.get("diagnostics", [])

    conv = run_bun(os.path.join(JAC_DIR, "convert_bridge.mjs"), {
        "protocolVersion": 1,
        "ast": ast_env["ast"],
        "path": path,
    })
    if not conv.get("ok"):
        return False, "", conv, conv.get("diagnostics", [])
    return True, conv["jac"], conv, []


def jac_check(jac: str) -> tuple[bool, str]:
    with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False, encoding="utf-8") as tf:
        tf.write(jac)
        tmp_path = tf.name
    try:
        proc = subprocess.run(
            ["jac", "check", tmp_path],
            cwd=JAC_REPO,
            capture_output=True,
            text=True,
        )
    finally:
        os.unlink(tmp_path)
    out = proc.stdout + proc.stderr
    ok = proc.returncode == 0 and "FAILED" not in out
    return ok, out


def validate_corpus(pilot_dir: str, manifest_path: str, fail_fast: bool) -> int:
    with open(manifest_path, encoding="utf-8") as fh:
        manifest = json.load(fh)

    passed = 0
    failed = 0
    for rec in manifest["records"]:
        rel = rec["source"]["path"]
        src_path = os.path.join(pilot_dir, rel)
        with open(src_path, encoding="utf-8") as fh:
            source = fh.read()

        ok, jac, conv_env, diags = convert_source(source, rel)
        if not ok:
            failed += 1
            print(f"FAIL convert {rel}:")
            for d in diags:
                print(f"  {d.get('code')}: {d.get('message')}")
            if fail_fast:
                return 1
            continue

        check_ok, check_out = jac_check(jac)
        if not check_ok:
            failed += 1
            print(f"FAIL jac check {rel}:")
            for ln in check_out.splitlines():
                if "Error" in ln or "error[" in ln or "FAILED" in ln:
                    print(f"  {ln.strip()}")
            if fail_fast:
                return 1
            continue

        rec["jac_sha256"] = _sha256(jac)
        rec["conversion"] = {
            "rule_set_version": RULE_SET_VERSION,
            "parser_protocol_version": 1,
            "ok": True,
            "summary": conv_env.get("summary", {}),
            "validation_stages": [
                {"stage": "convert", "status": "passed"},
                {"stage": "check", "status": "passed"},
            ],
        }
        passed += 1
        print(f"PASS {rel} ({rec['family']})")

    manifest["validated_count"] = passed
    manifest["failed_count"] = failed
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2, sort_keys=True)
        fh.write("\n")

    print(f"\n=== {passed}/{passed + failed} passed ===")
    return 0 if failed == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate js2jac pilot corpus")
    parser.add_argument("--pilot-dir", default=DEFAULT_PILOT)
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--fail-fast", action="store_true")
    args = parser.parse_args()
    return validate_corpus(args.pilot_dir, args.manifest, args.fail_fast)


if __name__ == "__main__":
    sys.exit(main())
