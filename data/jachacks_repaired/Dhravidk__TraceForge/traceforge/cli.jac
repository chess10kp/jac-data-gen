import argparse;
import json;
import re;
import from pathlib { Path }
import from shutil { which }
import from sys { argv }
import from traceforge.analysis {
    analyze_batch_summary,
    batch_overview_summary,
    cluster_view_summary,
    run_view_summary,
}
import from traceforge.eval {
    compare_run_harness_summary,
    export_blinded_eval_summary,
    pack_run_summary,
    run_rigorous_eval_summary,
}
import from traceforge.ingest { upload_batch_summary }
import from traceforge.provider_config {
    provider_resolution_summary,
    provider_status_summary,
    save_provider_config_summary,
}
import from traceforge.reporting { export_report_summary }

import traceforge.__init__;
import traceforge.schema;
import traceforge.ingest;
import traceforge.parser;
import traceforge.features;
import traceforge.clustering;
import traceforge.critical;
import traceforge.graph_build;
import traceforge.analysis;
import traceforge.llm_ops;
import traceforge.eval;
import traceforge.reporting;
import traceforge.provider_config;
import traceforge.api;

def _repo_root() -> any {
    return Path(__file__).resolve().parents[1];
}

def _jac_binary() -> str {
    local = _repo_root().joinpath(".venv", "bin", "jac");
    if local.exists() {
        return str(local);
    }
    discovered = which("jac");
    if discovered {
        return str(discovered);
    }
    raise SystemExit("TraceForge CLI could not find `jac`. Create `.venv` first or add `jac` to PATH.");
}

def _emit_json(payload: dict[str, any]) -> int {
    print(json.dumps(payload, indent=2));
    return 0;
}

def _print_kv(label: str, value: any) -> None {
    print(label + ": " + str(value));
}

def _print_list(title: str, items: list[any], limit: int = 5) -> None {
    if not items {
        return;
    }
    print(title);
    for item in items[:limit] {
        print("- " + str(item));
    }
}

def _print_section(title: str) -> None {
    print("");
    print(title);
}

def _truncate(text: any, limit: int = 140) -> str {
    value = " ".join(str(text or "").split());
    if len(value) <= limit {
        return value;
    }
    return value[: max(0, limit - 3)].rstrip() + "...";
}

def _format_pairs(items: list[any], limit: int = 5) -> str {
    rendered: list[str] = [];
    for item in items[:limit] {
        if isinstance(item, (list, tuple)) and len(item) >= 2 {
            rendered.append(str(item[0]) + " (" + str(item[1]) + ")");
        } else {
            rendered.append(str(item));
        }
    }
    return ", ".join(rendered);
}

def _dominant_family(family_counts: dict[str, any]) -> str {
    if not family_counts {
        return "";
    }
    ranked = sorted(family_counts.items(), key=lambda (pair: any) -> any { (-pair[1], pair[0]) });
    family_name = ranked[0][0];
    count = ranked[0][1];
    return str(family_name) + " (" + str(count) + ")";
}

def _format_family_counts(family_counts: dict[str, any]) -> str {
    rendered: list[str] = [];
    for pair in sorted(family_counts.items(), key=lambda (item: any) -> any { item[0] }) {
        rendered.append(str(pair[0]) + "=" + str(pair[1]));
    }
    return ", ".join(rendered);
}

def _comparison_warning(payload: dict[str, any], requested_provider: str = "") -> str {
    comparison_mode = str(payload.get("comparison_mode") or "");
    if comparison_mode != "deterministic_proxy" {
        return "";
    }
    verifier = payload.get("verifier", {});
    detail = str(verifier.get("llm_error") or "").strip();
    if detail {
        return "Live provider compare was requested but fell back to deterministic proxy: " + detail;
    }
    if requested_provider and requested_provider != "auto" {
        return "Requested provider was not used live. The result shown here is deterministic proxy output.";
    }
    return "No live provider was configured. The result shown here is deterministic proxy output.";
}

def _artifact_paths(payload: dict[str, any]) -> dict[str, str] {
    paths: dict[str, str] = {};
    for key in ["path", "blind_sheet_path", "blind_key_path", "summary_json_path", "summary_markdown_path", "gold_score_path"] {
        value = str(payload.get(key) or "").strip();
        if value {
            paths[key] = value;
        }
    }
    return paths;
}

def _slug(text: str) -> str {
    cleaned = re.sub(r"[^a-zA-Z0-9._-]+", "_", str(text or "").strip());
    cleaned = re.sub(r"_+", "_", cleaned).strip("._");
    return cleaned or "artifact";
}

def _write_text_output(path_value: str, text: str) -> str {
    target = Path(path_value).expanduser();
    if not target.is_absolute() {
        target = _repo_root().joinpath(target);
    }
    target.parent.mkdir(parents=True, exist_ok=True);
    target.write_text(text, encoding="utf-8");
    return str(target.relative_to(_repo_root()));
}

