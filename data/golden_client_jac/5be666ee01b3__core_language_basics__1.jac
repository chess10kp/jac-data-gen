"""studio - single resident MLX model + token stream.

Ports server/model_manager.py + server/generate.py. 48GB box: exactly one model
in memory. Swap = drop refs + gc + mx.clear_cache(), then mlx_lm.load() the new
one. mlx imports are lazy (inside bodies) so server boot stays mlx-free until the
first load. Module globals hold the resident model; a threading.Lock serializes
load+generation so a concurrent request can never swap the model mid-request
(matches the old single-lock-across-request design in app.py).

Checker notes (jaclang 0.16.1): native mlx submodules are `Unknown`, so import the
symbols directly and keep handles in `any` locals. `with _lock {}` rejects an
`any` context manager → acquire/release explicitly. `round(x, 1)` has no resolvable
overload and ANY `any`-typed local poisons arithmetic in the same function, so
elapsed time is computed in helpers with no `any` locals and rounded client-side.
"""

import gc;
import time;
import threading;
import resource;
import from uuid { uuid4 }

glob _model: any = None;
glob _tokenizer: any = None;
glob _current_id: str = "";
glob _load_seconds: float = 0.0;
glob _lock: any = threading.Lock();
# Generation cancel channel: stream_chat records its generation id in
# _active_gen; stop_generation (chat.sv.jac) sets _cancel_gen; the token loop
# breaks when they match. Lock-free on purpose — the whole point is to reach a
# generator that is holding _lock.
glob _active_gen: str = "";
glob _cancel_gen: str = "";

def request_cancel(gen_id: str = "") -> str {
    global _cancel_gen;
    target = gen_id if gen_id else _active_gen;
    _cancel_gen = target;
    return target;
}

def _now() -> float { return time.monotonic(); }

def _elapsed(t0: float) -> float { return time.monotonic() - t0; }

def _unload_locked() {
    global _model, _tokenizer, _current_id;
    _model = None;
    _tokenizer = None;
    _current_id = "";
    gc.collect();
    try {
        import from mlx.core { clear_cache }
        clear_cache();
    } except Exception {}
}

"""Blocking load. Returns seconds spent (0.0 if already resident). Unloads any
prior model first — only one fits in 48GB. Used by the standalone warm path."""
def load_sync(model_id: str, path: str) -> float {
    global _model, _tokenizer, _current_id, _load_seconds;
    _lock.acquire();
    try {
        if _current_id == model_id {
            _load_seconds = 0.0;
            return 0.0;
        }
        if _current_id {
            _unload_locked();
        }
        import from mlx_lm { load }
        t0 = _now();
        loaded: any = load(path);
        _model = loaded[0];
        _tokenizer = loaded[1];
        _load_seconds = _elapsed(t0);
        _current_id = model_id;
        return _load_seconds;
    } finally {
        _lock.release();
    }
}

def current_id() -> str { return _current_id; }

"""Currently-resident model id + a ROUGH resident memory estimate in GB.

There is no cheap, exact "bytes this model occupies" probe, so we approximate
with the process peak RSS (ru_maxrss) — on a single-resident-model box that is
dominated by the loaded weights. Bytes on macOS, hundredths-of-GB via int div
(round(x,2) is broken in the checker). Returns 0.0 when nothing is loaded."""
def loaded_info() -> dict {
    if not _current_id {
        return {"id": "", "resident_gb": 0.0};
    }
    ru: any = resource.getrusage(resource.RUSAGE_SELF);
    rss = float(str(ru.ru_maxrss));  # bytes on macOS; would be KB on Linux
    return {"id": _current_id, "resident_gb": int(rss / 10_000_000.0) / 100.0};
}

def _build_prompt(messages: list[dict]) -> any {
    return _tokenizer.apply_chat_template(messages, add_generation_prompt=True);
}

"""Stream a chat completion: loads the requested model if needed, then yields one
frame per token, holding `_lock` across the WHOLE load+generate so a concurrent
request can't swap the resident model mid-stream. Any failure surfaces as an
`{kind:"error"}` frame instead of crashing the generator.

Frames: {kind:"load",load_s,model_id} once, {kind:"token",token,text} per token,
{kind:"done",text,tokens,tps,load_s,gen_s} last, {kind:"error",text} on failure."""
def stream_chat(
    messages: list[dict], model_id: str, path: str,
    temperature: float, top_p: float, max_tokens: int
) -> any {
    global _model, _tokenizer, _current_id, _load_seconds, _active_gen, _cancel_gen;
    _lock.acquire();
    gid = str(uuid4().hex)[:8];
    _active_gen = gid;
    try {
        import from mlx_lm { load, stream_generate }
        import from mlx_lm.sample_utils { make_sampler }
        load_s = 0.0;
        if _current_id != model_id {
            if _current_id { _unload_locked(); }
            t0 = _now();
            loaded: any = load(path);
            _model = loaded[0];
            _tokenizer = loaded[1];
            load_s = _elapsed(t0);
            _current_id = model_id;
            _load_seconds = load_s;
        }
        yield {"kind": "load", "load_s": load_s, "model_id": model_id, "gen_id": gid};
        sampler = make_sampler(temp=temperature, top_p=top_p);
        ptoks = _build_prompt(messages);
        gt0 = _now();
        # Hoist the native generator into a local before iterating — a yield over
        # an inline native call crashes the type checker (jaclang 0.16.1).
        gen: any = stream_generate(
            _model, _tokenizer, ptoks, max_tokens=max_tokens, sampler=sampler
        );
        acc = "";
        ntok: any = 0;
        ntps: any = 0.0;
        for resp in gen {
            if _cancel_gen == gid { break; }
            # Extract native attrs into locals before yielding (checker crash).
            txt: str = str(resp.text);
            ntok = resp.generation_tokens;
            ntps = resp.generation_tps;
            acc += txt;
            yield {"kind": "token", "token": txt, "text": acc};
        }
        yield {
            "kind": "done", "text": acc, "tokens": ntok, "tps": ntps,
            "load_s": load_s, "gen_s": _elapsed(gt0)
        };
    } except Exception as e {
        yield {"kind": "error", "text": str(e)};
    } finally {
        if _cancel_gen == gid { _cancel_gen = ""; }
        if _active_gen == gid { _active_gen = ""; }
        _lock.release();
    }
}
