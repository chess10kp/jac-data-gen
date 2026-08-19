"""PLAN section — per-workspace roadmap (every workspace has the same five
sections; PLAN shows that attempt's phases + checklist). Static render, status
hardcoded to on-disk reality; the named docs are the source of truth."""

import from ..shared.StatusGlyph { StatusGlyph }

glob TITLES: dict = {
    "01": "PLAN · SFT → DPO → BAKE-OFF",
    "02": "PLAN · RL / GRPO LADDER",
    "03": "PLAN · CPT → SFT/DPO → GRPO"
};
glob SOURCES: dict = {
    "01": "model-experiments/01-sft-dpo/ results + bake-off docs",
    "02": "model-experiments/02-rl-grpo/ RL_FINDINGS.md + ladder design",
    "03": "model-experiments/03-new/docs/cpt-1/workflow.md"
};

glob WS_PHASES: dict = {
    "01": [
        {"id": "P1", "status": "done", "title": "Seed conversion dataset", "note": "DONE — hand-authored + generated py→jac pairs; 13-stage build pipeline (DATA section) with manifest/splits/holdouts."},
        {"id": "P2", "status": "done", "title": "SFT probe · qwen + gemma", "note": "DONE — LoRA SFT on Qwen3-Coder-30B-A3B and Gemma; resumable run_probe.sh; live curves in TRAIN."},
        {"id": "P3", "status": "done", "title": "DPO pass", "note": "DONE — DPO on top of SFT (run_dpo.sh); fused deploy models qwen-dpo / gemma-dpo."},
        {"id": "P4", "status": "done", "title": "Candidate bake-off", "note": "DONE — incumbent Qwen3-Coder confirmed: no candidate beat it beyond noise; qwen3i closest, gptoss MXFP4-broken, ling dropped."},
        {"id": "P5", "status": "running", "title": "Dataset expansion waves", "note": "IN PROGRESS — graph/OSP-heavy SFT batches landing (receipt-guarded ingest gates); target: semantic coverage, not just syntax."},
        {"id": "P6", "status": "idle", "title": "Retrain @ expanded data", "note": "GATED on expansion waves — rerun SFT/DPO on the enlarged set, re-eval on both holdouts."}
    ],
    "02": [
        {"id": "P1", "status": "done", "title": "RL corpus + 51 drivers", "note": "DONE — hand-authored task drivers with behavioral checks; browsable in DATA."},
        {"id": "P2", "status": "done", "title": "GRPO experiments", "note": "DONE — the core null: LoRA-GRPO can't move greedy (KL≈0, pass@8==pass@1). σ=0 zero-advantage trap + splice bug found and fixed along the way."},
        {"id": "P3", "status": "done", "title": "Corrected eval ladder", "note": "DONE — measurement bug fixed: SFT lifts greedy 39%→61%; RESULTS renders the corrected ladder + holdouts."},
        {"id": "P4", "status": "done", "title": "Best-of-k + verifier deploy", "note": "DONE — best-of-k with the jac compiler as picker ≈78% vs 55% greedy; live demo in TRAIN (loads 30B per call)."},
        {"id": "P5", "status": "idle", "title": "SFT-first ladder · GRPO 2nd pass", "note": "LOCKED NEXT — redesigned ladder: SFT moves models, so ladder SFT first, then GRPO second pass; two models."}
    ],
    "03": [
        {"id": "P0", "status": "idle", "title": "Base eval (checkpoint 0)", "note": "unmodified Qwen3-Coder-30B-A3B through both eval tracks — the floor every checkpoint is read against."},
        {"id": "P1", "status": "done", "title": "CPT data build", "note": "DONE — 3.84M tokens, 939 windows (790/149). 5 sources: docs, code, rehearsal, blogs, osp_paper. Decontam clean, manifest emitted."},
        {"id": "P2", "status": "done", "title": "CPT training", "note": "DONE (2026-07-14) — 2586/2586 iters, 6.82h. Train loss -18.5%, val loss -24.4%, moving together (no overfit signal). Fused: models/qwen-cpt-v1-fused-q4. CF regression PASS."},
        {"id": "C1", "status": "done", "title": "Checkpoint 1 · +CPT eval", "note": "DONE (2026-07-14) — NULL RESULT. 20-question semantic MCQ: 18/20 both models, identical answers. CPT-v1 NOT accepted — see analysis.md."},
        {"id": "P3", "status": "done", "title": "CPT-v2 · curated corpus, 12 legs", "note": "12/12 legs complete (6528 iters, optimizer-state resume). Status + curves in TRAIN; compare in RESULTS."},
        {"id": "P4", "status": "idle", "title": "SFT/DPO (redesigned data)", "note": "GATED — spec not yet written. Reuse 01 recipe; redesign DPO pairs toward semantic-vs-subtly-wrong OSP idiom."},
        {"id": "C2", "status": "idle", "title": "Checkpoint 2 · +CPT+SFT/DPO eval", "note": "Full track: semantic MCQ + online-judge (compiler/pass@k) + human trust check."},
        {"id": "P6", "status": "idle", "title": "RL/GRPO (redesigned corpus+reward)", "note": "GATED — spec not yet written. Multi-project source diversity + Type-B AST/partial-credit grading."},
        {"id": "P8", "status": "idle", "title": "Read the ablation", "note": "4-point delta table (base / +CPT / +CPT+SFT-DPO / +…+GRPO). Did CPT move the semantic ceiling?"}
    ]
};