def _write_json_output(path_value: str, payload: dict[str, any]) -> str {
    target = Path(path_value).expanduser();
    if not target.is_absolute() {
        target = _repo_root().joinpath(target);
    }
    target.parent.mkdir(parents=True, exist_ok=True);
    target.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8");
    return str(target.relative_to(_repo_root()));
}

def _default_pack_output_path(batch_id: str, run_id: str, mode: str) -> str {
    batch = _slug(batch_id or "batch");
    run_id_slug = _slug(run_id or "run");
    pack_mode = _slug(mode or "structured");
    return "exports/packs/" + batch + "_" + run_id_slug + "_" + pack_mode + ".md";
}

def _default_compare_output_path(batch_id: str, run_id: str, provider: str) -> str {
    batch = _slug(batch_id or "batch");
    run_id_slug = _slug(run_id or "run");
    provider_slug = _slug(provider or "auto");
    return "exports/comparisons/" + batch + "_" + run_id_slug + "_" + provider_slug + ".json";
}

def _default_demo_output_dir(batch_id: str, run_id: str) -> str {
    batch = _slug(batch_id or "batch");
    run_id_slug = _slug(run_id or "run");
    return "exports/demo/" + batch + "_" + run_id_slug;
}

def _copy_text_artifact(source_path: str, output_path: str) -> str {
    source = Path(source_path).expanduser();
    if not source.is_absolute() {
        source = _repo_root().joinpath(source_path);
    }
    if not source.exists() {
        raise SystemExit("Expected artifact does not exist: " + str(source));
    }
    target = Path(output_path).expanduser();
    if not target.is_absolute() {
        target = _repo_root().joinpath(output_path);
    }
    target.parent.mkdir(parents=True, exist_ok=True);
    target.write_text(source.read_text(encoding="utf-8"), encoding="utf-8");
    return str(target.relative_to(_repo_root()));
}

def _augment_payload(
    payload: dict[str, any],
    command: str,
    requested_provider: str = "",
    strict_provider: bool = False,
) -> dict[str, any] {
    enriched = dict(payload);
    enriched["command"] = command;
    enriched["strict_provider"] = strict_provider;
    if command in {"compare", "export-eval"} {
        warning = _comparison_warning(payload, requested_provider);
        if warning {
            enriched["warning"] = warning;
        }
    }
    if command in {"export-report", "export-eval"} {
        enriched["artifact_paths"] = _artifact_paths(payload);
    }
    return enriched;
}

def _doctor_payload() -> dict[str, any] {
    payload = provider_status_summary();
    payload["jac_binary"] = _jac_binary();
    payload["repo_root"] = str(_repo_root());
    codex = payload.get("providers", {}).get("codex", {});
    payload["demo_ready"] = bool(codex.get("available")) and bool(codex.get("logged_in"));
    payload["recommended_demo_mode"] = "codex_cli_live_compare" if payload["demo_ready"] else "pack_first_with_export_fallback";
    return payload;
}

def _render_doctor(payload: dict[str, any]) -> None {
    print("TraceForge doctor");
    _print_kv("Repo root", payload.get("repo_root", ""));
    _print_kv("Jac binary", payload.get("jac_binary", ""));
    _print_kv("Preferred provider", payload.get("preferred_provider", "auto"));
    _print_kv("Resolved provider", payload.get("resolved_provider", "") or "none");
    _print_kv("Resolved available", payload.get("resolved_available", False));
    print("");
    providers = payload.get("providers", {});
    for name in ["codex", "openai", "anthropic"] {
        provider = providers.get(name, {});
        print("[" + str(provider.get("label", name)) + "]");
        for key in ["available", "logged_in", "model", "key_present", "key_source", "cli_path", "login_status", "version"] {
            if key in provider and provider.get(key) not in {"", None} {
                _print_kv(key.replace("_", " ").title(), provider.get(key));
            }
        }
        print("");
    }
    _print_kv("Recommended demo mode", payload.get("recommended_demo_mode", ""));
    print("");
    print("Next steps");
    if payload.get("demo_ready") {
        print("- Use `traceforge compare --batch sample-starter --run premature_completion --strict-provider` for a live compare.");
        print("- Use `traceforge demo --batch sample-starter --run premature_completion --strict-provider` to prepare the live demo bundle.");
    } else {
        print("- Start with `traceforge pack --batch sample-starter --run invalid_patch --mode structured`.");
        print("- Use exported artifacts as the demo fallback if live provider compare is unavailable.");
    }
}

