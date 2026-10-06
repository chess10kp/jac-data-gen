import from traceforge.api {
    AnalyzeBatch,
    CompareBaseline,
    CompileMemoryPatch,
    DiagnoseCluster,
    DiagnoseRun,
    ExportBlindedEvaluation,
    ExportBatchReport,
    GetBatchCatalog,
    GetBatchOverview,
    GetClusterView,
    GetProviderStatus,
    GetRunView,
    RunRigorousEvaluation,
    SaveProviderConfig,
    UploadBatch
}
import from "@jac/runtime" { jacIsLoggedIn, jacLogin, jacSignup }

def ui_styles() -> str {
    return """
@import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@500;700&display=swap');

:root {
--tf-bg: #0c0b0a;
--tf-surface: rgba(18, 17, 16, 0.92);
--tf-surface-soft: rgba(255, 255, 255, 0.03);
--tf-line: rgba(255, 255, 255, 0.08);
--tf-line-strong: rgba(232, 125, 86, 0.22);
--tf-text: #f5efe8;
--tf-muted: #b6aca2;
--tf-dim: #847d76;
--tf-accent: #e87d56;
--tf-accent-soft: #f2c09d;
--tf-cool: #92c9c5;
--tf-shadow: 0 18px 48px rgba(0, 0, 0, 0.24);
--tf-radius-xl: 28px;
--tf-radius-lg: 22px;
--tf-radius-md: 16px;
--tf-radius-sm: 12px;
}

* {
box-sizing: border-box;
}

html, body {
margin: 0;
min-height: 100%;
background:
    radial-gradient(circle at top, rgba(232, 125, 86, 0.06), transparent 24%),
    linear-gradient(180deg, #12100f 0%, #0c0b0a 100%);
color: var(--tf-text);
font-family: 'IBM Plex Sans', sans-serif;
}

body {
-webkit-font-smoothing: antialiased;
text-rendering: optimizeLegibility;
}

button,
input,
select,
textarea {
font: inherit;
}

pre {
margin: 0;
white-space: pre-wrap;
word-break: break-word;
font-family: 'IBM Plex Mono', monospace;
font-size: 0.82rem;
line-height: 1.6;
}

summary {
cursor: pointer;
font-weight: 600;
color: var(--tf-text);
}

.tf-shell {
width: min(1180px, calc(100vw - 40px));
margin: 0 auto;
padding: 28px 0 80px;
}

.tf-loading {
min-height: calc(100vh - 80px);
display: grid;
place-items: center;
}

.tf-card {
background: linear-gradient(180deg, rgba(24, 22, 20, 0.96) 0%, rgba(18, 17, 16, 0.98) 100%);
border: 1px solid var(--tf-line);
border-radius: var(--tf-radius-lg);
box-shadow: var(--tf-shadow);
}

.tf-hero {
margin-bottom: 18px;
}

.tf-hero-main,
.tf-panel,
.tf-sidebar-card,
.tf-stepper,
.tf-stat {
background: linear-gradient(180deg, rgba(24, 22, 20, 0.96) 0%, rgba(18, 17, 16, 0.98) 100%);
border: 1px solid var(--tf-line);
box-shadow: var(--tf-shadow);
}

.tf-hero-main,
.tf-panel,
.tf-sidebar-card {
border-radius: var(--tf-radius-xl);
}

.tf-hero-main {
padding: 32px;
}

.tf-kicker {
display: inline-flex;
align-items: center;
gap: 8px;
color: var(--tf-muted);
font-size: 0.76rem;
letter-spacing: 0.12em;
text-transform: uppercase;
}

.tf-kicker::before {
content: "";
width: 7px;
height: 7px;
border-radius: 999px;
background: var(--tf-accent);
}

.tf-brand {
margin: 12px 0 10px;
font-family: 'Space Grotesk', sans-serif;
font-size: clamp(3.1rem, 8vw, 5rem);
line-height: 0.94;
letter-spacing: -0.05em;
}

.tf-tagline {
margin: 0 0 16px;
color: var(--tf-accent-soft);
font-size: 0.86rem;
letter-spacing: 0.11em;
text-transform: uppercase;
}

.tf-lead {
max-width: 60ch;
margin: 0;
color: var(--tf-muted);
line-height: 1.75;
font-size: 1rem;
}

.tf-context-row {
display: flex;
flex-wrap: wrap;
gap: 10px;
margin-top: 20px;
}

.tf-chip {
display: inline-flex;
align-items: center;
gap: 8px;
min-width: 0;
max-width: 100%;
padding: 8px 12px;
border-radius: 999px;
border: 1px solid var(--tf-line);
background: rgba(255, 255, 255, 0.03);
color: var(--tf-muted);
font-size: 0.82rem;
overflow: hidden;
text-overflow: ellipsis;
white-space: nowrap;
}

.tf-chip strong {
color: var(--tf-text);
}

.tf-status-block {
padding: 14px 16px;
border-radius: var(--tf-radius-md);
background: rgba(255, 255, 255, 0.03);
border: 1px solid var(--tf-line);
}

.tf-hero-strip {
display: grid;
grid-template-columns: minmax(0, 1.8fr) repeat(2, minmax(0, 0.7fr));
gap: 12px;
margin-top: 22px;
padding-top: 20px;
border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.tf-ministat {
min-width: 0;
padding: 14px 16px;
border-radius: var(--tf-radius-md);
background: rgba(255, 255, 255, 0.03);
border: 1px solid var(--tf-line);
}

.tf-ministat strong {
display: block;
margin-top: 2px;
font-family: 'Space Grotesk', sans-serif;
font-size: 1.35rem;
letter-spacing: -0.03em;
}

.tf-label {
display: block;
margin-bottom: 6px;
color: var(--tf-dim);
font-size: 0.72rem;
letter-spacing: 0.11em;
text-transform: uppercase;
}

.tf-status-copy,
.tf-body {
color: var(--tf-muted);
line-height: 1.65;
overflow-wrap: anywhere;
}

.tf-stat strong {
display: block;
margin-bottom: 4px;
font-family: 'Space Grotesk', sans-serif;
font-size: 1.5rem;
letter-spacing: -0.03em;
}

.tf-stat span {
color: var(--tf-muted);
line-height: 1.45;
font-size: 0.88rem;
}

.tf-stepper {
display: grid;
grid-template-columns: repeat(4, minmax(0, 1fr));
gap: 6px;
padding: 8px;
border-radius: 16px;
margin-bottom: 18px;
}

.tf-step {
width: 100%;
text-align: left;
padding: 12px 14px;
border: 1px solid transparent;
border-radius: 14px;
background: transparent;
color: var(--tf-muted);
cursor: pointer;
transition: background 140ms ease, border-color 140ms ease, transform 140ms ease;
}

.tf-step:hover {
transform: translateY(-1px);
border-color: var(--tf-line);
}

.tf-step.is-active {
background: rgba(232, 125, 86, 0.10);
border-color: rgba(232, 125, 86, 0.24);
color: var(--tf-text);
}

.tf-step strong {
display: block;
margin-bottom: 2px;
font-size: 0.94rem;
}

.tf-step span {
display: none;
font-size: 0.82rem;
line-height: 1.45;
}

.tf-step.is-active span {
display: block;
}

.tf-layout {
display: grid;
grid-template-columns: 256px minmax(0, 1fr);
gap: 18px;
align-items: start;
}

.tf-sidebar {
display: grid;
gap: 16px;
position: sticky;
top: 20px;
}

.tf-sidebar-card,
.tf-panel {
padding: 20px;
}

.tf-workspace {
display: grid;
gap: 18px;
}

.tf-panel-head {
display: flex;
flex-direction: column;
align-items: flex-start;
gap: 10px;
margin-bottom: 14px;
}

.tf-panel-head h2,
.tf-panel h3,
.tf-panel h4 {
margin: 0;
font-family: 'Space Grotesk', sans-serif;
letter-spacing: -0.03em;
}

.tf-panel-head h2 {
font-size: 1.48rem;
}

.tf-panel-head p {
max-width: 68ch;
margin: 0;
color: var(--tf-muted);
line-height: 1.65;
}

.tf-overline {
display: inline-block;
margin-bottom: 8px;
color: var(--tf-accent-soft);
font-size: 0.74rem;
letter-spacing: 0.11em;
text-transform: uppercase;
}

.tf-stats {
display: grid;
grid-template-columns: repeat(3, minmax(0, 1fr));
gap: 12px;
}

.tf-stat {
padding: 18px;
border-radius: 18px;
}

.tf-grid-2 {
display: grid;
grid-template-columns: repeat(2, minmax(0, 1fr));
gap: 18px;
}

.tf-stack {
display: grid;
gap: 18px;
}

.tf-subgrid {
display: grid;
gap: 12px;
}

.tf-subcard {
padding: 16px;
border-radius: var(--tf-radius-md);
background: rgba(255, 255, 255, 0.03);
border: 1px solid var(--tf-line);
}

.tf-list,
.tf-inline-list,
.tf-timeline {
margin: 0;
padding: 0;
list-style: none;
display: grid;
gap: 10px;
}

.tf-item-button,
.tf-list-item {
width: 100%;
min-width: 0;
text-align: left;
padding: 14px 16px;
border-radius: var(--tf-radius-md);
background: rgba(255, 255, 255, 0.03);
border: 1px solid var(--tf-line);
}

.tf-item-button {
cursor: pointer;
transition: transform 140ms ease, border-color 140ms ease, background 140ms ease;
}

.tf-item-button:hover {
transform: translateY(-1px);
border-color: rgba(255, 255, 255, 0.14);
}

.tf-item-button.is-selected {
background: rgba(232, 125, 86, 0.08);
border-color: rgba(232, 125, 86, 0.22);
}

.tf-item-head {
display: flex;
justify-content: space-between;
align-items: start;
gap: 12px;
margin-bottom: 8px;
}

.tf-item-head strong {
color: var(--tf-text);
min-width: 0;
overflow: hidden;
text-overflow: ellipsis;
white-space: nowrap;
}

.tf-pill {
display: inline-flex;
align-items: center;
padding: 6px 10px;
border-radius: 999px;
font-size: 0.72rem;
font-weight: 600;
border: 1px solid var(--tf-line);
background: rgba(255, 255, 255, 0.04);
color: var(--tf-text);
}

.tf-meta {
display: flex;
flex-wrap: wrap;
gap: 8px;
margin-bottom: 8px;
}

.tf-meta .tf-pill {
color: var(--tf-muted);
}

.tf-kv {
display: grid;
gap: 8px;
}

.tf-kv-row {
display: flex;
justify-content: space-between;
align-items: flex-start;
gap: 16px;
padding-top: 8px;
border-top: 1px solid rgba(255, 255, 255, 0.06);
}

.tf-kv-row:first-child {
border-top: 0;
padding-top: 0;
}

.tf-kv-row span:last-child {
color: var(--tf-text);
text-align: right;
overflow-wrap: anywhere;
}

.tf-empty {
margin: 0;
padding: 16px;
border-radius: var(--tf-radius-md);
border: 1px dashed rgba(255, 255, 255, 0.12);
color: var(--tf-dim);
background: rgba(255, 255, 255, 0.02);
}

.tf-scroll {
max-height: 460px;
overflow: auto;
padding-right: 4px;
}

.tf-scroll::-webkit-scrollbar {
width: 9px;
}

.tf-scroll::-webkit-scrollbar-thumb {
background: rgba(255, 255, 255, 0.10);
border-radius: 999px;
}

.tf-code {
padding: 14px;
border-radius: var(--tf-radius-md);
background: rgba(11, 11, 11, 0.72);
border: 1px solid var(--tf-line);
}

.tf-inline-code {
font-family: 'IBM Plex Mono', monospace;
font-size: 0.8rem;
}

.tf-action-row {
display: flex;
flex-wrap: wrap;
gap: 10px;
margin-top: 16px;
}

.tf-toolbar {
display: flex;
flex-wrap: wrap;
gap: 10px;
align-items: center;
}

.tf-form-grid {
display: grid;
grid-template-columns: repeat(2, minmax(0, 1fr));
gap: 12px;
}

.tf-field {
display: grid;
gap: 6px;
}

.tf-input,
.tf-textarea {
width: 100%;
min-width: 0;
padding: 11px 12px;
border-radius: 12px;
border: 1px solid var(--tf-line);
background: rgba(255, 255, 255, 0.03);
color: var(--tf-text);
outline: none;
}

.tf-textarea {
min-height: 92px;
resize: vertical;
}

.tf-input::placeholder,
.tf-textarea::placeholder {
color: var(--tf-dim);
}

.tf-input:focus,
.tf-textarea:focus {
border-color: rgba(232, 125, 86, 0.28);
box-shadow: 0 0 0 1px rgba(232, 125, 86, 0.18);
}

.tf-choice-row {
display: flex;
flex-wrap: wrap;
gap: 8px;
}

.tf-choice {
appearance: none;
border: 1px solid var(--tf-line);
background: rgba(255, 255, 255, 0.02);
color: var(--tf-muted);
padding: 9px 12px;
border-radius: 999px;
cursor: pointer;
}

.tf-choice.is-selected {
background: rgba(232, 125, 86, 0.12);
border-color: rgba(232, 125, 86, 0.26);
color: var(--tf-text);
}

.tf-helper {
color: var(--tf-dim);
font-size: 0.84rem;
line-height: 1.5;
}

.tf-btn {
appearance: none;
border: 1px solid var(--tf-line);
background: rgba(255, 255, 255, 0.03);
color: var(--tf-text);
padding: 11px 14px;
border-radius: 12px;
cursor: pointer;
transition: transform 140ms ease, border-color 140ms ease, background 140ms ease;
}

.tf-btn:hover {
transform: translateY(-1px);
border-color: rgba(255, 255, 255, 0.16);
}

.tf-btn--primary {
background: rgba(232, 125, 86, 0.14);
border-color: rgba(232, 125, 86, 0.28);
}

.tf-btn--ghost {
color: var(--tf-muted);
}

.tf-signal-rows {
display: grid;
gap: 14px;
}

.tf-signal-row {
display: grid;
grid-template-columns: 120px minmax(0, 1fr);
gap: 16px;
padding-top: 14px;
border-top: 1px solid rgba(255, 255, 255, 0.06);
}

.tf-signal-row:first-child {
padding-top: 0;
border-top: 0;
}

.tf-inline-list li,
.tf-subcard,
.tf-panel,
.tf-sidebar-card {
min-width: 0;
}

.tf-inline-list li {
overflow-wrap: anywhere;
}

.tf-inline-list--compact {
gap: 6px;
}

.tf-timeline li {
padding: 14px 16px;
border-radius: var(--tf-radius-md);
background: rgba(255, 255, 255, 0.03);
border: 1px solid var(--tf-line);
}

.tf-files {
margin-top: 8px;
color: var(--tf-dim);
font-family: 'IBM Plex Mono', monospace;
font-size: 0.78rem;
}

.tf-compare {
display: grid;
grid-template-columns: 1fr;
gap: 18px;
}

.tf-shell {
width: min(1120px, calc(100vw - 48px));
padding: 18px 0 56px;
}

.tf-hero-main--compact {
padding: 18px 22px;
}

.tf-hero-header {
display: flex;
justify-content: space-between;
align-items: flex-start;
gap: 20px;
}

.tf-brand {
margin: 8px 0 10px;
font-size: clamp(2.4rem, 5vw, 3.6rem);
}

.tf-tagline {
display: none;
}

.tf-lead {
max-width: 44ch;
font-size: 0.94rem;
line-height: 1.6;
}

.tf-context-row--stacked {
justify-content: flex-end;
max-width: 240px;
margin-top: 0;
}

.tf-inline-stats {
display: flex;
flex-wrap: wrap;
gap: 10px;
margin-top: 14px;
padding-top: 14px;
border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.tf-inline-stats span {
display: inline-flex;
align-items: center;
gap: 8px;
padding: 8px 12px;
border-radius: 999px;
border: 1px solid var(--tf-line);
background: rgba(255, 255, 255, 0.03);
color: var(--tf-muted);
font-size: 0.82rem;
}

.tf-inline-stats strong {
color: var(--tf-text);
}

.tf-stepper {
padding: 6px;
gap: 4px;
}

.tf-step {
padding: 10px 12px;
}

.tf-step span {
display: none !important;
}

.tf-layout {
grid-template-columns: 244px minmax(0, 1fr);
gap: 16px;
}

.tf-sidebar-card,
.tf-panel {
padding: 18px;
}

.tf-item-button,
.tf-list-item,
.tf-subcard,
.tf-stat {
border-radius: 14px;
}

.tf-scroll {
max-height: 360px;
}

.tf-form-grid {
grid-template-columns: 1fr;
}

.tf-grid-2 {
gap: 16px;
}

.tf-panel-head p,
.tf-body,
.tf-helper {
max-width: 64ch;
}

@media (max-width: 1080px) {
.tf-layout,
.tf-grid-2,
.tf-compare,
.tf-stats,
.tf-stepper {
    grid-template-columns: 1fr;
}

.tf-sidebar {
    position: static;
}

.tf-hero-strip {
    grid-template-columns: 1fr;
}

.tf-signal-row {
    grid-template-columns: 1fr;
    gap: 8px;
}

.tf-form-grid {
    grid-template-columns: 1fr;
}
}

@media (max-width: 760px) {
.tf-shell {
    width: min(100vw - 24px, 1440px);
    padding-top: 16px;
}

.tf-hero-main,
.tf-panel,
.tf-sidebar-card {
    padding: 18px;
    border-radius: 20px;
}

.tf-brand {
    font-size: 2.8rem;
}
}
""";
}

