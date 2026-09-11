"""Unified LLM backend — one seam for pi / cursor / zen / openrouter.

Goal: any model swaps via --backend pi|cursor|zen|openrouter|auto without
editing prompts or generation logic. Every backend exposes the same call:

    backend.call(system, user, model, timeout, tries) -> (text|None, error|None, usage dict)

Usage is normalized to {inputTokens, outputTokens, cacheReadTokens, ms} so
ledgers (generation_ledger.sqlite + legacy _cost_ledger.jsonl) stay comparable.
Retry/backoff lives here, not in callers — callers just handle fence extraction
and validation.

Auto routing (when --backend auto):
  pi: / cursor: / zen: / openrouter: prefix forces that backend (prefix stripped)
  luna in model -> pi (backward compat for gpt-5.6-luna)
  *-free / :free -> zen (except minimax/nemotron which go openrouter)
  slash models like minimax/... -> openrouter
  else -> cursor (composer-2.5 etc.)

Callers:
  from llm_backend import get_backend, strip_prefix
  backend = get_backend(args.backend, args.model)
  text, err, usage = backend.call(system, user, model_core, timeout, tries)
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import time
import threading
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

import httpx

# ---------------------------------------------------------------------------
# helpers shared across backends
# ---------------------------------------------------------------------------

CURSOR_WS = os.environ.get("CURSOR_OSP_WS", "/tmp/cursor_osp_ws_empty")
CURSOR_TMP = os.environ.get("CURSOR_OSP_TMP", "/tmp/cursor_osp_tmp")
ISO_HOME = Path(os.environ.get("CURSOR_OSP_ISO_HOME", "/tmp/cursor_iso_home"))
_ISO_READY = False
_ISO_LOCK = threading.Lock()


def _ensure_iso_home() -> None:
    global _ISO_READY
    with _ISO_LOCK:
        if _ISO_READY:
            return
        cfg = ISO_HOME / ".cursor"
        xdg = ISO_HOME / ".config" / "cursor"
        cfg.mkdir(parents=True, exist_ok=True)
        xdg.mkdir(parents=True, exist_ok=True)
        src_cfg = Path.home() / ".cursor"
        for name in ("cli-config.json",):
            p = src_cfg / name
            if p.exists():
                (cfg / name).write_text(p.read_text())
        mcp_src = src_cfg / "mcp.json"
        if mcp_src.exists():
            try:
                m = json.loads(mcp_src.read_text())
                m.get("mcpServers", {}).pop("jac", None)
                (cfg / "mcp.json").write_text(json.dumps(m, indent=2))
            except (ValueError, OSError):
                (cfg / "mcp.json").write_text('{"mcpServers": {}}')
        else:
            (cfg / "mcp.json").write_text('{"mcpServers": {}}')
        auth = Path.home() / ".config" / "cursor" / "auth.json"
        if auth.exists():
            (xdg / "auth.json").write_text(auth.read_text())
        _ISO_READY = True


def strip_prefix(model: str) -> str:
    """Strip pi:/cursor:/zen:/openrouter: prefix for the underlying transport."""
    for p in ("pi:", "cursor:", "zen:", "openrouter:"):
        if model.startswith(p):
            return model[len(p):]
    return model


# ---------------------------------------------------------------------------
# key helpers for zen / openrouter (lifted from idiomize_seam / minimax)
# ---------------------------------------------------------------------------

ZEN_BASE = "https://opencode.ai/zen/v1"
OR_BASE = "https://openrouter.ai/api/v1"

_or_key_idx = 0
_or_key_lock = threading.Lock()


_zen_key_idx = 0
_zen_key_lock = threading.Lock()


def _opencode_keys() -> list[str]:
    keys: list[str] = []
    # env vars (numbered + API variants)
    for env in ("OPENCODE_KEY", "OPENCODE_API_KEY",
                "OPENCODE_KEY_2", "OPENCODE_API_KEY_2",
                "OPENCODE_KEY_3", "OPENCODE_API_KEY_3",
                "OPENCODE_KEY_4", "OPENCODE_API_KEY_4",
                "OPENCODE_KEY_5", "OPENCODE_API_KEY_5"):
        k = os.environ.get(env)
        if k and k.startswith("sk-") and k not in keys:
            keys.append(k)
    # scan secrets + all worker env files (second-worker.env etc.)
    env_files = [Path.home() / ".secrets", Path.home() / ".secrets.env"] + list(Path.home().glob(".*.env"))
    # also explicit worker files without dot? keep for compat
    for p in env_files:
        if not p.exists():
            continue
        try:
            for ln in p.read_text().splitlines():
                m = re.match(r"(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.+)$", ln.strip())
                if not m:
                    continue
                name = m.group(1)
                if not name.startswith("OPENCODE"):
                    continue
                k = m.group(2).strip().strip("'\"")
                if k.startswith("sk-") and k not in keys:
                    keys.append(k)
        except OSError:
            pass
    # auth files — opencode key only
    for p in (Path.home() / ".pi/agent/auth.json",
              Path.home() / ".local/share/opencode/auth.json"):
        if p.exists():
            try:
                d = json.loads(p.read_text())
                if isinstance(d, dict) and d.get("opencode", {}).get("key"):
                    k = d["opencode"]["key"]
                    if k and k.startswith("sk-") and k not in keys:
                        keys.append(k)
            except Exception:
                pass
    if not keys:
        raise RuntimeError("opencode key not found (set OPENCODE_API_KEY or configure pi/opencode auth)")
    return keys


def _opencode_key() -> str:
    return _opencode_keys()[0]


def _or_keys() -> list[str]:
    keys: list[str] = []
    for env in ("OR_KEY", "OPENROUTER_API_KEY", "OPENROUTER_API_KEY_2", "OPENROUTER_API_KEY_3"):
        k = os.environ.get(env)
        if k and k.startswith("sk-") and k not in keys:
            keys.append(k)
    secrets = Path.home() / ".secrets.env"
    if secrets.exists():
        try:
            for ln in secrets.read_text().splitlines():
                m = re.match(r"(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.+)$", ln.strip())
                if not m or m.group(1) not in ("OR_KEY", "OPENROUTER_API_KEY",
                                                "OPENROUTER_API_KEY_2", "OPENROUTER_API_KEY_3"):
                    continue
                k = m.group(2).strip().strip("'\"")
                if k.startswith("sk-") and k not in keys:
                    keys.append(k)
        except OSError:
            pass
    auth = Path.home() / ".pi/agent/auth.json"
    if auth.exists():
        try:
            d = json.loads(auth.read_text())
            k = d.get("openrouter", {}).get("key")
            if k and k not in keys:
                keys.append(k)
        except (ValueError, OSError):
            pass
    if not keys:
        raise RuntimeError("OpenRouter key not found (set OR_KEY/OPENROUTER_API_KEY* or configure ~/.pi/agent/auth.json)")
    return keys


def _or_key() -> str:
    global _or_key_idx
    keys = _or_keys()
    with _or_key_lock:
        k = keys[_or_key_idx % len(keys)]
        _or_key_idx += 1
        return k


# ---------------------------------------------------------------------------
# Backend protocol
# ---------------------------------------------------------------------------

class Backend(Protocol):
    name: str
    def call(self, system: str, user: str, model: str, timeout: int, tries: int = 2
             ) -> tuple[str | None, str | None, dict]:
        """Return (text, error, usage). text is None on failure."""
        ...


# ---------------------------------------------------------------------------
# Pi (codex OAuth via pi -p)
# ---------------------------------------------------------------------------

class PiBackend:
    name = "pi"

    # pi provider per model: muse/zen models ride the opencode provider,
    # everything else (luna etc.) uses openai-codex. OSP_PI_PROVIDER overrides.
    @staticmethod
    def _provider(model: str) -> str:
        env = os.environ.get("OSP_PI_PROVIDER")
        if env:
            return env
        m = model.lower()
        if "muse" in m or m.endswith("-free"):
            return "opencode"
        return "openai-codex"

    def call(self, system: str, user: str, model: str, timeout: int, tries: int = 2
             ) -> tuple[str | None, str | None, dict]:
        last = "not attempted"
        t0 = time.perf_counter()
        provider = self._provider(model)
        for attempt in range(tries):
            try:
                r = subprocess.run(
                    ["pi", "-p", "--provider", provider, "--model", model,
                     "--no-session", "--system-prompt", system, user],
                    capture_output=True, text=True, timeout=timeout)
            except subprocess.TimeoutExpired:
                last = f"pi timeout after {timeout}s"
                time.sleep(2 ** attempt)
                continue
            out = (r.stdout or "").strip()
            if r.returncode == 0 and out:
                ms = int((time.perf_counter() - t0) * 1000)
                # pi text mode exposes no usage counters — char/4 estimate, marked
                usage = {"inputTokens": len(system) // 4 + len(user) // 4,
                         "outputTokens": len(out) // 4,
                         "cacheReadTokens": 0, "ms": ms}
                return out, None, usage
            last = f"pi rc={r.returncode}: {(r.stderr or out)[-300:]}"
            time.sleep(2 ** attempt)
        return None, last, {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0,
                            "ms": int((time.perf_counter() - t0) * 1000)}


# ---------------------------------------------------------------------------
# Cursor (cursor-agent CLI)
# ---------------------------------------------------------------------------

_SEEN_REQ: set[str] = set()

def _scan_cursor_logs_since(since: float) -> list[dict]:
    rows: list[dict] = []
    for log in Path(CURSOR_TMP).rglob("session-*.log"):
        try:
            if log.stat().st_mtime < since - 2:
                continue
            text = log.read_text(errors="ignore")
        except OSError:
            continue
        for line in text.splitlines():
            if "agent_cli.turn.outcome" not in line:
                continue

            def grab(k: str) -> int:
                m = re.search(rf'"{k}":"(\d+)"', line)
                return int(m.group(1)) if m else 0

            def grab_s(k: str) -> str | None:
                m = re.search(rf'"{k}":"([^"]+)"', line)
                return m.group(1) if m else None

            req = grab_s("request_id")
            if req:
                if req in _SEEN_REQ:
                    continue
                _SEEN_REQ.add(req)
            rows.append({"inputTokens": grab("input_tokens"),
                         "outputTokens": grab("output_tokens"),
                         "cacheReadTokens": grab("cache_read_tokens"),
                         "cacheWriteTokens": grab("cache_write_tokens"),
                         "ms": grab("duration_ms"),
                         "conversation_id": grab_s("conversation_id")})
    return rows


class CursorBackend:
    name = "cursor"

    def call(self, system: str, user: str, model: str, timeout: int, tries: int = 2
             ) -> tuple[str | None, str | None, dict]:
        prompt = f"{system}\n\n---\n\n{user}"
        argv = ["cursor-agent", "--print", "--output-format", "json",
                "--mode", "ask", "--trust", "--model", model,
                "--workspace", CURSOR_WS, prompt]
        iso = os.environ.get("CURSOR_OSP_ISO", "1") != "0"
        env = {**os.environ, "TMPDIR": CURSOR_TMP}
        if iso:
            _ensure_iso_home()
            env["HOME"] = str(ISO_HOME)
            env["XDG_CONFIG_HOME"] = str(ISO_HOME / ".config")
        Path(CURSOR_WS).mkdir(parents=True, exist_ok=True)
        Path(CURSOR_TMP).mkdir(parents=True, exist_ok=True)

        last = "not attempted"
        t0 = time.perf_counter()
        for attempt in range(tries):
            try:
                p = subprocess.run(argv, capture_output=True, text=True, timeout=timeout, env=env)
            except subprocess.TimeoutExpired:
                last = f"cursor timeout after {timeout}s"
                time.sleep(2 ** attempt)
                continue
            raw = (p.stdout or "").strip()
            if not raw:
                last = f"cursor empty stdout: {(p.stderr or '')[:200]}"
                time.sleep(2 ** attempt)
                continue
            try:
                d = json.loads(raw)
                text = (d.get("result") or "").strip()
                is_error = bool(d.get("is_error"))
                usage = d.get("usage") or {}
                # normalize usage keys
                norm = {"inputTokens": int(usage.get("inputTokens") or usage.get("input_tokens") or 0),
                        "outputTokens": int(usage.get("outputTokens") or usage.get("output_tokens") or 0),
                        "cacheReadTokens": int(usage.get("cacheReadTokens") or usage.get("cache_read_tokens") or 0),
                        "ms": int((time.perf_counter() - t0) * 1000)}
                # fallback to log scan if json has no counters
                if norm["inputTokens"] == 0 and norm["outputTokens"] == 0:
                    rows = _scan_cursor_logs_since(t0)
                    if rows:
                        r = rows[-1]
                        norm = {"inputTokens": r.get("inputTokens", 0),
                                "outputTokens": r.get("outputTokens", 0),
                                "cacheReadTokens": r.get("cacheReadTokens", 0),
                                "ms": norm["ms"]}
                if is_error or not text:
                    last = f"cursor is_error: {str(d.get('error'))[:200] or text[:200]}"
                    time.sleep(2 ** attempt)
                    continue
                return text, None, norm
            except json.JSONDecodeError:
                # raw stdout without json wrapper — treat as text
                if raw:
                    ms = int((time.perf_counter() - t0) * 1000)
                    return raw, None, {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0, "ms": ms}
                last = f"cursor parse_error: {raw[:200]}"
                time.sleep(2 ** attempt)
                continue
        return None, last, {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0,
                            "ms": int((time.perf_counter() - t0) * 1000)}


# ---------------------------------------------------------------------------
# Zen (opencode free gateway)
# ---------------------------------------------------------------------------

class ZenBackend:
    name = "zen"

    def call(self, system: str, user: str, model: str, timeout: int, tries: int = 3
             ) -> tuple[str | None, str | None, dict]:
        try:
            keys = _opencode_keys()
        except Exception as e:
            return None, f"zen auth: {e}", {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0, "ms": 0}
        body = {"model": model, "max_tokens": 16384,
                "messages": [{"role": "system", "content": system},
                             {"role": "user", "content": user}]}
        last = "not attempted"
        # round-robin start so parallel shards spread across keys
        global _zen_key_idx
        with _zen_key_lock:
            start_idx = _zen_key_idx % len(keys)
            _zen_key_idx += 1
        t0 = time.perf_counter()
        session_id = uuid.uuid4().hex  # zen free models (nemotron/mimo) require x-session-id
        for attempt in range(tries):
            key = keys[(start_idx + attempt) % len(keys)]
            headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json",
                       "x-session-id": session_id}
            try:
                r = httpx.post(f"{ZEN_BASE}/chat/completions", headers=headers, json=body, timeout=timeout)
                if r.status_code in (429, 500, 502, 503, 504):
                    last = f"zen {r.status_code}: {r.text[:120]}"
                    time.sleep(2 ** attempt)
                    continue
                if r.status_code in (401, 402, 403):
                    last = f"zen {r.status_code}: {r.text[:120]}"
                    time.sleep(1 * (attempt + 1))
                    continue
                if 400 <= r.status_code < 500:
                    return None, f"zen client {r.status_code}: {r.text[:200]}", {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0, "ms": 0}
                r.raise_for_status()
                p = r.json()
                choice = (p.get("choices") or [{}])[0]
                content = (choice.get("message") or {}).get("content") or ""
                finish = choice.get("finish_reason")
                if not content.strip() or finish in (None, "error"):
                    last = "zen empty/cut stream"
                    if attempt == tries - 1:
                        break
                    time.sleep(1.5 * (attempt + 1))
                    continue
                u = p.get("usage") or {}
                usage = {"inputTokens": int(u.get("prompt_tokens") or 0),
                         "outputTokens": int(u.get("completion_tokens") or 0),
                         "cacheReadTokens": 0,
                         "ms": int((time.perf_counter() - t0) * 1000)}
                return content, None, usage
            except Exception as e:
                last = f"zen {type(e).__name__}: {str(e)[:160]}"
                if attempt == tries - 1:
                    break
                time.sleep(1.5 * (attempt + 1))
        return None, last, {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0,
                            "ms": int((time.perf_counter() - t0) * 1000)}


# ---------------------------------------------------------------------------
# OpenRouter
# ---------------------------------------------------------------------------

class OpenRouterBackend:
    name = "openrouter"

    def call(self, system: str, user: str, model: str, timeout: int, tries: int = 3
             ) -> tuple[str | None, str | None, dict]:
        try:
            keys = _or_keys()
        except Exception as e:
            return None, str(e), {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0, "ms": 0}
        body = {"model": model, "max_tokens": 2048,
                "messages": [{"role": "system", "content": system},
                             {"role": "user", "content": user}]}
        last: str | None = None
        # claim starting key round-robin so parallel shards spread
        global _or_key_idx
        with _or_key_lock:
            start_idx = _or_key_idx % len(keys)
            _or_key_idx += 1
        t0 = time.perf_counter()
        for attempt in range(tries):
            k = keys[(start_idx + attempt) % len(keys)]
            headers = {"Authorization": f"Bearer {k}", "Content-Type": "application/json"}
            try:
                r = httpx.post(f"{OR_BASE}/chat/completions", headers=headers, json=body, timeout=timeout)
            except (httpx.TimeoutException, httpx.HTTPError) as e:
                last = f"or transport {type(e).__name__}: {e}"
                time.sleep(2 ** attempt)
                continue
            if r.status_code in (429, 500, 502, 503, 504):
                last = f"or http {r.status_code}: {r.text[:120]}"
                time.sleep(2 ** attempt)
                continue
            if r.status_code in (401, 402, 403):
                last = f"or http {r.status_code}: {r.text[:120]}"
                continue
            if 400 <= r.status_code < 500:
                return None, f"or http {r.status_code}: {r.text[:200]}", {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0, "ms": 0}
            r.raise_for_status()
            payload = r.json()
            try:
                content = payload["choices"][0]["message"]["content"] or ""
            except (KeyError, IndexError, TypeError) as e:
                return None, f"or malformed payload: {e}", {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0, "ms": 0}
            if not content.strip():
                last = "or empty content"
                time.sleep(2 ** attempt)
                continue
            u = payload.get("usage") or {}
            usage = {"inputTokens": int(u.get("prompt_tokens") or 0),
                     "outputTokens": int(u.get("completion_tokens") or 0),
                     "cacheReadTokens": 0,
                     "ms": int((time.perf_counter() - t0) * 1000)}
            return content, None, usage
        return None, last or "exhausted retries", {"inputTokens": 0, "outputTokens": 0, "cacheReadTokens": 0,
                                                   "ms": int((time.perf_counter() - t0) * 1000)}


# ---------------------------------------------------------------------------
# factory
# ---------------------------------------------------------------------------

_BACKENDS: dict[str, type[Backend]] = {
    "pi": PiBackend, "cursor": CursorBackend, "zen": ZenBackend, "openrouter": OpenRouterBackend,
}

def get_backend(backend: str, model: str) -> Backend:
    """Resolve a backend instance. backend is pi|cursor|zen|openrouter|auto."""
    b = (backend or "auto").lower().strip()
    # explicit prefix always wins — pi:foo -> PiBackend regardless of auto logic
    if model.startswith("pi:"):
        return PiBackend()
    if model.startswith("cursor:"):
        return CursorBackend()
    if model.startswith("zen:"):
        return ZenBackend()
    if model.startswith("openrouter:"):
        return OpenRouterBackend()
    if b != "auto":
        if b not in _BACKENDS:
            raise ValueError(f"unknown backend {b!r} (pi|cursor|zen|openrouter|auto)")
        return _BACKENDS[b]()
    # auto
    m = model.lower()
    if "luna" in m or "muse" in m:
        return PiBackend()
    if m.endswith("-free") or m.endswith(":free"):
        if "minimax" in m or "nemotron" in m:
            return OpenRouterBackend()
        return ZenBackend()
    if "/" in model and not model.startswith("composer"):
        # openrouter-style model ids contain a slash
        return OpenRouterBackend()
    return CursorBackend()