def _render_analyze(payload: dict[str, any]) -> None {
    print("Batch " + str(payload.get("batch_id", "")));
    _print_kv("Status", payload.get("status", ""));
    _print_kv("Runs", payload.get("run_count", 0));
    _print_kv("Clusters", payload.get("cluster_count", 0));
    status_counts = payload.get("status_counts", {});
    if status_counts {
        _print_kv("Run statuses", _format_family_counts(status_counts));
    }
    family_counts = payload.get("family_counts", {});
    if family_counts {
        _print_kv("Families", _format_family_counts(family_counts));
    }
    print("");
    print("Next steps");
    print("- `traceforge overview --batch " + str(payload.get("batch_id", "")) + "`");
    print("- `traceforge run --batch " + str(payload.get("batch_id", "")) + " --run invalid_patch`");
}

def _render_overview(payload: dict[str, any]) -> None {
    batch_id = str(payload.get("batch_id", ""));
    runs = payload.get("runs", []);
    clusters = payload.get("clusters", []);
    family_counts = payload.get("family_counts", {});
    top_cluster = max(clusters, key=lambda (item: any) { item.get("size", 0) }, `default={}) if clusters else {};
    top_run = runs[0] if runs else {};

    print("Batch " + str(payload.get("batch_id", "")));
    _print_kv("Status", payload.get("status", ""));
    _print_kv("Runs", len(runs));
    _print_kv("Clusters", len(clusters));
    status_counts = payload.get("status_counts", {});
    if status_counts {
        _print_kv("Run statuses", _format_family_counts(status_counts));
    }
    if family_counts {
        _print_kv("Families", _format_family_counts(family_counts));
    }
    dominant_family = _dominant_family(family_counts);
    if dominant_family {
        _print_kv("Dominant family", dominant_family);
    }

    if top_cluster {
        _print_section("Recommended starting point");
        _print_kv("Cluster", top_cluster.get("cluster_id", ""));
        _print_kv("Why start here", _truncate(top_cluster.get("summary", ""), 100));
        _print_kv("Medoid run", top_cluster.get("medoid_run_id", ""));
    }

    if clusters {
        _print_section("Top clusters");
        for cluster in clusters[:3] {
            label = cluster.get("label", "");
            cluster_id = cluster.get("cluster_id", "");
            size = cluster.get("size", 0);
            medoid = cluster.get("medoid_run_id", "");
            summary = _truncate(cluster.get("summary", ""), 90);
            print("- " + str(label) + " | size=" + str(size) + " | medoid=" + str(medoid));
            print("  " + str(cluster_id));
            if summary {
                print("  " + summary);
            }
        }
    }

    top_files = payload.get("top_files", []);
    top_errors = payload.get("top_errors", []);
    top_tests = payload.get("top_tests", []);
    if top_files or top_errors or top_tests {
        _print_section("Recurring signals");
        if top_files {
            _print_kv("Files", _format_pairs(top_files));
        }
        if top_errors {
            _print_kv("Errors", _format_pairs(top_errors));
        }
        if top_tests {
            _print_kv("Tests", _format_pairs(top_tests));
        }
    }

    if top_run {
        _print_section("Suggested next steps");
        next_cluster = top_cluster.get("cluster_id", "") if top_cluster else clusters[0].get("cluster_id", "");
        print("- Inspect the recommended cluster: `traceforge cluster --cluster " + str(next_cluster) + "`");
        print("- Inspect one failed run: `traceforge run --batch " + batch_id + " --run " + str(top_run.get("run_id", "")) + "`");
        print("- Generate the structured pack: `traceforge pack --batch " + batch_id + " --run " + str(top_run.get("run_id", "")) + " --mode structured --save`");
    }
}

def _render_run(payload: dict[str, any]) -> None {
    print("Run " + str(payload.get("run_id", "")));
    _print_kv("Task", payload.get("task_title", ""));
    _print_kv("Exit status", payload.get("exit_status", ""));
    _print_kv("API calls", payload.get("api_calls", 0));
    _print_kv("Cost", payload.get("cost", 0.0));
    _print_kv("Primary failure", payload.get("primary_failure", ""));
    _print_kv("Critical step", payload.get("critical_step_idx", -1));
    _print_kv("Source path", payload.get("source_path", ""));
    telemetry = payload.get("artifacts", {}).get("telemetry", {});
    if telemetry.get("trajectory_format") {
        _print_kv("Trajectory format", telemetry.get("trajectory_format", ""));
    }
    summary = str(payload.get("summary", "")).strip();
    if summary {
        print("");
        print(summary);
    }
    top_files = payload.get("artifacts", {}).get("fingerprint", {}).get("top_files", []);
    if top_files {
        print("");
        _print_kv("Top files", ", ".join(top_files[:5]));
    }
    evidence_window = payload.get("critical_evidence_window", []);
    if evidence_window {
        print("");
        print("Critical evidence window");
        for step in evidence_window[:3] {
            excerpt = str(step.get("excerpt") or "").splitlines()[0];
            print("- Step " + str(step.get("idx", -1)) + " [" + str(step.get("phase", "")) + "]: " + excerpt);
        }
    }
    print("");
    print("Next steps");
    print("- `traceforge pack --batch " + str(payload.get("batch_id", "")) + " --run " + str(payload.get("run_id", "")) + " --mode raw`");
    print("- `traceforge pack --batch " + str(payload.get("batch_id", "")) + " --run " + str(payload.get("run_id", "")) + " --mode structured`");
}

def _render_cluster(payload: dict[str, any]) -> None {
    batch_id = str(payload.get("batch_id", ""));
    medoid_run_id = str(payload.get("medoid_run_id", ""));
    medoid = payload.get("medoid", {});

    print("Cluster " + str(payload.get("cluster_id", "")));
    _print_kv("Label", payload.get("label", ""));
    _print_kv("Failure class", payload.get("failure_class", ""));
    _print_kv("Size", payload.get("size", 0));
    _print_kv("Medoid run", payload.get("medoid_run_id", ""));

    summary = _truncate(payload.get("summary", ""), 120);
    if summary {
        _print_kv("Summary", summary);
    }

    recurring = payload.get("recurring_signals", []);
    if recurring {
        _print_section("Recurring signals");
        for item in recurring[:5] {
            print("- " + str(item));
        }
    }

    recurring_files = payload.get("recurring_files", []);
    recurring_errors = payload.get("recurring_errors", []);
    recurring_tests = payload.get("recurring_tests", []);
    if recurring_files or recurring_errors or recurring_tests {
        _print_section("Footprint");
        if recurring_files {
            _print_kv("Files", _format_pairs(recurring_files));
        }
        if recurring_errors {
            _print_kv("Errors", _format_pairs(recurring_errors));
        }
        if recurring_tests {
            _print_kv("Tests", _format_pairs(recurring_tests));
        }
    }

    if medoid {
        _print_section("Medoid run");
        _print_kv("Run", medoid.get("run_id", ""));
        _print_kv("Critical step", medoid.get("critical_step_idx", -1));
        medoid_summary = _truncate(medoid.get("summary", ""), 180);
        if medoid_summary {
            print(medoid_summary);
        }
    }

    if payload.get("patch_ready") {
        _print_section("Reusable memory");
        _print_kv("Stored patch count", payload.get("stored_patch_count", 0));
        stored_patch_ids = payload.get("stored_patch_ids", []);
        if stored_patch_ids {
            _print_kv("Patch ids", ", ".join(stored_patch_ids[:3]));
        }
    }

    if medoid_run_id {
        _print_section("Suggested next steps");
        print("- Inspect the medoid run: `traceforge run --batch " + batch_id + " --run " + medoid_run_id + "`");
        print("- Generate a structured pack: `traceforge pack --batch " + batch_id + " --run " + medoid_run_id + " --mode structured --save`");
        print("- Compare raw vs structured: `traceforge compare --batch " + batch_id + " --run " + medoid_run_id + " --save`");
    }
}

def _render_pack(payload: dict[str, any]) -> None {
    print("Pack mode: " + str(payload.get("mode", "")));
    _print_kv("Run", payload.get("run_id", ""));
    _print_kv("Task", payload.get("task_title", ""));
    _print_kv("Primary failure", payload.get("primary_failure", ""));
    _print_kv("Token estimate", payload.get("token_estimate", 0));
    artifact_paths = payload.get("artifact_paths", {});
    if artifact_paths.get("pack_path") {
        _print_kv("Saved pack", artifact_paths.get("pack_path"));
    }
    print("");
    print(str(payload.get("text", "")));
}

def _render_compare(payload: dict[str, any]) -> None {
    run_id = str(payload.get("run_id", ""));
    print("Compare run " + str(payload.get("run_id", "")));
    _print_kv("Comparison mode", payload.get("comparison_mode", ""));
    _print_kv("Provider", payload.get("provider", "") or "none");
    _print_kv("Provider available", payload.get("provider_available", False));
    artifact_paths = payload.get("artifact_paths", {});
    if artifact_paths.get("comparison_path") {
        _print_kv("Saved comparison", artifact_paths.get("comparison_path"));
    }
    print("");
    baseline = payload.get("baseline", {});
    structured = payload.get("structured", {});
    verifier = payload.get("verifier", {});
    warning = str(payload.get("warning") or "").strip();
    if warning {
        print("Warning");
        print("- " + warning);
    }
    _print_section("Verdict");
    verdict_winner = str(verifier.get("winner", ""));
    _print_kv("Winner", verdict_winner);
    _print_kv("Rationale", _truncate(verifier.get("rationale", ""), 180));
    llm_error = str(verifier.get("llm_error") or "").strip();
    if llm_error {
        _print_kv("Provider detail", _truncate(llm_error, 180));
    }

    _print_section("Raw diagnosis");
    _print_kv("Failure class", baseline.get("failure_class", ""));
    _print_kv("Critical step", baseline.get("critical_step_idx", -1));
    _print_kv("Specificity", baseline.get("specificity", ""));
    raw_rationale = str(baseline.get("short_rationale") or "").strip();
    if raw_rationale {
        _print_kv("Rationale", _truncate(raw_rationale, 160));
    }

    _print_section("Structured diagnosis");
    _print_kv("Failure class", structured.get("failure_class", ""));
    _print_kv("Critical step", structured.get("critical_step_idx", -1));
    _print_kv("Specificity", structured.get("specificity", ""));
    why_better = structured.get("why_better", "");
    if why_better {
        label = "Why structured won" if verdict_winner == "structured" else "Structured pack notes";
        _print_kv(label, _truncate(why_better, 180));
    }
    support_points = structured.get("support_points", []);
    if support_points {
        _print_list("Support points", support_points);
    }

    _print_section("Suggested next steps");
    print("- Save durable artifacts: `traceforge compare --batch " + str(payload.get("batch_id", "")) + " --run " + run_id + " --save`");
    print("- Generate the raw pack: `traceforge pack --batch " + str(payload.get("batch_id", "")) + " --run " + run_id + " --mode raw --save`");
    print("- Generate the structured pack: `traceforge pack --batch " + str(payload.get("batch_id", "")) + " --run " + run_id + " --mode structured --save`");
}

def _render_export_report(payload: dict[str, any]) -> None {
    print("Batch " + str(payload.get("batch_id", "")));
    _print_kv("Status", payload.get("status", ""));
    for key in ["markdown_path", "report_path", "path"] {
        if key in payload and payload.get(key) {
            _print_kv("Report", payload.get(key));
            break;
        }
    }
    print("");
    print("Use this artifact as the fallback demo path if live compare is unavailable.");
}

def _render_export_eval(payload: dict[str, any]) -> None {
    print("Batch " + str(payload.get("batch_id", "")));
    _print_kv("Status", payload.get("status", ""));
    _print_kv("Comparison mode", payload.get("comparison_mode", ""));
    warning = str(payload.get("warning") or "").strip();
    if warning {
        _print_kv("Warning", warning);
    }
    artifact_paths = payload.get("artifact_paths", {});
    if artifact_paths {
        _print_section("Artifacts");
    }
    label_map = {
        "blind_sheet_path": "Blind sheet",
        "blind_key_path": "Blind key",
        "summary_json_path": "Comparison JSON",
        "summary_markdown_path": "Summary markdown",
        "gold_score_path": "Gold score",
    };
    for key in ["blind_sheet_path", "blind_key_path", "summary_json_path", "summary_markdown_path", "gold_score_path"] {
        if payload.get(key) {
            _print_kv(label_map.get(key, key), payload.get(key));
        }
    }
    if artifact_paths {
        _print_section("Suggested next steps");
        if payload.get("blind_sheet_path") {
            print("- Open the blind sheet first for side-by-side judging.");
        }
        if payload.get("summary_markdown_path") {
            print("- Keep the markdown summary ready as the demo fallback artifact.");
        }
    }
}

def _render_demo(payload: dict[str, any]) -> None {
    print("TraceForge demo bundle");
    _print_kv("Batch", payload.get("batch_id", ""));
    _print_kv("Run", payload.get("run_id", ""));
    _print_kv("Provider", payload.get("provider", "") or "none");
    _print_kv("Comparison mode", payload.get("comparison_mode", ""));
    warning = str(payload.get("warning") or "").strip();
    if warning {
        print("");
        print("Warning");
        print("- " + warning);
    }
    artifact_paths = payload.get("artifact_paths", {});
    if artifact_paths {
        print("");
        print("Artifacts");
        for item in artifact_paths.items() {
            print("- " + str(item[0]) + ": " + str(item[1]));
        }
    }
    print("");
    print("Suggested demo order");
    print("- Open the saved raw pack.");
    print("- Open the saved structured pack.");
    print("- Open the saved comparison JSON or the markdown report.");
}

def _save_auth(args: any) -> dict[str, any] {
    preferred_provider = getattr(args, "provider", "auto");
    openai_model = args.model if preferred_provider == "openai" else "";
    anthropic_model = args.model if preferred_provider == "anthropic" else "";
    codex_model = args.model if preferred_provider == "codex" else "";
    return save_provider_config_summary(
        preferred_provider=preferred_provider,
        openai_api_key=args.openai_api_key or "",
        openai_model=openai_model,
        anthropic_api_key=args.anthropic_api_key or "",
        anthropic_model=anthropic_model,
        codex_model=codex_model,
        codex_cli_path=args.codex_cli_path or "",
        clear_openai_key=False,
        clear_anthropic_key=False,
    );
}

def _clear_auth() -> dict[str, any] {
    return save_provider_config_summary(
        preferred_provider="auto",
        clear_openai_key=True,
        clear_anthropic_key=True,
    );
}

def _resolve_batch(args: any) -> str {
    if args.input {
        upload = upload_batch_summary(args.input);
        batch_id = str(upload.get("batch_id") or "");
        if not batch_id {
            raise SystemExit("UploadBatch did not return a batch_id.");
        }
        return batch_id;
    }
    return str(args.batch);
}

def _enforce_strict_provider(payload: dict[str, any], requested_provider: str, strict: bool) -> None {
    if not strict {
        return;
    }
    requested = str(requested_provider or "auto");
    resolved = provider_resolution_summary(requested);
    resolved_provider = str(resolved.get("provider") or requested or "");
    if requested == "auto" and not resolved_provider {
        raise SystemExit("Strict provider mode requires a live resolved provider. Run `traceforge doctor` first.");
    }
    if not payload.get("provider_available", False) {
        if resolved_provider and requested == "auto" {
            raise SystemExit(
                "Resolved provider `"
                + resolved_provider
                + "` is not available. Run `traceforge doctor` to inspect provider readiness."
            );
        }
        raise SystemExit("Requested provider is not available. Run `traceforge doctor` to inspect provider readiness.");
    }
    if payload.get("comparison_mode") == "deterministic_proxy" {
        verifier = payload.get("verifier", {});
        detail = verifier.get("llm_error") or "Compare fell back to deterministic proxy.";
        provider_label = " `" + resolved_provider + "`" if resolved_provider else "";
        raise SystemExit(
            str(detail)
            + " Strict mode expected live provider"
            + provider_label
            + ". Run `traceforge doctor` and verify provider quota/auth state."
        );
    }
}

