"""GENERATE section (workspace 02 RL/GRPO) — deployable best-of-k Jac codegen.

Samples k completions from the SFT model and returns the first that compiles+runs
(rl_generate → model-experiments/02-rl-grpo/rl/generate.py). The jac compiler is the verifier; on the
holdout this reaches ~78% vs ~55% greedy. Loads a 30B model per call (~1–2 min).
"""

sv import from ...rl { rl_generate }
import from ..shared.Button { Button }

def:pub Generate -> JsxElement {
    has genPrompt: str = "Write a Jac function `add(a: int, b: int) -> int` that returns their sum.",
        genJac: str = "",
        genNote: str = "",
        genBusy: bool = False,
        startedAt: float = 0.0,
        elapsed: int = 0,
        tickId: any = None;

    # rl_generate is a blocking RPC with no cancel endpoint — all we can do
    # honestly is count elapsed seconds while it holds the connection.
    async def doGen() -> None {
        if genBusy { return; }
        win: any = window;
        t0: float = float(str(win.Date.now()));
        startedAt = t0;
        elapsed = 0;
        genBusy = True; genJac = ""; genNote = "";
        # capture t0/win locally: the interval lambda must not read stale state
        iv: any = setInterval(lambda -> None {
            elapsed = int((float(str(win.Date.now())) - t0) / 1000);
        }, 1000);
        tickId = iv;
        try {
            r = await rl_generate(genPrompt, 8);
            if ("ok" in r) and (not bool(r["ok"])) {
                # backend busy-rejection: {"ok": False, "note": "busy: ..."}
                genNote = "⚠ " + str(r["note"]);
            } else {
                genJac = str(r["jac"] or "");
                genNote = ("✓ " + str(r["note"])) if bool(r["verified"]) else ("⚠ " + str(r["note"]));
            }
        } except Exception {
            genNote = "⚠ generate failed — server unreachable or errored";
        }
        genBusy = False;
        clearInterval(float(str(iv)));
        tickId = None;
    }

    can with exit {
        if tickId { clearInterval(float(str(tickId))); }
    }

    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
            <span className="micro-label">TRAIN · RL (GRPO ran offline) · deployed artifact: best-of-k + compiler verifier (~78%)</span>
            <span className="micro-label text-muted-foreground/70">{"sampling…" if genBusy else ""}</span>
        </div>

        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-4">
            <div className="relative rounded-md border border-border bg-card p-3 pt-4">
                <span className="micro-label absolute -top-2 left-3 bg-background px-2">PROMPT</span>
                <textarea
                    className="w-full resize-y rounded-sm border border-input bg-background p-2 font-mono text-xs text-foreground outline-none placeholder:text-muted-foreground/70 focus:border-ring"
                    rows={4} value={genPrompt} onChange={lambda e: ChangeEvent { genPrompt = str(e.target.value); }}
                    placeholder="Describe the Jac function to generate…" />
                <div className="mt-2 flex items-center gap-3">
                    <Button variant="solid" disabled={genBusy} onClick={lambda e: MouseEvent { doGen(); }}>
                        {"generating…" if genBusy else "▷ generate (sample 8, keep the one that compiles+runs)"}
                    </Button>
                    {genBusy and <span key="gen-elapsed" className="stat-line text-muted-foreground">{f"GENERATING · {elapsed}s · loads 30B model, 1-2 min typical"}</span>}
                    {(not genBusy and genNote != "") and <span key="gen-note" className="stat-line text-muted-foreground">{genNote}</span>}
                </div>
                {(<pre className="mt-3 overflow-x-auto rounded-sm border border-border bg-background p-3 font-mono text-xs text-foreground">{genJac}</pre>) if genJac else <span></span>}
                <div className="stat-line mt-2 text-muted-foreground/70">the jac compiler is the verifier — returns the first of 8 samples that compiles+runs. On the holdout this reaches ~78% vs ~55% greedy. Loads the SFT model per call (~1–2 min).</div>
            </div>
        </div>
    </div>;
}
