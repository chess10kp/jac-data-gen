#!/usr/bin/env python3
"""Generate the frontend eval suite apps via an OpenAI-compatible API.

Reads evals/frontend/v1/specs.json (one spec = paragraph + assertions, per
docs/frontend_app_evals.md), calls the model once per spec, and writes:

  evals/frontend/v1/preds/<model_tag>/<id>/index.html   extracted HTML
  evals/frontend/v1/preds/<model_tag>/<id>/raw.txt      raw model output
  evals/frontend/v1/preds/<model_tag>/manifest.jsonl    per-app status

Defaults to Featherless + ornith-ai/Ornith-1.5-9B; env-overridable.
"""
from __future__ import annotations
import argparse, json, os, random, re, sys, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib import request, error

REPO = Path(__file__).resolve().parents[2]
SPECS = REPO / "evals" / "frontend" / "v1" / "specs.json"

PROMPT = """You are generating a benchmark app. Output ONLY a single self-contained HTML file — no markdown fences, no explanation, no commentary.

Requirements:
- Everything inline: CSS in <style>, JS in <script>. No external scripts, styles, fonts, images, or network calls. No frameworks, no CDN.
- Start the file with <!DOCTYPE html>. Put the app UI inside <body>.
- Implement ALL the behavior below; every button must work. Clean, presentable styling.

APP SPEC:
{spec}

Behavioral assertions the app will be tested against:
{assertions}

Write the complete HTML file now."""


def load_key() -> str:
    key = os.environ.get("FEATHERLESS_API_KEY")
    if key:
        return key
    secrets = Path.home() / ".secrets"
    for line in secrets.read_text().splitlines():
        m = re.match(r"\s*FEATHERLESS_API_KEY\s*=\s*['\"]?([^'\"\s]+)", line)
        if m:
            return m.group(1)
    sys.exit("FEATHERLESS_API_KEY not found in env or ~/.secrets")


def chat(base: str, key: str, model: str, prompt: str, max_tokens: int, temperature: float, timeout: int) -> tuple[str, str, dict]:
    """Return (content, reasoning, usage)."""
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    req = request.Request(
        base.rstrip("/") + "/chat/completions",
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
        },
    )
    with request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read())
    msg = data["choices"][0]["message"]
    return msg.get("content") or "", msg.get("reasoning") or "", data.get("usage") or {}


def extract_html(text: str) -> str:
    """Pull a standalone HTML doc out of model output (handles fences/preamble)."""
    fence = re.findall(r"```(?:html)?\s*\n(.*?)```", text, re.S)
    if fence:
        text = max(fence, key=len)
    m = re.search(r"<!DOCTYPE html[\s\S]*?</html>", text, re.I)
    if m:
        return m.group(0)
    m = re.search(r"<html[\s\S]*?</html>", text, re.I)
    if m:
        return m.group(0)
    return ""


def gen_one(spec: dict, args, key: str) -> dict:
    outdir = Path(args.outdir) / spec["id"]
    outdir.mkdir(parents=True, exist_ok=True)
    html_path, raw_path = outdir / "index.html", outdir / "raw.txt"
    if html_path.exists() and not args.force:
        return {"id": spec["id"], "status": "cached"}

    assertions = "\n".join(f"- {a}" for a in spec["assertions"])
    prompt = PROMPT.format(spec=spec["spec"], assertions=assertions)

    last_err = ""
    for attempt in range(args.retries + 1):
        try:
            content, reasoning, usage = chat(
                args.base_url, key, args.model, prompt,
                args.max_tokens, args.temperature, args.timeout,
            )
            raw = content or reasoning
            html = extract_html(raw)
            if not html:
                # retry once with the reasoning+content concatenated (base
                # models sometimes dump the file into the reasoning field)
                html = extract_html(reasoning + "\n" + content)
            raw_path.write_text(raw)
            if html:
                html_path.write_text(html + "\n")
                return {"id": spec["id"], "status": "ok", "bytes": len(html),
                        "tokens": usage.get("total_tokens")}
            last_err = "no_html_extracted"
            raw_path.write_text(raw)
        except error.HTTPError as e:
            last_err = f"http_{e.code}: {e.read()[:200].decode('utf-8', 'replace')}"
        except Exception as e:  # noqa: BLE001
            last_err = f"{type(e).__name__}: {e}"
        time.sleep(min(2 ** attempt * 2 + random.random() * 3, 60))
    return {"id": spec["id"], "status": "fail", "error": last_err}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default=os.environ.get("MODEL", "ornith-ai/Ornith-1.5-9B"))
    ap.add_argument("--base-url", default=os.environ.get("BASE_URL", "https://api.featherless.ai/v1"))
    ap.add_argument("--outdir", default="")
    ap.add_argument("--max-tokens", type=int, default=32768)
    ap.add_argument("--temperature", type=float, default=0.2)
    ap.add_argument("--timeout", type=int, default=600)
    ap.add_argument("--retries", type=int, default=2)
    ap.add_argument("--workers", type=int, default=5)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only", nargs="*", default=[], help="spec ids to (re)generate")
    args = ap.parse_args()

    if not args.outdir:
        args.outdir = str(REPO / "evals/frontend/v1/preds" / args.model.replace("/", "__"))

    specs = json.loads(SPECS.read_text())
    if args.only:
        want = set(args.only)
        specs = [s for s in specs if s["id"] in want]
    key = load_key()

    manifest_path = Path(args.outdir) / "manifest.jsonl"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)

    results = []
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(gen_one, s, args, key): s for s in specs}
        for fut in as_completed(futs):
            r = fut.result()
            results.append(r)
            print(f"[{len(results)}/{len(specs)}] {r['id']}: {r['status']}"
                  + (f" ({r.get('bytes')}B, {r.get('tokens')}tok)" if r["status"] == "ok"
                     else f" {r.get('error', '')}"), flush=True)

    results.sort(key=lambda r: [s["id"] for s in json.loads(SPECS.read_text())].index(r["id"]))
    # merge with existing manifest entries for ids we didn't touch
    old = {}
    if manifest_path.exists():
        for line in manifest_path.read_text().splitlines():
            if line.strip():
                rec = json.loads(line)
                old[rec["id"]] = rec
    for r in results:
        old[r["id"]] = {**r, "model": args.model, "ts": int(t0)}
    manifest_path.write_text("\n".join(json.dumps(v) for v in old.values()) + "\n")

    ok = sum(1 for v in old.values() if v["status"] in ("ok", "cached"))
    print(f"done: {ok}/{len(old)} generated in {time.time()-t0:.0f}s -> {args.outdir}")
    if any(v["status"] == "fail" for v in old.values()):
        sys.exit(1)


if __name__ == "__main__":
    main()