def failure_pill_style(family: str) -> dict {
    if family == "INVALID_PATCH" {
        return {
            "background": "rgba(232, 125, 86, 0.12)",
            "borderColor": "rgba(232, 125, 86, 0.24)",
            "color": "#f4b79e",
        };
    } elif family == "OSCILLATION_LOOP" {
        return {
            "background": "rgba(220, 184, 99, 0.12)",
            "borderColor": "rgba(220, 184, 99, 0.24)",
            "color": "#ead79c",
        };
    } elif family == "PREMATURE_COMPLETION" {
        return {
            "background": "rgba(146, 201, 197, 0.12)",
            "borderColor": "rgba(146, 201, 197, 0.24)",
            "color": "#c3ece8",
        };
    } elif family == "WRONG_FILE_FOCUS" {
        return {
            "background": "rgba(129, 153, 232, 0.12)",
            "borderColor": "rgba(129, 153, 232, 0.24)",
            "color": "#cbd6fb",
        };
    } elif family == "structured" {
        return {
            "background": "rgba(232, 125, 86, 0.12)",
            "borderColor": "rgba(232, 125, 86, 0.24)",
            "color": "#f4b79e",
        };
    } elif family == "baseline" or family == "raw" {
        return {
            "background": "rgba(255, 255, 255, 0.04)",
            "borderColor": "rgba(255, 255, 255, 0.10)",
            "color": "#f5efe8",
        };
    } elif family == "tie" {
        return {
            "background": "rgba(255, 255, 255, 0.04)",
            "borderColor": "rgba(255, 255, 255, 0.10)",
            "color": "#ded5cc",
        };
    }
    return {
        "background": "rgba(255, 255, 255, 0.04)",
        "borderColor": "rgba(255, 255, 255, 0.10)",
        "color": "#ded5cc",
    };
}