def _save_pack_artifact(payload: dict[str, any], output_path: str = "", save: bool = False) -> dict[str, any] {
    if not (output_path or save) {
        return payload;
    }
    artifact_paths = dict(payload.get("artifact_paths", {}));
    target_path = output_path or _default_pack_output_path(
        str(payload.get("batch_id") or "batch"),
        str(payload.get("run_id") or "run"),
        str(payload.get("mode") or "structured"),
    );
    artifact_paths["pack_path"] = _write_text_output(target_path, str(payload.get("text") or ""));
    payload["artifact_paths"] = artifact_paths;
    return payload;
}

def _save_compare_artifact(payload: dict[str, any], output_path: str = "", save: bool = False) -> dict[str, any] {
    if not (output_path or save) {
        return payload;
    }
    artifact_paths = dict(payload.get("artifact_paths", {}));
    target_path = output_path or _default_compare_output_path(
        str(payload.get("batch_id") or "batch"),
        str(payload.get("run_id") or "run"),
        str(payload.get("provider") or "auto"),
    );
    artifact_paths["comparison_path"] = _write_json_output(target_path, payload);
    payload["artifact_paths"] = artifact_paths;
    return payload;
}

def build_parser() -> any {
    parser = argparse.ArgumentParser(
        prog="traceforge",
        description="Graph-backed trajectory analysis for Codex CLI and Claude Code workflows.",
        epilog=(
            "Quickstart:\n"
            + "  traceforge doctor\n"
            + "  traceforge analyze-batch --batch sample-starter\n"
            + "  traceforge run --batch sample-starter --run invalid_patch\n"
            + "  traceforge pack --batch sample-starter --run invalid_patch --mode structured\n\n"
            + "Core thesis:\n"
            + "  same failed run, same outer model, better evidence pack"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    );
    json_parent = argparse.ArgumentParser(add_help=False);
    json_parent.add_argument("--json", action="store_true", help="Render machine-readable JSON.");

    subparsers = parser.add_subparsers(dest="command", required=True);

    subparsers.add_parser("doctor", help="Show provider and environment readiness.", parents=[json_parent]);

    auth = subparsers.add_parser("auth", help="Manage provider preferences.");
    auth_subparsers = auth.add_subparsers(dest="auth_command", required=True);
    auth_subparsers.add_parser("status", help="Show saved provider state.", parents=[json_parent]);
    auth_use = auth_subparsers.add_parser("use", help="Save the preferred provider.", parents=[json_parent]);
    auth_use.add_argument("provider", choices=["auto", "codex", "openai", "anthropic"]);
    auth_use.add_argument("--model", `default="");
    auth_use.add_argument("--openai-api-key", `default="");
    auth_use.add_argument("--anthropic-api-key", `default="");
    auth_use.add_argument("--codex-cli-path", `default="");
    auth_subparsers.add_parser("clear", help="Clear saved API keys and reset provider selection.", parents=[json_parent]);

    analyze = subparsers.add_parser("analyze-batch", help="Analyze a sample or uploaded batch.", parents=[json_parent]);
    analyze.add_argument("--batch", `default="sample-starter");
    analyze.add_argument("--input", `default="");
    analyze.add_argument("--force-rebuild", action="store_true");

    overview = subparsers.add_parser("overview", help="Show batch overview.", parents=[json_parent]);
    overview.add_argument("--batch", required=True);

    run_parser = subparsers.add_parser("run", help="Inspect one run.", parents=[json_parent]);
    run_parser.add_argument("--batch", `default="");
    run_parser.add_argument("--run", required=True);

    cluster = subparsers.add_parser("cluster", help="Inspect one cluster.", parents=[json_parent]);
    cluster.add_argument("--cluster", required=True);

    pack = subparsers.add_parser("pack", help="Emit a raw or structured evidence pack.", parents=[json_parent]);
    pack.add_argument("--batch", `default="");
    pack.add_argument("--run", required=True);
    pack.add_argument("--mode", choices=["raw", "structured"], `default="structured");
    pack.add_argument("--output", `default="");
    pack.add_argument("--save", action="store_true");

    compare = subparsers.add_parser("compare", help="Compare raw versus structured analysis on the same run.", parents=[json_parent]);
    compare.add_argument("--batch", `default="");
    compare.add_argument("--run", required=True);
    compare.add_argument("--provider", `default="auto", choices=["auto", "codex", "openai", "anthropic"]);
    compare.add_argument("--model", `default="");
    compare.add_argument("--strict-provider", action="store_true");
    compare.add_argument("--output", `default="");
    compare.add_argument("--save", action="store_true");

    demo = subparsers.add_parser("demo", help="Generate the full sample demo artifact bundle.", parents=[json_parent]);
    demo.add_argument("--batch", `default="sample-starter");
    demo.add_argument("--run", `default="premature_completion");
    demo.add_argument("--provider", `default="auto", choices=["auto", "codex", "openai", "anthropic"]);
    demo.add_argument("--model", `default="");
    demo.add_argument("--strict-provider", action="store_true");
    demo.add_argument("--output-dir", `default="");

    report_cmd = subparsers.add_parser("export-report", help="Export the batch markdown report.", parents=[json_parent]);
    report_cmd.add_argument("--batch", required=True);

    export_eval = subparsers.add_parser("export-eval", help="Export blinded or rigorous evaluation artifacts.", parents=[json_parent]);
    export_eval.add_argument("--batch", required=True);
    export_eval.add_argument("--kind", choices=["blind", "rigorous"], `default="blind");
    export_eval.add_argument("--limit", type=int, `default=10);
    export_eval.add_argument("--substantive-only", action="store_true");
    export_eval.add_argument("--provider", `default="auto", choices=["auto", "codex", "openai", "anthropic"]);
    export_eval.add_argument("--model", `default="");
    export_eval.add_argument("--strict-provider", action="store_true");
    export_eval.add_argument("--substantive-limit", type=int, `default=20);
    export_eval.add_argument("--startup-limit", type=int, `default=5);
    export_eval.add_argument("--annotation-path", `default="");

    return parser;
}

def main(arg_list: list[str] = []) -> int {
    parser = build_parser();
    args = parser.parse_args(arg_list);

    if args.command == "doctor" {
        payload = _augment_payload(_doctor_payload(), "doctor");
        if args.json {
            return _emit_json(payload);
        }
        _render_doctor(payload);
        return 0;
    }

    if args.command == "auth" {
        if args.auth_command == "status" {
            payload = provider_status_summary();
        } elif args.auth_command == "use" {
            payload = _save_auth(args);
        } else {
            payload = _clear_auth();
        }
        payload = _augment_payload(payload, "auth");
        if args.json {
            return _emit_json(payload);
        }
        _render_doctor(payload);
        return 0;
    }

    if args.command == "analyze-batch" {
        batch_id = _resolve_batch(args);
        payload = analyze_batch_summary(root, batch_id, args.force_rebuild);
        payload = _augment_payload(payload, "analyze-batch");
        if args.json {
            return _emit_json(payload);
        }
        _render_analyze(payload);
        return 0;
    }

    if args.command == "overview" {
        payload = _augment_payload(batch_overview_summary(root, args.batch), "overview");
        if args.json {
            return _emit_json(payload);
        }
        _render_overview(payload);
        return 0;
    }

    if args.command == "run" {
        payload = _augment_payload(run_view_summary(root, args.run, args.batch), "run");
        if args.json {
            return _emit_json(payload);
        }
        _render_run(payload);
        return 0;
    }

    if args.command == "cluster" {
        payload = _augment_payload(cluster_view_summary(root, args.cluster), "cluster");
        if args.json {
            return _emit_json(payload);
        }
        _render_cluster(payload);
        return 0;
    }

    if args.command == "pack" {
        payload = _augment_payload(pack_run_summary(root, args.run, args.batch, args.mode), "pack");
        output_path = args.output or _default_pack_output_path(
            str(payload.get("batch_id") or args.batch or "batch"),
            str(payload.get("run_id") or args.run),
            str(payload.get("mode") or args.mode),
        );
        payload = _save_pack_artifact(payload, output_path if (args.output or args.save) else "", args.save);
        if args.json {
            return _emit_json(payload);
        }
        _render_pack(payload);
        return 0;
    }

    if args.command == "compare" {
        payload = compare_run_harness_summary(root, args.run, args.batch, args.provider, args.model);
        _enforce_strict_provider(payload, args.provider, args.strict_provider);
        payload = _augment_payload(payload, "compare", args.provider, args.strict_provider);
        output_path = args.output or _default_compare_output_path(
            str(payload.get("batch_id") or args.batch or "batch"),
            str(payload.get("run_id") or args.run),
            str(payload.get("provider") or args.provider or "auto"),
        );
        payload = _save_compare_artifact(payload, output_path if (args.output or args.save) else "", args.save);
        if args.json {
            return _emit_json(payload);
        }
        _render_compare(payload);
        return 0;
    }

    if args.command == "demo" {
        demo_dir = args.output_dir or _default_demo_output_dir(args.batch, args.run);
        analyze_payload = _augment_payload(analyze_batch_summary(root, args.batch), "analyze-batch");
        run_payload = _augment_payload(run_view_summary(root, args.run, args.batch), "run");
        raw_payload = _save_pack_artifact(
            _augment_payload(pack_run_summary(root, args.run, args.batch, "raw"), "pack"),
            demo_dir + "/raw.md",
            True,
        );
        structured_payload = _save_pack_artifact(
            _augment_payload(pack_run_summary(root, args.run, args.batch, "structured"), "pack"),
            demo_dir + "/structured.md",
            True,
        );
        compare_payload = compare_run_harness_summary(root, args.run, args.batch, args.provider, args.model);
        _enforce_strict_provider(compare_payload, args.provider, args.strict_provider);
        compare_payload = _save_compare_artifact(
            _augment_payload(compare_payload, "compare", args.provider, args.strict_provider),
            demo_dir + "/comparison.json",
            True,
        );
        report_payload = _augment_payload(export_report_summary(root, args.batch), "export-report");
        report_path = str(report_payload.get("path") or "");
        copied_report = "";
        if report_path {
            copied_report = _copy_text_artifact(report_path, demo_dir + "/report.md");
        }
        bundle = {
            "status": "demo_bundle_ready",
            "command": "demo",
            "batch_id": args.batch,
            "run_id": args.run,
            "provider": str(compare_payload.get("provider") or ""),
            "comparison_mode": str(compare_payload.get("comparison_mode") or ""),
            "strict_provider": args.strict_provider,
            "warning": str(compare_payload.get("warning") or ""),
            "artifact_paths": {
                "raw_pack": str(raw_payload.get("artifact_paths", {}).get("pack_path") or ""),
                "structured_pack": str(structured_payload.get("artifact_paths", {}).get("pack_path") or ""),
                "comparison": str(compare_payload.get("artifact_paths", {}).get("comparison_path") or ""),
                "report": copied_report or report_path,
            },
            "analyze": analyze_payload,
            "run": run_payload,
        };
        if args.json {
            return _emit_json(bundle);
        }
        _render_demo(bundle);
        return 0;
    }

    if args.command == "export-report" {
        payload = _augment_payload(export_report_summary(root, args.batch), "export-report");
        if args.json {
            return _emit_json(payload);
        }
        _render_export_report(payload);
        return 0;
    }

    if args.command == "export-eval" {
        strict_resolution = provider_resolution_summary(args.provider);
        strict_provider_name = str(strict_resolution.get("provider") or args.provider or "");
        if args.kind == "rigorous" {
            payload = run_rigorous_eval_summary(
                root,
                args.batch,
                args.provider,
                args.model,
                int(args.substantive_limit),
                int(args.startup_limit),
                args.annotation_path,
            );
            if args.strict_provider {
                if args.provider in {"", "auto"} and not strict_provider_name {
                    raise SystemExit("Strict provider mode requires a live resolved provider. Run `traceforge doctor` first.");
                }
                if payload.get("comparison_mode") == "deterministic_proxy" {
                    raise SystemExit(
                        "Rigorous evaluation fell back to deterministic proxy. Strict mode expected live provider `"
                        + str(strict_provider_name or args.provider)
                        + "`."
                    );
                }
            }
        } else {
            payload = export_blinded_eval_summary(
                root,
                args.batch,
                int(args.limit),
                bool(args.substantive_only),
                args.provider,
                args.model,
            );
            if args.strict_provider {
                if args.provider in {"", "auto"} and not strict_provider_name {
                    raise SystemExit("Strict provider mode requires a live resolved provider. Run `traceforge doctor` first.");
                }
                if payload.get("comparison_mode") == "deterministic_proxy" {
                    raise SystemExit(
                        "Blinded export fell back to deterministic proxy. Strict mode expected live provider `"
                        + str(strict_provider_name or args.provider)
                        + "`."
                    );
                }
            }
        }
        payload = _augment_payload(payload, "export-eval", args.provider, args.strict_provider);
        if args.json {
            return _emit_json(payload);
        }
        _render_export_eval(payload);
        return 0;
    }

    parser.error("Unknown command.");
    return 2;
}

with entry:__main__ {
    raise SystemExit(main(list(argv[1:])));
}