glob WS_CHECKLIST: dict = {
    "01": [
        {"done": True, "t": "Seed + generated conversion data built, splits emitted"},
        {"done": True, "t": "SFT probes complete (qwen 600 it, gemma 600 it)"},
        {"done": True, "t": "DPO runs complete, fused deploy models produced"},
        {"done": True, "t": "Bake-off read: incumbent confirmed (>noise bar)"},
        {"done": False, "t": "Expansion waves ingested to target size"},
        {"done": False, "t": "Retrain + re-eval at expanded dataset"}
    ],
    "02": [
        {"done": True, "t": "51 RL task drivers authored + verified"},
        {"done": True, "t": "GRPO null documented (LoRA can't move greedy)"},
        {"done": True, "t": "Eval bug found; corrected ladder published"},
        {"done": True, "t": "best-of-k + compiler verifier shipped (~78%)"},
        {"done": False, "t": "SFT-first ladder spec executed (2 models)"},
        {"done": False, "t": "GRPO second pass on SFT'd models"}
    ],
    "03": [
        {"done": True, "t": "Phase 1 CPT dataset built, manifest emitted, decontam clean"},
        {"done": False, "t": "Phase 0 base eval recorded (both tracks)"},
        {"done": True, "t": "CPT-v1 training complete + CF regression PASS"},
        {"done": True, "t": "Checkpoint 1 MCQ recorded — NULL, checkpoint NOT accepted"},
        {"done": True, "t": "CPT-v2 curated corpus + 12-leg run complete"},
        {"done": False, "t": "SFT/DPO redesign spec written (gates Phase 4)"},
        {"done": False, "t": "Checkpoint 2 full eval recorded"},
        {"done": False, "t": "GRPO redesign spec + run + Checkpoint 3"},
        {"done": False, "t": "Ablation table built, hypothesis confirmed/killed"}
    ]
};

def:pub Plan(workspace: str = "03") -> JsxElement {
    phases: list = list(WS_PHASES[workspace]);
    checklist: list = list(WS_CHECKLIST[workspace]);
    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
            <span className="micro-label">{str(TITLES[workspace])}</span>
        </div>
        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-4">
            <div className="relative rounded-md border border-border bg-card p-3 pt-4">
                <span className="micro-label absolute -top-2 left-3 bg-background px-2">PHASES</span>
                <div className="relative flex flex-col gap-0.5 pl-3">
                    <div className="absolute bottom-1 left-0 top-1 w-px bg-border"></div>
                    {for p in phases {
                        <div key={str(p["id"])} className="flex items-start gap-3 rounded px-2 py-1.5">
                            <span className="mt-0.5 shrink-0"><StatusGlyph status={str(p["status"])} showLabel={False} /></span>
                            <span className="shrink-0 font-mono text-xs text-muted-foreground/70" style={{"width": 26}}>{str(p["id"])}</span>
                            <div className="flex flex-col gap-0.5">
                                <span className="font-mono text-xs text-foreground">{str(p["title"])}</span>
                                <span className="stat-line text-muted-foreground">{str(p["note"])}</span>
                            </div>
                        </div>
                    }}
                </div>
            </div>

            <div className="relative rounded-md border border-border bg-card p-3 pt-4">
                <span className="micro-label absolute -top-2 left-3 bg-background px-2">CHECKLIST</span>
                <div className="flex flex-col gap-1">
                    {for c in checklist {
                        <div key={str(c["t"])} className="flex items-center gap-2 font-mono text-xs">
                            <span className={"shrink-0 " + ("text-foreground" if c["done"] else "text-muted-foreground/70")}>{"✓" if c["done"] else "○"}</span>
                            <span className={"text-foreground/80" if c["done"] else "text-muted-foreground"}>{str(c["t"])}</span>
                        </div>
                    }}
                </div>
                <div className="stat-line mt-3 text-muted-foreground/70">status hardcoded to on-disk reality · source of truth: {str(SOURCES[workspace])}</div>
            </div>
        </div>
    </div>;
}