def top_item_text(item: any) -> str {
    if item == None {
        return "";
    }
    return str(item[0]) + " (" + str(item[1]) + ")";
}

def batch_summary_text(batch: any) -> str {
    return str(batch["name"]) + " / " + str(batch["run_count"]) + " runs";
}

def compact_text(text: str, maxLen: int) -> str {
    if len(text) > maxLen {
        return text[0:maxLen - 3] + "...";
    }
    return text;
}

def top_series_text(items: any, limit: int = 5) -> str {
    lines = [top_item_text(item) for item in items[0:limit]];
    return str(" • ".join(lines));
}

def:pub app() -> JsxElement {
    has status: str = "Booting TraceForge...";
    has authStatus: str = "Checking demo session...";
    has authError: str = "";
    has loading: bool = True;
    has loadingBatch: bool = False;
    has loadingRun: bool = False;
    has loadingCluster: bool = False;
    has loadingReport: bool = False;
    has loadingEval: bool = False;
    has activeView: str = "overview";
    has selectedBatchId: str = "";
    has selectedRunId: str = "";
    has selectedClusterId: str = "";
    has batchCatalog: any = {
        "batches": [],
        "batch_count": 0,
    };
    has overview: any = {
        "family_counts": {},
        "clusters": [],
        "top_files": [],
        "top_errors": [],
        "top_tests": [],
        "runs": [],
        "run_count": 0,
        "cluster_count": 0,
    };
    has runDetail: any = {
        "run_id": "",
        "summary": "",
        "primary_failure": "UNKNOWN",
        "critical_step_idx": -1,
        "critical_evidence_window": [],
        "timeline": [],
        "artifacts": {
            "fingerprint": {},
            "cluster_ids": [],
        },
    };
    has clusterDetail: any = {
        "cluster_id": "",
        "label": "",
        "summary": "",
        "failure_class": "UNKNOWN",
        "size": 0,
        "stored_patch_count": 0,
        "recurring_signals": [],
        "representative_runs": [],
    };
    has patchDetail: any = {
        "summary": "",
        "rules": [],
        "diff_text": "",
        "stored_in_graph": False,
        "stored_patch_id": "",
    };
    has clusterDiagnosis: any = {
        "label": "",
        "summary": "",
        "confidence": 0.0,
        "llm_used": False,
        "evidence_pack": "",
    };
    has comparison: any = {
        "status": "idle",
        "comparison_mode": "",
        "baseline": {
            "diagnosis": "",
            "compressed_trajectory": "",
            "specificity": "",
        },
        "structured": {
            "failure_class": "UNKNOWN",
            "critical_step_idx": -1,
            "evidence_window": [],
            "why_better": "",
        },
        "verifier": {
            "winner": "tie",
            "rationale": "",
        },
    };
    has diagnosis: any = {
        "irreversible_because": "",
        "evidence": [],
        "confidence": 0.0,
    };
    has reportDetail: any = {
        "status": "idle",
        "path": "",
        "preview": "",
        "run_count": 0,
        "cluster_count": 0,
    };
    has evalDetail: any = {
        "status": "idle",
        "blind_sheet_path": "",
        "blind_key_path": "",
        "summary_json_path": "",
        "selected_run_count": 0,
        "comparison_mode": "",
        "preview": "",
    };
    has rigorousEvalDetail: any = {
        "status": "idle",
        "provider": "",
        "model": "",
        "selected_run_count": 0,
        "summary_markdown_path": "",
        "gold_score_path": "",
        "preview": "",
    };
    has providerStatus: any = {
        "status": "idle",
        "preferred_provider": "auto",
        "resolved_provider": "",
        "resolved_model": "",
        "resolved_available": False,
        "providers": {
            "openai": {
                "label": "OpenAI",
                "available": False,
                "key_present": False,
                "key_source": "none",
                "key_preview": "",
                "model": "gpt-5.4",
            },
            "anthropic": {
                "label": "Anthropic / Claude",
                "available": False,
                "key_present": False,
                "key_source": "none",
                "key_preview": "",
                "model": "claude-sonnet-4-20250514",
            },
            "codex": {
                "label": "Codex CLI",
                "available": False,
                "logged_in": False,
                "cli_path": "",
                "version": "",
                "login_status": "",
                "model": "gpt-5.4",
            },
        },
    };
    has selectedProvider: str = "auto";
    has openaiKeyInput: str = "";
    has openaiModelInput: str = "gpt-5.4";
    has anthropicKeyInput: str = "";
    has anthropicModelInput: str = "claude-sonnet-4-20250514";
    has codexModelInput: str = "gpt-5.4";
    has uploadPathInput: str = "";
    has providerMessage: str = "";
    has uploadMessage: str = "";
    has loadingProvider: bool = False;
    has savingProvider: bool = False;
    has uploadingBatch: bool = False;
    has runningRigorousEval: bool = False;

    def action_provider_model(provider: str) -> str {
        provider_name = str(provider or "auto");
        if provider_name == "openai" {
            return str(openaiModelInput or providerStatus["providers"]["openai"]["model"] or "");
        }
        if provider_name == "anthropic" {
            return str(anthropicModelInput or providerStatus["providers"]["anthropic"]["model"] or "");
        }
        if provider_name == "codex" {
            return str(codexModelInput or providerStatus["providers"]["codex"]["model"] or "");
        }
        return "";
    }

    async def load_provider_status(syncSelection: bool = True) -> None {
        loadingProvider = True;
        provider_result = root spawn GetProviderStatus();
        if provider_result.reports {
            provider_data = provider_result.reports[0];
            providerStatus = provider_data;
            openaiModelInput = str(provider_data["providers"]["openai"]["model"] or "gpt-5.4");
            anthropicModelInput = str(provider_data["providers"]["anthropic"]["model"] or "claude-sonnet-4-20250514");
            codexModelInput = str(provider_data["providers"]["codex"]["model"] or "gpt-5.4");
            if syncSelection {
                selectedProvider = str(provider_data["preferred_provider"] or "auto");
            }
            providerMessage = "Resolved provider / " + str(provider_data["resolved_provider"] or "deterministic fallback");
        }
        loadingProvider = False;
    }

    async def save_provider_settings() -> None {
        savingProvider = True;
        providerMessage = "Saving provider settings...";
        save_result = root spawn SaveProviderConfig(
            preferred_provider=selectedProvider,
            openai_api_key=openaiKeyInput,
            openai_model=openaiModelInput,
            anthropic_api_key=anthropicKeyInput,
            anthropic_model=anthropicModelInput,
            codex_model=codexModelInput,
        );
        if save_result.reports {
            providerStatus = save_result.reports[0];
            providerMessage = str(save_result.reports[0]["message"] or "Provider settings saved.");
            openaiKeyInput = "";
            anthropicKeyInput = "";
        }
        savingProvider = False;
    }

    async def clear_provider_key(providerName: str) -> None {
        savingProvider = True;
        providerMessage = "Clearing saved " + providerName + " key...";
        clear_result = root spawn SaveProviderConfig(
            preferred_provider=selectedProvider,
            openai_model=openaiModelInput,
            anthropic_model=anthropicModelInput,
            codex_model=codexModelInput,
            clear_openai_key=providerName == "openai",
            clear_anthropic_key=providerName == "anthropic",
        );
        if clear_result.reports {
            providerStatus = clear_result.reports[0];
            providerMessage = "Saved " + providerName + " key cleared.";
        }
        savingProvider = False;
    }

    async def upload_batch_from_path() -> None {
        if not uploadPathInput {
            uploadMessage = "Enter a local folder name, folder path, or zip path.";
            return;
        }
        uploadingBatch = True;
        uploadMessage = "Loading batch from " + uploadPathInput + "...";
        upload_result = root spawn UploadBatch(filename=uploadPathInput);
        if upload_result.reports {
            upload_data = upload_result.reports[0];
            uploadMessage = str(upload_data["message"] or upload_data["status"] or "Batch loaded.");
            catalog_result = root spawn GetBatchCatalog();
            if catalog_result.reports {
                batchCatalog = catalog_result.reports[0];
            }
            if upload_data["batch_id"] {
                await load_batch(str(upload_data["batch_id"]));
                uploadPathInput = "";
            }
        }
        uploadingBatch = False;
    }

    async def refresh_current_comparison() -> None {
        if not selectedRunId {
            return;
        }
        status = "Refreshing comparison for " + selectedRunId + "...";
        compare_result = root spawn CompareBaseline(
            run_id=selectedRunId,
            batch_id=selectedBatchId,
            provider=selectedProvider,
            model=action_provider_model(selectedProvider),
        );
        if compare_result.reports {
            comparison = compare_result.reports[0];
        }
        status = "Comparison refreshed for " + selectedRunId + ".";
    }

    async def run_rigorous_evaluation() -> None {
        if not selectedBatchId {
            return;
        }
        activeView = "compare";
        runningRigorousEval = True;
        status = "Running rigorous evaluation for " + selectedBatchId + "...";
        eval_result = root spawn RunRigorousEvaluation(
            batch_id=selectedBatchId,
            provider=selectedProvider,
            model=action_provider_model(selectedProvider),
            substantive_limit=20,
            startup_limit=5,
        );
        if eval_result.reports {
            rigorousEvalDetail = eval_result.reports[0];
        }
        status = "Rigorous evaluation finished for " + selectedBatchId + ".";
        runningRigorousEval = False;
    }

    async def ensure_demo_session() -> bool {
        if jacIsLoggedIn() {
            authStatus = "Demo session ready.";
            authError = "";
            return True;
        }

        authStatus = "Authorizing demo session...";
        login_ok = await jacLogin("traceforge_demo_v1", "traceforge_demo_v1_pass");
        if login_ok {
            authStatus = "Demo session restored.";
            authError = "";
            return True;
        }

        signup_result = await jacSignup("traceforge_demo_v1", "traceforge_demo_v1_pass");
        if signup_result["success"] {
            authStatus = "Demo session created.";
            authError = "";
            return True;
        }

        authStatus = "Demo session failed.";
        authError = str(signup_result["error"] or "Could not authenticate demo user.");
        return False;
    }

    async def load_run(runId: str, batchId: str = "", focusView: bool = True) -> None {
        if not runId {
            return;
        }
        selectedRunId = runId;
        if focusView {
            activeView = "run";
        }
        loadingRun = True;
        status = "Loading run " + runId + "...";

        run_result = root spawn GetRunView(run_id=runId, batch_id=batchId);
        if run_result.reports {
            runDetail = run_result.reports[0];
        }

        diagnosis_result = root spawn DiagnoseRun(run_id=runId, batch_id=batchId);
        if diagnosis_result.reports {
            diagnosis = diagnosis_result.reports[0];
        }

        status = "Showing run " + runId + ".";
        loadingRun = False;
    }

    async def load_cluster(clusterId: str, focusView: bool = True) -> None {
        if not clusterId {
            return;
        }
        selectedClusterId = clusterId;
        if focusView {
            activeView = "clusters";
        }
        loadingCluster = True;
        status = "Loading cluster " + clusterId + "...";

        cluster_result = root spawn GetClusterView(cluster_id=clusterId);
        if cluster_result.reports {
            clusterDetail = cluster_result.reports[0];
        }

        cluster_diagnosis_result = root spawn DiagnoseCluster(cluster_id=clusterId);
        if cluster_diagnosis_result.reports {
            clusterDiagnosis = cluster_diagnosis_result.reports[0];
        }

        patch_result = root spawn CompileMemoryPatch(cluster_id=clusterId);
        if patch_result.reports {
            patchDetail = patch_result.reports[0];
        }

        status = "Showing cluster " + clusterId + ".";
        loadingCluster = False;
    }

    async def export_batch_report(batchId: str) -> None {
        if not batchId {
            return;
        }
        activeView = "compare";
        loadingReport = True;
        status = "Exporting report for " + batchId + "...";

        report_result = root spawn ExportBatchReport(batch_id=batchId);
        if report_result.reports {
            reportDetail = report_result.reports[0];
        }

        status = "Exported report for " + batchId + ".";
        loadingReport = False;
    }

    async def export_blinded_eval(batchId: str) -> None {
        if not batchId {
            return;
        }
        activeView = "compare";
        loadingEval = True;
        status = "Exporting blinded evaluation for " + batchId + "...";

        eval_result = root spawn ExportBlindedEvaluation(
            batch_id=batchId,
            provider=selectedProvider,
            model=action_provider_model(selectedProvider),
        );
        if eval_result.reports {
            evalDetail = eval_result.reports[0];
        }

        status = "Exported blinded evaluation for " + batchId + ".";
        loadingEval = False;
    }

    async def go_to_clusters() -> None {
        activeView = "clusters";
        if selectedClusterId and str(clusterDetail["cluster_id"] or "") != selectedClusterId {
            await load_cluster(selectedClusterId, False);
        }
    }

    async def go_to_run(runId: str = "") -> None {
        activeView = "run";
        target_run = str(runId or selectedRunId or "");
        if target_run and str(runDetail["run_id"] or "") != target_run {
            await load_run(target_run, selectedBatchId, False);
        }
    }

    async def go_to_compare(runComparison: bool = False) -> None {
        activeView = "compare";
        if runComparison and selectedRunId {
            await refresh_current_comparison();
        }
    }

    async def navigate_to_step(stepId: str) -> None {
        if stepId == "overview" {
            activeView = "overview";
            return;
        }
        if stepId == "clusters" {
            await go_to_clusters();
            return;
        }
        if stepId == "run" {
            await go_to_run();
            return;
        }
        await go_to_compare(False);
    }

    async def load_batch(batchId: str) -> None {
        if not batchId {
            return;
        }
        selectedBatchId = batchId;
        selectedRunId = "";
        selectedClusterId = "";
        activeView = "overview";
        clusterDetail = {
            "cluster_id": "",
            "label": "",
            "summary": "",
            "failure_class": "UNKNOWN",
            "size": 0,
            "stored_patch_count": 0,
            "recurring_signals": [],
            "representative_runs": [],
        };
        runDetail = {
            "run_id": "",
            "summary": "",
            "primary_failure": "UNKNOWN",
            "critical_step_idx": -1,
            "critical_evidence_window": [],
            "timeline": [],
            "artifacts": {
                "fingerprint": {},
                "cluster_ids": [],
            },
        };
        diagnosis = {
            "irreversible_because": "",
            "evidence": [],
            "confidence": 0.0,
        };
        comparison = {
            "status": "idle",
            "comparison_mode": "",
            "baseline": {
                "diagnosis": "",
                "compressed_trajectory": "",
                "specificity": "",
            },
            "structured": {
                "failure_class": "UNKNOWN",
                "critical_step_idx": -1,
                "evidence_window": [],
                "why_better": "",
            },
            "verifier": {
                "winner": "tie",
                "rationale": "",
            },
        };
        loadingBatch = True;
        reportDetail = {
            "status": "idle",
            "path": "",
            "preview": "",
            "run_count": 0,
            "cluster_count": 0,
        };
        evalDetail = {
            "status": "idle",
            "blind_sheet_path": "",
            "blind_key_path": "",
            "summary_json_path": "",
            "selected_run_count": 0,
            "comparison_mode": "",
            "preview": "",
        };
        rigorousEvalDetail = {
            "status": "idle",
            "provider": "",
            "model": "",
            "selected_run_count": 0,
            "summary_markdown_path": "",
            "gold_score_path": "",
            "preview": "",
        };
        status = "Loading batch " + batchId + "...";

        analyze = root spawn AnalyzeBatch(batch_id=batchId);
        if analyze.reports {
            status = str(analyze.reports[0]["message"]);
        }

        overview_result = root spawn GetBatchOverview(batch_id=batchId);
        if overview_result.reports {
            overview_data = overview_result.reports[0];
            overview = overview_data;

            if len(overview_data["clusters"]) > 0 {
                selectedClusterId = str(overview_data["clusters"][0]["cluster_id"]);
            }

            if len(overview_data["runs"]) > 0 {
                selectedRunId = str(overview_data["runs"][0]["run_id"]);
            }
        }

        status = "Showing batch " + batchId + ".";
        loadingBatch = False;
    }

    async can with entry {
        session_ready = await ensure_demo_session();
        if not session_ready {
            status = "TraceForge could not initialize the demo session.";
            loading = False;
            return;
        }

        await load_provider_status();

        catalog_result = root spawn GetBatchCatalog();
        if catalog_result.reports {
            catalog_data = catalog_result.reports[0];
            batchCatalog = catalog_data;

            if len(catalog_data["batches"]) > 0 {
                await load_batch(str(catalog_data["batches"][0]["batch_id"]));
            } else {
                status = "No batches available yet.";
            }
        }

        loading = False;
    }

    catalogEntries = batchCatalog["batches"] or [];
    familyRows = list(overview["family_counts"] or {});
    topFiles = overview["top_files"] or [];
    topErrors = overview["top_errors"] or [];
    topTests = overview["top_tests"] or [];
    clusters = overview["clusters"] or [];
    runs = overview["runs"] or [];
    diagnosisEvidence = diagnosis["evidence"] or [];
    criticalWindow = runDetail["critical_evidence_window"] or [];
    timeline = runDetail["timeline"] or [];
    representativeRuns = clusterDetail["representative_runs"] or [];
    recurringSignals = clusterDetail["recurring_signals"] or [];
    recurringFiles = clusterDetail["recurring_files"] or [];
    recurringErrors = clusterDetail["recurring_errors"] or [];
    recurringTests = clusterDetail["recurring_tests"] or [];
    patchRules = patchDetail["rules"] or [];
    baselineComparison = comparison["baseline"] or {};
    structuredComparison = comparison["structured"] or {};
    verifierComparison = comparison["verifier"] or {};
    structuredWindow = structuredComparison["evidence_window"] or [];
    baselineBlindSpots = baselineComparison["blind_spots"] or [];
    structuredSupportPoints = structuredComparison["support_points"] or [];

    sortedFamilies = sorted(familyRows, key=lambda (r: list) { float(r[1]) }, reverse=True);
    leadingFamily = "UNKNOWN";
    leadingFamilyCount = "0";
    if len(sortedFamilies) > 0 {
        leadingFamily = str(sortedFamilies[0][0]);
        leadingFamilyCount = str(sortedFamilies[0][1]);
    }

    activeBatch = {};
    for batch in catalogEntries {
        if str(batch["batch_id"]) == str(selectedBatchId) {
            activeBatch = batch;
        }
    }

    activeBatchName = str(activeBatch["name"] or selectedBatchId or "none");
    activeBatchPath = str(activeBatch["path"] or "");
    activeBatchDisplay = compact_text(activeBatchName, 22);
    selectedRunDisplay = compact_text(str(selectedRunId or "none"), 24);
    selectedClusterDisplay = compact_text(str(selectedClusterId or "none"), 28);
    topFilesText = top_series_text(topFiles, 5);
    topErrorsText = top_series_text(topErrors, 5);
    topTestsText = top_series_text(topTests, 5);
    providerCards = providerStatus["providers"] or {};
    openaiProvider = providerCards["openai"] or {};
    anthropicProvider = providerCards["anthropic"] or {};
    codexProvider = providerCards["codex"] or {};
    resolvedProviderDisplay = str(providerStatus["resolved_provider"] or "deterministic fallback");
    resolvedModelDisplay = str(providerStatus["resolved_model"] or "");
    selectedProviderDisplay = str(selectedProvider or "auto");
    selectedProviderModel = action_provider_model(selectedProvider);
    comparisonReady = str(comparison["status"] or "") == "comparison_ready";
    selectedClusterLoaded = str(clusterDetail["cluster_id"] or "") == str(selectedClusterId or "");
    selectedRunLoaded = str(runDetail["run_id"] or "") == str(selectedRunId or "");
    diagnosisMode = "Deterministic fallback";
    if diagnosis["llm_used"] {
        diagnosisMode = "Typed by llm()";
    }
    clusterDiagnosisMode = "Deterministic fallback";
    if clusterDiagnosis["llm_used"] {
        clusterDiagnosisMode = "Typed by llm()";
    }
    patchMode = "Deterministic fallback";
    if patchDetail["llm_used"] {
        patchMode = "Typed by llm()";
    }
    comparisonWinner = "pending";
    if comparisonReady {
        comparisonWinner = str(verifierComparison["winner"] or "tie");
    }

    workflowSteps = [
        {
            "id": "overview",
            "title": "1. Choose batch",
            "caption": "Load one trajectory corpus and read the batch signal.",
        },
        {
            "id": "clusters",
            "title": "2. Review clusters",
            "caption": "Inspect recurring motifs and generated rules.",
        },
        {
            "id": "run",
            "title": "3. Inspect run",
            "caption": "Localize the critical step and supporting evidence.",
        },
        {
            "id": "compare",
            "title": "4. Compare and export",
            "caption": "Contrast baseline vs TraceForge and generate artifacts.",
        },
    ];

    reportStatusText = "Idle";
    if loadingReport {
        reportStatusText = "Exporting";
    } elif reportDetail["status"] == "exported" {
        reportStatusText = "Ready";
    }

    evalStatusText = "Idle";
    if loadingEval {
        evalStatusText = "Exporting";
    } elif evalDetail["status"] == "exported" {
        evalStatusText = "Ready";
    }

    rigorousEvalStatusText = "Idle";
    if runningRigorousEval {
        rigorousEvalStatusText = "Running";
    } elif rigorousEvalDetail["status"] == "evaluated" {
        rigorousEvalStatusText = "Ready";
    }

    if loading {
        return <>
            <style>{ui_styles()}</style>
            <main className="tf-shell tf-loading">
                <section className="tf-card" style={{"padding": "28px", "width": "min(760px, 100%)"}}>
                    <span className="tf-kicker">JacHacks 2026 / loading</span>
                    <h1 className="tf-brand">TraceForge</h1>
                    <p className="tf-tagline">Graph-native failure intelligence</p>
                    <p className="tf-lead">
                        Establishing the demo session and hydrating the first batch surfaces.
                    </p>
                    <div className="tf-action-row">
                        <span className="tf-chip"><strong>Status</strong> {status}</span>
                        <span className="tf-chip"><strong>Auth</strong> {authStatus}</span>
                    </div>
                    {authError and <p className="tf-body" style={{"marginTop": "16px"}}>{authError}</p>}
                </section>
            </main>
        </>;
    }

    return <>
        <style>{ui_styles()}</style>
        <main className="tf-shell">
            <section className="tf-hero">
                <article className="tf-hero-main tf-hero-main--compact">
                    <div className="tf-hero-header">
                        <div>
                            <span className="tf-kicker">JacHacks 2026 / graph-backed demo</span>
                            <h1 className="tf-brand">TraceForge</h1>
                            <p className="tf-lead">
                                Review one batch at a time. Start with the batch signal, move into the strongest recurring motif, inspect the decisive run,
                                then compare raw transcript analysis against TraceForge retrieval.
                            </p>
                        </div>
                        <div className="tf-context-row tf-context-row--stacked">
                            <span className="tf-chip"><strong>Batch</strong> {activeBatchDisplay}</span>
                            <span className="tf-chip"><strong>Provider</strong> {selectedProviderDisplay}</span>
                            {selectedProviderModel and <span className="tf-chip"><strong>Model</strong> {selectedProviderModel}</span>}
                        </div>
                    </div>
                    <div className="tf-inline-stats">
                        <span><strong>Status</strong> {status}</span>
                        <span><strong>Auth</strong> {authStatus}</span>
                        <span><strong>Runs</strong> {str(overview["run_count"] or 0)}</span>
                        <span><strong>Clusters</strong> {str(overview["cluster_count"] or 0)}</span>
                    </div>
                    {authError and <div className="tf-helper" style={{"marginTop": "10px"}}>{authError}</div>}
                </article>
            </section>

            <nav className="tf-stepper">
                {for step in workflowSteps {
<button
                        key={str(step["id"])}
                        className={"tf-step" + (" is-active" if str(step["id"]) == str(activeView) else "")}
                        onClick={lambda (e: any) { navigate_to_step(str(step["id"])); }}
                    >
                        <strong>{str(step["title"])}</strong>
                        <span>{str(step["caption"])}</span>
                    </button>
}}}
            </nav>

            <section className="tf-layout">
                <aside className="tf-sidebar">
                    <article className="tf-sidebar-card">
                        <span className="tf-overline">Batch list</span>
                        <h3>Available batches</h3>
                        <div className="tf-list tf-scroll" style={{"marginTop": "16px"}}>
                            {for batch in catalogEntries {
<button
                                    key={str(batch["batch_id"])}
                                    className={"tf-item-button" + (" is-selected" if str(batch["batch_id"]) == str(selectedBatchId) else "")}
                                    onClick={lambda (e: any) { load_batch(str(batch["batch_id"])); }}
                                >
                                    <div className="tf-item-head">
                                        <strong>{compact_text(str(batch["name"]), 18)}</strong>
                                        <span className="tf-pill">{str(batch["kind"])}</span>
                                    </div>
                                    <div className="tf-meta">
                                        <span className="tf-pill">{str(batch["run_count"])} runs</span>
                                    </div>
                                </button>
}}}
                        </div>
                        <div className="tf-status-block" style={{"marginTop": "16px"}}>
                            <span className="tf-label">Current selection</span>
                            <div className="tf-body">Run / {selectedRunDisplay}</div>
                            <div className="tf-body">Cluster / {selectedClusterDisplay}</div>
                        </div>
                        <div className="tf-status-block" style={{"marginTop": "12px"}}>
                            <span className="tf-label">Load local batch</span>
                            <div className="tf-field">
                                <input
                                    className="tf-input"
                                    type="text"
                                    value={uploadPathInput}
                                    placeholder="uploads/my_batch or /abs/path.zip"
                                    onChange={lambda (e: any) { uploadPathInput = str(e.target.value or ""); }}
                                />
                            </div>
                            <div className="tf-action-row">
                                <button className="tf-btn" onClick={lambda (e: any) { upload_batch_from_path(); }}>
                                    {uploadingBatch and "Loading..." or "Load path"}
                                </button>
                            </div>
                            {uploadMessage and <div className="tf-helper" style={{"marginTop": "8px"}}>{uploadMessage}</div>}
                        </div>
                    </article>
                </aside>

                <section className="tf-workspace">
                    {activeView == "overview" and (
                        <>
                            <article className="tf-panel">
                                <div className="tf-panel-head">
                                    <div>
                                        <span className="tf-overline">Step 1</span>
                                        <h2>Batch overview</h2>
                                    </div>
                                    <p>
                                        Read the batch first. The goal is to understand whether one failure family dominates and which artifacts drive it.
                                    </p>
                                </div>

                                <div className="tf-stats">
                                    <div className="tf-stat">
                                        <span className="tf-label">Runs in scope</span>
                                        <strong>{str(overview["run_count"] or 0)}</strong>
                                        <span>Trajectory footprint</span>
                                    </div>
                                    <div className="tf-stat">
                                        <span className="tf-label">Clusters</span>
                                        <strong>{str(overview["cluster_count"] or 0)}</strong>
                                        <span>Recurring motifs found</span>
                                    </div>
                                    <div className="tf-stat">
                                        <span className="tf-label">Dominant motif</span>
                                        <strong>{leadingFamilyCount}</strong>
                                        <span>{leadingFamily}</span>
                                    </div>
                                </div>
                                <div className="tf-action-row">
                                    <button className="tf-btn tf-btn--primary" onClick={lambda (e: any) { go_to_clusters(); }}>
                                        Open recommended cluster
                                    </button>
                                    <button className="tf-btn" onClick={lambda (e: any) { go_to_run(); }}>
                                        Inspect suggested run
                                    </button>
                                    <button className="tf-btn tf-btn--ghost" onClick={lambda (e: any) { go_to_compare(False); }}>
                                        Connect a model
                                    </button>
                                </div>
                            </article>

                            <div className="tf-grid-2">
                                <article className="tf-panel">
                                    <span className="tf-overline">Failure families</span>
                                    <h3>What dominates this batch</h3>
                                    {len(sortedFamilies) > 0 and (
                                        <ul className="tf-list" style={{"marginTop": "14px"}}>
                                            {for item in sortedFamilies {
<li key={str(item[0])} className="tf-list-item">
                                                    <div className="tf-item-head">
                                                        <strong>{str(item[0])}</strong>
                                                        <span className="tf-pill" style={failure_pill_style(str(item[0]))}>
                                                            {str(item[1])} runs
                                                        </span>
                                                    </div>
                                                    <div className="tf-body">
                                                        TraceForge grouped this motif from graph fingerprints and repeated artifact context.
                                                    </div>
                                                </li>
}}}
                                        </ul>
                                    ) or <p className="tf-empty">No family counts are available yet.</p>}
                                </article>

                                <article className="tf-panel">
                                    <span className="tf-overline">Signal summary</span>
                                    <h3>Where the batch is noisy</h3>
                                    <div className="tf-signal-rows" style={{"marginTop": "14px"}}>
                                        <div className="tf-signal-row">
                                            <span className="tf-label">Top files</span>
                                            <div className="tf-body">{topFilesText or "No file hotspots."}</div>
                                        </div>
                                        <div className="tf-signal-row">
                                            <span className="tf-label">Top errors</span>
                                            <div className="tf-body">{topErrorsText or "No recurrent errors."}</div>
                                        </div>
                                        <div className="tf-signal-row">
                                            <span className="tf-label">Top tests</span>
                                            <div className="tf-body">{topTestsText or "No test signals."}</div>
                                        </div>
                                    </div>
                                </article>
                            </div>
                        </>
                    )}

                    {activeView == "clusters" and (
                        <div className="tf-stack">
                            <article className="tf-panel">
                                <div className="tf-panel-head">
                                    <div>
                                        <span className="tf-overline">Step 2</span>
                                        <h2>Failure clusters</h2>
                                    </div>
                                    <p>
                                        Pick one motif. This is the fastest path to showing repeated failure structure and the value of graph-backed grouping.
                                    </p>
                                </div>
                                <div className="tf-list tf-scroll">
                                    {for cluster in clusters {
<button
                                            key={str(cluster["cluster_id"])}
                                            className={"tf-item-button" + (" is-selected" if str(cluster["cluster_id"]) == str(selectedClusterId) else "")}
                                            onClick={lambda (e: any) { load_cluster(str(cluster["cluster_id"])); }}
                                        >
                                            <div className="tf-item-head">
                                                <strong>{str(cluster["label"])}</strong>
                                                <span className="tf-pill" style={failure_pill_style(str(cluster["failure_class"]))}>
                                                    {str(cluster["failure_class"])}
                                                </span>
                                            </div>
                                            <div className="tf-meta">
                                                <span className="tf-pill">Size {str(cluster["size"])}</span>
                                            </div>
                                            <div className="tf-body">{str(cluster["summary"])}</div>
                                        </button>
}}}
                                </div>
                            </article>

                            <article className="tf-panel">
                                <span className="tf-overline">Active cluster</span>
                                <div className="tf-item-head">
                                    <h3>{str(clusterDetail["label"] or "No cluster selected")}</h3>
                                    <span className="tf-pill" style={failure_pill_style(str(clusterDetail["failure_class"] or "UNKNOWN"))}>
                                        {str(clusterDetail["failure_class"] or "UNKNOWN")}
                                    </span>
                                </div>
                                <p className="tf-body">{str(clusterDetail["summary"] or "Select a cluster to inspect its repeated pattern.")}</p>
                                <div className="tf-kv" style={{"marginTop": "14px"}}>
                                    <div className="tf-kv-row">
                                        <span>Cluster size</span>
                                        <span>{str(clusterDetail["size"] or 0)}</span>
                                    </div>
                                    <div className="tf-kv-row">
                                        <span>Medoid run</span>
                                        <span>{str(clusterDetail["medoid_run_id"] or "none")}</span>
                                    </div>
                                    <div className="tf-kv-row">
                                        <span>Diagnosis mode</span>
                                        <span>{clusterDiagnosisMode}</span>
                                    </div>
                                    <div className="tf-kv-row">
                                        <span>Patch mode</span>
                                        <span>{patchMode}</span>
                                    </div>
                                </div>
                                <div className="tf-action-row" style={{"marginTop": "16px"}}>
                                    <button className="tf-btn tf-btn--primary" onClick={lambda (e: any) { go_to_run(str(clusterDetail["medoid_run_id"] or "")); }}>
                                        Open medoid run
                                    </button>
                                    <button className="tf-btn tf-btn--ghost" onClick={lambda (e: any) { go_to_compare(False); }}>
                                        Connect model for compare
                                    </button>
                                </div>
                                <div className="tf-grid-2" style={{"marginTop": "16px"}}>
                                    <div className="tf-subcard">
                                        <span className="tf-label">Recurring signals</span>
                                        {len(recurringSignals) > 0 and (
                                            <ul className="tf-inline-list">
                                                {for item in recurringSignals[0:6] {
<li key={str(item)}>{str(item)}</li>
}}}
                                            </ul>
                                        ) or <p className="tf-empty">No recurring signals.</p>}
                                    </div>
                                    <div className="tf-subcard">
                                        <span className="tf-label">Recurring files</span>
                                        {len(recurringFiles) > 0 and (
                                            <ul className="tf-inline-list">
                                                {for item in recurringFiles[0:6] {
<li key={str(item[0])}>{top_item_text(item)}</li>
}}}
                                            </ul>
                                        ) or <p className="tf-empty">No recurring files.</p>}
                                    </div>
                                </div>
                                <details>
                                    <summary>Cluster diagnosis, representative runs, and patch</summary>
                                    <div className="tf-subgrid" style={{"marginTop": "14px"}}>
                                        <div className="tf-subcard">
                                            <span className="tf-label">Diagnosis</span>
                                            <p className="tf-body">{str(clusterDiagnosis["summary"] or "")}</p>
                                            <div className="tf-body">Confidence / {str(clusterDiagnosis["confidence"] or 0)}</div>
                                        </div>
                                        <div className="tf-subcard">
                                            <span className="tf-label">Representative runs</span>
                                            {len(representativeRuns) > 0 and (
                                                <ul className="tf-list">
                                                    {for item in representativeRuns {
<li key={str(item["run_id"])} className="tf-list-item">
                                                            <div className="tf-item-head">
                                                                <strong>{str(item["run_id"])}</strong>
                                                                <button className="tf-btn tf-btn--ghost" onClick={lambda (e: any) { load_run(str(item["run_id"]), str(selectedBatchId)); }}>
                                                                    Open run
                                                                </button>
                                                            </div>
                                                            <div className="tf-body">{str(item["summary"])}</div>
                                                        </li>
}}}
                                                </ul>
                                            ) or <p className="tf-empty">No representative runs.</p>}
                                        </div>
                                        <div className="tf-subcard">
                                            <span className="tf-label">Memory patch</span>
                                            <p className="tf-body">{str(patchDetail["summary"] or "")}</p>
                                            {len(patchRules) > 0 and (
                                                <ul className="tf-inline-list">
                                                    {for rule in patchRules {
<li key={str(rule["title"])}>{str(rule["title"])}</li>
}}}
                                                </ul>
                                            ) or <p className="tf-empty">No patch rules yet.</p>}
                                        </div>
                                    </div>
                                </details>
                            </article>
                        </div>
                    )}

                    {activeView == "run" and (
                        <div className="tf-stack">
                            <article className="tf-panel">
                                <div className="tf-panel-head">
                                    <div>
                                        <span className="tf-overline">Step 3</span>
                                        <h2>Run browser</h2>
                                    </div>
                                    <p>
                                        Select one failed run and inspect the localized pivot, evidence, and timeline.
                                    </p>
                                </div>
                                <div className="tf-list tf-scroll">
                                    {for run in runs {
<button
                                            key={str(run["run_id"])}
                                            className={"tf-item-button" + (" is-selected" if str(run["run_id"]) == str(selectedRunId) else "")}
                                            onClick={lambda (e: any) { load_run(str(run["run_id"]), str(selectedBatchId)); }}
                                        >
                                            <div className="tf-item-head">
                                                <strong>{str(run["run_id"])}</strong>
                                                <span className="tf-pill" style={failure_pill_style(str(run["primary_failure"]))}>
                                                    {str(run["primary_failure"])}
                                                </span>
                                            </div>
                                            <div className="tf-meta">
                                                <span className="tf-pill">Critical step {str(run["critical_step_idx"])}</span>
                                            </div>
                                            <div className="tf-body">{str(run["summary"])}</div>
                                        </button>
}}}
                                </div>
                            </article>

                            <article className="tf-panel">
                                <span className="tf-overline">Active run</span>
                                <div className="tf-item-head">
                                    <h3>{str(runDetail["run_id"] or "No run selected")}</h3>
                                    <span className="tf-pill" style={failure_pill_style(str(runDetail["primary_failure"] or "UNKNOWN"))}>
                                        {str(runDetail["primary_failure"] or "UNKNOWN")}
                                    </span>
                                </div>
                                <p className="tf-body">{str(runDetail["summary"] or "Select a run to inspect its decision path.")}</p>
                                <div className="tf-kv" style={{"marginTop": "14px"}}>
                                    <div className="tf-kv-row">
                                        <span>Critical step</span>
                                        <span>{str(runDetail["critical_step_idx"] or -1)}</span>
                                    </div>
                                    <div className="tf-kv-row">
                                        <span>Diagnosis mode</span>
                                        <span>{diagnosisMode}</span>
                                    </div>
                                    <div className="tf-kv-row">
                                        <span>Linked clusters</span>
                                        <span>{str(len(runDetail["artifacts"]["cluster_ids"] or []) or 0)}</span>
                                    </div>
                                </div>
                                <div className="tf-action-row" style={{"marginTop": "16px"}}>
                                    <button className="tf-btn tf-btn--primary" onClick={lambda (e: any) { go_to_compare(True); }}>
                                        Compare this run
                                    </button>
                                    <button className="tf-btn tf-btn--ghost" onClick={lambda (e: any) { go_to_clusters(); }}>
                                        Back to clusters
                                    </button>
                                </div>
                                <div className="tf-subgrid" style={{"marginTop": "16px"}}>
                                    <div className="tf-subcard">
                                        <span className="tf-label">Why the run failed</span>
                                        <p className="tf-body">{str(diagnosis["irreversible_because"] or "")}</p>
                                        <div className="tf-body">Confidence / {str(diagnosis["confidence"] or 0)}</div>
                                    </div>
                                    <div className="tf-subcard">
                                        <span className="tf-label">Evidence refs</span>
                                        {len(diagnosisEvidence) > 0 and (
                                            <ul className="tf-inline-list">
                                                {for item in diagnosisEvidence {
<li key={str(item["step_idx"]) + ":" + str(item["artifact"])}>
                                                        <strong>Step {str(item["step_idx"])} [{str(item["artifact"])}]</strong>
                                                        <div className="tf-body">{str(item["quote"])}</div>
                                                    </li>
}}}
                                            </ul>
                                        ) or <p className="tf-empty">No evidence refs.</p>}
                                    </div>
                                    <div className="tf-subcard">
                                        <span className="tf-label">Critical window</span>
                                        {len(criticalWindow) > 0 and (
                                            <ol className="tf-timeline">
                                                {for item in criticalWindow {
<li key={str(item["idx"])}>
                                                        <strong>Step {str(item["idx"])} [{str(item["phase"])}]</strong>
                                                        <div className="tf-body">{str(item["excerpt"])}</div>
                                                    </li>
}}}
                                            </ol>
                                        ) or <p className="tf-empty">No critical window.</p>}
                                    </div>
                                </div>
                                <details>
                                    <summary>Full timeline and evidence pack</summary>
                                    <div className="tf-subgrid" style={{"marginTop": "14px"}}>
                                        <div className="tf-subcard">
                                            <span className="tf-label">Timeline</span>
                                            {len(timeline) > 0 and (
                                                <ol className="tf-timeline tf-scroll">
                                                    {for item in timeline {
<li key={str(item["idx"])}>
                                                            <strong>Step {str(item["idx"])} [{str(item["phase"])}]</strong>
                                                            <div className="tf-body">{str(item["excerpt"])}</div>
                                                            <div className="tf-files">{str((", ").join(item["touched_files"] or []))}</div>
                                                        </li>
}}}
                                                </ol>
                                            ) or <p className="tf-empty">No timeline.</p>}
                                        </div>
                                        <div className="tf-code">
                                            <pre>{str(diagnosis["evidence_pack"] or "")}</pre>
                                        </div>
                                    </div>
                                </details>
                            </article>
                        </div>
                    )}

                    {activeView == "compare" and (
                        <>
                            <article className="tf-panel">
                                <div className="tf-panel-head">
                                    <div>
                                        <span className="tf-overline">Step 4</span>
                                        <h2>Comparison and exports</h2>
                                    </div>
                                    <p>
                                        Finish the workflow by comparing the raw baseline with TraceForge retrieval, then export the report and blind-eval artifacts.
                                    </p>
                                </div>
                                <div className="tf-stats">
                                    <div className="tf-stat">
                                        <span className="tf-label">Winner</span>
                                        <strong>{comparisonWinner}</strong>
                                        <span>{str(comparison["comparison_mode"] or "same-schema")}</span>
                                    </div>
                                    <div className="tf-stat">
                                        <span className="tf-label">Provider</span>
                                        <strong>{resolvedProviderDisplay}</strong>
                                        <span>{resolvedModelDisplay or "default model"}</span>
                                    </div>
                                    <div className="tf-stat">
                                        <span className="tf-label">Rigorous eval</span>
                                        <strong>{str(rigorousEvalDetail["selected_run_count"] or 0)}</strong>
                                        <span>{rigorousEvalStatusText}</span>
                                    </div>
                                </div>
                            </article>

                            <div className="tf-grid-2">
                                <article className="tf-panel">
                                    <span className="tf-overline">Provider setup</span>
                                    <h3>Connect one model path</h3>
                                    <p className="tf-body">
                                        Use local Codex login, or save one OpenAI / Claude key locally for this machine. You only need one path active.
                                    </p>
                                    <div className="tf-choice-row" style={{"marginTop": "14px"}}>
                                        <button className={"tf-choice" + (" is-selected" if selectedProvider == "auto" else "")} onClick={lambda (e: any) { selectedProvider = "auto"; }}>
                                            Auto
                                        </button>
                                        <button className={"tf-choice" + (" is-selected" if selectedProvider == "codex" else "")} onClick={lambda (e: any) { selectedProvider = "codex"; }}>
                                            Codex
                                        </button>
                                        <button className={"tf-choice" + (" is-selected" if selectedProvider == "openai" else "")} onClick={lambda (e: any) { selectedProvider = "openai"; }}>
                                            OpenAI
                                        </button>
                                        <button className={"tf-choice" + (" is-selected" if selectedProvider == "anthropic" else "")} onClick={lambda (e: any) { selectedProvider = "anthropic"; }}>
                                            Claude
                                        </button>
                                    </div>
                                    <div className="tf-helper" style={{"marginTop": "10px"}}>
                                        {providerMessage or "If no model is configured, TraceForge falls back to the deterministic proxy comparison."}
                                    </div>
                                    <div className="tf-subgrid" style={{"marginTop": "16px"}}>
                                        {selectedProvider == "auto" and (
                                            <div className="tf-subcard">
                                                <span className="tf-label">Available providers</span>
                                                <div className="tf-kv">
                                                    <div className="tf-kv-row">
                                                        <span>Codex</span>
                                                        <span>{codexProvider["logged_in"] and "Logged in" or "Not ready"}</span>
                                                    </div>
                                                    <div className="tf-kv-row">
                                                        <span>OpenAI</span>
                                                        <span>{openaiProvider["available"] and "Key saved" or "No key"}</span>
                                                    </div>
                                                    <div className="tf-kv-row">
                                                        <span>Claude</span>
                                                        <span>{anthropicProvider["available"] and "Key saved" or "No key"}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        )}
                                        {selectedProvider == "codex" and (
                                            <div className="tf-subcard">
                                                <span className="tf-label">Codex CLI</span>
                                                <div className="tf-body">{str(codexProvider["login_status"] or "No Codex status yet.")}</div>
                                                <div className="tf-helper" style={{"marginTop": "8px"}}>
                                                    {str(codexProvider["version"] or "")}
                                                </div>
                                                <div className="tf-field" style={{"marginTop": "12px"}}>
                                                    <label className="tf-label">Codex model</label>
                                                    <input
                                                        className="tf-input"
                                                        type="text"
                                                        value={codexModelInput}
                                                        placeholder="gpt-5.4"
                                                        onChange={lambda (e: any) { codexModelInput = str(e.target.value or ""); }}
                                                    />
                                                </div>
                                                <div className="tf-helper" style={{"marginTop": "10px"}}>
                                                    Use the local `codex login` session already present on this machine.
                                                </div>
                                            </div>
                                        )}
                                        {selectedProvider == "openai" and (
                                            <div className="tf-subcard">
                                                <span className="tf-label">OpenAI</span>
                                                <div className="tf-helper">Saved key / {str(openaiProvider["key_preview"] or "none")} ({str(openaiProvider["key_source"] or "none")})</div>
                                                <div className="tf-field" style={{"marginTop": "12px"}}>
                                                    <label className="tf-label">API key</label>
                                                    <input
                                                        className="tf-input"
                                                        type="password"
                                                        value={openaiKeyInput}
                                                        placeholder="Leave blank to keep current"
                                                        onChange={lambda (e: any) { openaiKeyInput = str(e.target.value or ""); }}
                                                    />
                                                </div>
                                                <div className="tf-field" style={{"marginTop": "12px"}}>
                                                    <label className="tf-label">Model</label>
                                                    <input
                                                        className="tf-input"
                                                        type="text"
                                                        value={openaiModelInput}
                                                        placeholder="gpt-5.4"
                                                        onChange={lambda (e: any) { openaiModelInput = str(e.target.value or ""); }}
                                                    />
                                                </div>
                                                <div className="tf-action-row">
                                                    <button className="tf-btn tf-btn--ghost" onClick={lambda (e: any) { clear_provider_key("openai"); }}>
                                                        Clear OpenAI key
                                                    </button>
                                                </div>
                                            </div>
                                        )}
                                        {selectedProvider == "anthropic" and (
                                            <div className="tf-subcard">
                                                <span className="tf-label">Anthropic / Claude</span>
                                                <div className="tf-helper">Saved key / {str(anthropicProvider["key_preview"] or "none")} ({str(anthropicProvider["key_source"] or "none")})</div>
                                                <div className="tf-field" style={{"marginTop": "12px"}}>
                                                    <label className="tf-label">API key</label>
                                                    <input
                                                        className="tf-input"
                                                        type="password"
                                                        value={anthropicKeyInput}
                                                        placeholder="Leave blank to keep current"
                                                        onChange={lambda (e: any) { anthropicKeyInput = str(e.target.value or ""); }}
                                                    />
                                                </div>
                                                <div className="tf-field" style={{"marginTop": "12px"}}>
                                                    <label className="tf-label">Model</label>
                                                    <input
                                                        className="tf-input"
                                                        type="text"
                                                        value={anthropicModelInput}
                                                        placeholder="claude-sonnet-4-20250514"
                                                        onChange={lambda (e: any) { anthropicModelInput = str(e.target.value or ""); }}
                                                    />
                                                </div>
                                                <div className="tf-action-row">
                                                    <button className="tf-btn tf-btn--ghost" onClick={lambda (e: any) { clear_provider_key("anthropic"); }}>
                                                        Clear Claude key
                                                    </button>
                                                </div>
                                            </div>
                                        )}
                                        <div className="tf-subcard">
                                            <span className="tf-label">Execution path</span>
                                            <div className="tf-body">Requested provider / {selectedProviderDisplay}</div>
                                            <div className="tf-body">Requested model / {selectedProviderModel or "default"}</div>
                                            <div className="tf-body">Resolved backend / {resolvedProviderDisplay}</div>
                                            <div className="tf-body">Resolved model / {resolvedModelDisplay or "default"}</div>
                                            <div className="tf-action-row">
                                                <button className="tf-btn" onClick={lambda (e: any) { load_provider_status(False); }}>
                                                    {loadingProvider and "Refreshing..." or "Refresh status"}
                                                </button>
                                                <button className="tf-btn tf-btn--primary" onClick={lambda (e: any) { save_provider_settings(); }}>
                                                    {savingProvider and "Saving..." or "Save provider settings"}
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </article>

                                <article className="tf-panel">
                                    <span className="tf-overline">Run it now</span>
                                    <h3>Current run and batch actions</h3>
                                    <div className="tf-kv" style={{"marginTop": "16px"}}>
                                        <div className="tf-kv-row">
                                            <span>Selected run</span>
                                            <span>{selectedRunDisplay}</span>
                                        </div>
                                        <div className="tf-kv-row">
                                            <span>Selected batch</span>
                                            <span>{activeBatchDisplay}</span>
                                        </div>
                                        <div className="tf-kv-row">
                                            <span>Comparison mode</span>
                                            <span>{str(comparison["comparison_mode"] or "not run yet")}</span>
                                        </div>
                                    </div>
                                    <div className="tf-action-row">
                                        <button className="tf-btn tf-btn--primary" onClick={lambda (e: any) { refresh_current_comparison(); }}>
                                            Run comparison
                                        </button>
                                        <button className="tf-btn" onClick={lambda (e: any) { run_rigorous_evaluation(); }}>
                                            {runningRigorousEval and "Running evaluation..." or "Run rigorous evaluation"}
                                        </button>
                                    </div>
                                    <div className="tf-helper" style={{"marginTop": "12px"}}>
                                        Rigorous evaluation uses the fixed subset selection and writes namespaced artifacts under exports/evals.
                                    </div>
                                    <details style={{"marginTop": "14px"}}>
                                        <summary>Rigorous evaluation preview</summary>
                                        <div className="tf-code" style={{"marginTop": "14px"}}>
                                            <pre>{str(rigorousEvalDetail["preview"] or "")}</pre>
                                        </div>
                                    </details>
                                </article>
                            </div>

                            <article className="tf-panel">
                                <span className="tf-overline">Comparison result</span>
                                {comparisonReady and (
                                    <>
                                        <div className="tf-item-head">
                                            <h3>Verdict for the active run</h3>
                                            <span className="tf-pill" style={failure_pill_style(comparisonWinner)}>
                                                {comparisonWinner}
                                            </span>
                                        </div>
                                        <p className="tf-body">{str(verifierComparison["rationale"] or "TraceForge is ready to compare once a run is selected.")}</p>
                                        <div className="tf-grid-2" style={{"marginTop": "16px"}}>
                                            <div className="tf-subcard">
                                                <span className="tf-label">Raw transcript diagnosis</span>
                                                <p className="tf-body">{str(baselineComparison["diagnosis"] or "")}</p>
                                                <div className="tf-body">Specificity / {str(baselineComparison["specificity"] or "")}</div>
                                                <details style={{"marginTop": "12px"}}>
                                                    <summary>Blind spots and compressed trajectory</summary>
                                                    <div className="tf-subgrid" style={{"marginTop": "12px"}}>
                                                        <div className="tf-subcard">
                                                            <span className="tf-label">Blind spots</span>
                                                            {len(baselineBlindSpots) > 0 and (
                                                                <ul className="tf-inline-list">
                                                                    {for item in baselineBlindSpots {
<li key={str(item)}>{str(item)}</li>
}}}
                                                                </ul>
                                                            ) or <p className="tf-empty">No blind spots.</p>}
                                                        </div>
                                                        <div className="tf-code">
                                                            <pre>{str(baselineComparison["compressed_trajectory"] or "")}</pre>
                                                        </div>
                                                    </div>
                                                </details>
                                            </div>
                                            <div className="tf-subcard">
                                                <span className="tf-label">TraceForge diagnosis</span>
                                                <p className="tf-body">{str(structuredComparison["why_better"] or "")}</p>
                                                <div className="tf-body">Critical step / {str(structuredComparison["critical_step_idx"] or -1)}</div>
                                                <div className="tf-body">Specificity / {str(structuredComparison["specificity"] or "")}</div>
                                                <details style={{"marginTop": "12px"}}>
                                                    <summary>Support points and evidence window</summary>
                                                    <div className="tf-subgrid" style={{"marginTop": "12px"}}>
                                                        <div className="tf-subcard">
                                                            <span className="tf-label">Support points</span>
                                                            {len(structuredSupportPoints) > 0 and (
                                                                <ul className="tf-inline-list">
                                                                    {for item in structuredSupportPoints {
<li key={str(item)}>{str(item)}</li>
}}}
                                                                </ul>
                                                            ) or <p className="tf-empty">No support points.</p>}
                                                        </div>
                                                        <div className="tf-subcard">
                                                            <span className="tf-label">Evidence window</span>
                                                            {len(structuredWindow) > 0 and (
                                                                <ol className="tf-timeline">
                                                                    {for item in structuredWindow {
<li key={str(item["idx"])}>
                                                                            <strong>Step {str(item["idx"])} [{str(item["phase"])}]</strong>
                                                                            <div className="tf-body">{str(item["excerpt"])}</div>
                                                                        </li>
}}}
                                                                </ol>
                                                            ) or <p className="tf-empty">No evidence window.</p>}
                                                        </div>
                                                    </div>
                                                </details>
                                            </div>
                                        </div>
                                    </>
                                ) or (
                                    <div className="tf-empty">
                                        Select a run, connect a provider if needed, and press <strong>Run comparison</strong>. The raw and structured diagnoses will appear here.
                                    </div>
                                )}
                            </article>

                            <div className="tf-grid-2">
                                <article className="tf-panel">
                                    <span className="tf-overline">Report export</span>
                                    <h3>Markdown artifact</h3>
                                    <p className="tf-body">
                                        Keep one clean report per batch as the fallback artifact outside the live UI.
                                    </p>
                                    <div className="tf-action-row">
                                        <button className="tf-btn tf-btn--primary" onClick={lambda (e: any) { export_batch_report(str(selectedBatchId)); }}>
                                            Export report
                                        </button>
                                    </div>
                                    <div className="tf-kv" style={{"marginTop": "14px"}}>
                                        <div className="tf-kv-row">
                                            <span>Status</span>
                                            <span>{reportStatusText}</span>
                                        </div>
                                        <div className="tf-kv-row">
                                            <span>Path</span>
                                            <span className="tf-inline-code">{str(reportDetail["path"] or "")}</span>
                                        </div>
                                    </div>
                                    <details>
                                        <summary>Report preview</summary>
                                        <div className="tf-code" style={{"marginTop": "14px"}}>
                                            <pre>{str(reportDetail["preview"] or "")}</pre>
                                        </div>
                                    </details>
                                </article>

                                <article className="tf-panel">
                                    <span className="tf-overline">Blind eval export</span>
                                    <h3>Judging sheet</h3>
                                    <p className="tf-body">
                                        Export the fair same-model A/B sheet and summary artifacts used for evaluation.
                                    </p>
                                    <div className="tf-action-row">
                                        <button className="tf-btn" onClick={lambda (e: any) { export_blinded_eval(str(selectedBatchId)); }}>
                                            Export blind eval
                                        </button>
                                    </div>
                                    <div className="tf-kv" style={{"marginTop": "14px"}}>
                                        <div className="tf-kv-row">
                                            <span>Status</span>
                                            <span>{evalStatusText}</span>
                                        </div>
                                        <div className="tf-kv-row">
                                            <span>Sheet</span>
                                            <span className="tf-inline-code">{str(evalDetail["blind_sheet_path"] or "")}</span>
                                        </div>
                                        <div className="tf-kv-row">
                                            <span>Summary</span>
                                            <span className="tf-inline-code">{str(evalDetail["summary_json_path"] or "")}</span>
                                        </div>
                                        <div className="tf-kv-row">
                                            <span>Rigorous eval</span>
                                            <span className="tf-inline-code">{str(rigorousEvalDetail["summary_markdown_path"] or "")}</span>
                                        </div>
                                    </div>
                                    <details>
                                        <summary>Blind eval preview</summary>
                                        <div className="tf-code" style={{"marginTop": "14px"}}>
                                            <pre>{str(evalDetail["preview"] or "")}</pre>
                                        </div>
                                    </details>
                                </article>
                            </div>
                        </>
                    )}
                </section>
            </section>
        </main>
    </>;
}

