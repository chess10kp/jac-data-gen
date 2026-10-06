import json;
import from os { getenv }
import from pathlib { Path }
import from shutil { rmtree }
import from subprocess { run }
import from tempfile { mkdtemp }
import from time { perf_counter }
import from urllib.error { HTTPError, URLError }
import from urllib.request { Request, urlopen }
import from traceforge.analysis { batch_overview_summary, run_view_summary }
import from traceforge.critical { localize_critical_step }
import from traceforge.features { compute_run_fingerprint, dominant_failure_label }
import from traceforge.graph_build { failure_class_name }
import from traceforge.llm_ops {
    cluster_rule_lines,
    diagnosis_reason,
}
import from traceforge.provider_config {
    configured_codex_cli_path,
    configured_provider_key,
    configured_provider_model,
    provider_resolution_summary,
}
import from traceforge.parser { hash_text, parse_run, step_text, truncate_text }

def _pack_token_estimate(text: str) -> int {
    if not text {
        return 0;
    }
    return max(len(text) // 4, 1);
}

def _specificity_label(evidence_count: int, critical_step_idx: int, pack_mode: str) -> str {
    if critical_step_idx < 0 and evidence_count <= 1 {
        return "low";
    }
    if pack_mode == "traceforge_retrieval_prompt" and evidence_count >= 2 and critical_step_idx >= 0 {
        return "high";
    }
    return "medium";
}

def _normalize_failure_class(name: str) -> str {
    if not name {
        return "UNKNOWN";
    }
    allowed = {
        "PREMATURE_COMPLETION",
        "INVALID_PATCH",
        "WRONG_FILE_FOCUS",
        "OSCILLATION_LOOP",
        "TOOL_MISUSE",
        "STALE_CONTEXT_OR_BAD_PLAN",
        "REQUIREMENT_DRIFT",
        "UNKNOWN",
    };
    if name in allowed {
        return name;
    }
    upper_name = name.upper();
    if upper_name in allowed {
        return upper_name;
    }
    return "UNKNOWN";
}

def _coerce_int(value: any, fallback: int = 0) -> int {
    if value is None or value == "" {
        return fallback;
    }
    return int(value);
}

def _coerce_bool(value: any, fallback: bool = False) -> bool {
    if value is None or value == "" {
        return fallback;
    }
    if isinstance(value, bool) {
        return bool(value);
    }
    lowered = str(value).lower();
    if lowered in {"true", "1", "yes", "y", "on"} {
        return True;
    }
    if lowered in {"false", "0", "no", "n", "off"} {
        return False;
    }
    return fallback;
}

def _slugify_label(text: str) -> str {
    cleaned = str(text or "").lower();
    output = "";
    for char in cleaned {
        if char.isalnum() {
            output += char;
        } elif char in {"-", "_", "."} {
            output += "_";
        }
    }
    while "__" in output {
        output = output.replace("__", "_");
    }
    return output.strip("_");
}

def _trim_json_fence(text: str) -> str {
    cleaned = str(text or "").strip();
    if cleaned.startswith("```json") {
        cleaned = cleaned.removeprefix("```json").strip();
    } elif cleaned.startswith("```") {
        cleaned = cleaned.removeprefix("```").strip();
    }
    if cleaned.endswith("```") {
        cleaned = cleaned.removesuffix("```").strip();
    }
    return cleaned;
}

def _extract_json_object(text: str) -> dict[str, any] {
    cleaned = _trim_json_fence(text);
    try {
        parsed = json.loads(cleaned);
        if isinstance(parsed, dict) {
            return parsed;
        }
    } except Exception {
    }

    start = cleaned.find("{");
    stop = cleaned.rfind("}");
    if start >= 0 and stop > start {
        snippet = cleaned[start: stop + 1];
        parsed = json.loads(snippet);
        if isinstance(parsed, dict) {
            return parsed;
        }
    }
    raise ValueError("model response did not contain a JSON object");
}

def _shared_run_diagnosis_instruction() -> str {
    lines: list[str] = [];
    lines.append("You are diagnosing a coding-agent trajectory.");
    lines.append("Return JSON only.");
    lines.append("Use only the evidence provided.");
    lines.append("Do not invent missing steps, files, tests, or outcomes.");
    lines.append("Choose the earliest plausible irreversible mistake.");
    lines.append("When the pack shows canonical decision steps, use those 0-based step_idx values in critical_step_idx and evidence_refs.");
    lines.append("Schema:");
    lines.append(
        json.dumps(
            {
                "failure_class": "PREMATURE_COMPLETION|INVALID_PATCH|WRONG_FILE_FOCUS|OSCILLATION_LOOP|TOOL_MISUSE|STALE_CONTEXT_OR_BAD_PLAN|REQUIREMENT_DRIFT|UNKNOWN",
                "critical_step_idx": 0,
                "evidence_refs": [{"step_idx": 0, "artifact": "phase", "quote": "exact quote"}],
                "irreversible_because": "one sentence",
                "memory_rule": "one operational rule",
                "confidence": 0.0,
            },
            indent=2,
        )
    );
    return "\n".join(lines);
}

def _shared_verdict_instruction() -> str {
    lines: list[str] = [];
    lines.append("You are a blinded evaluator comparing two trajectory diagnoses.");
    lines.append("Return JSON only.");
    lines.append("Judge evidence validity, pivot quality, specificity, actionability, and hallucination avoidance.");
    lines.append("Winner must be A, B, or tie.");
    lines.append(
        json.dumps(
            {
                "winner": "A|B|tie",
                "raw_score": 0.0,
                "structured_score": 0.0,
                "evidence_validity_winner": "A|B|tie",
                "pivot_quality_winner": "A|B|tie",
                "specificity_winner": "A|B|tie",
                "actionability_winner": "A|B|tie",
                "hallucination_winner": "A|B|tie",
                "rationale": "short explanation",
            },
            indent=2,
        )
    );
    return "\n".join(lines);
}

def _diagnosis_output_schema() -> dict[str, any] {
    return {
        "type": "object",
        "properties": {
            "failure_class": {
                "type": "string",
                "enum": [
                    "PREMATURE_COMPLETION",
                    "INVALID_PATCH",
                    "WRONG_FILE_FOCUS",
                    "OSCILLATION_LOOP",
                    "TOOL_MISUSE",
                    "STALE_CONTEXT_OR_BAD_PLAN",
                    "REQUIREMENT_DRIFT",
                    "UNKNOWN",
                ],
            },
            "critical_step_idx": {"type": "integer"},
            "evidence_refs": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "step_idx": {"type": "integer"},
                        "artifact": {"type": "string"},
                        "quote": {"type": "string"},
                    },
                    "required": ["step_idx", "artifact", "quote"],
                    "additionalProperties": False,
                },
            },
            "irreversible_because": {"type": "string"},
            "memory_rule": {"type": "string"},
            "confidence": {"type": "number"},
        },
        "required": [
            "failure_class",
            "critical_step_idx",
            "evidence_refs",
            "irreversible_because",
            "memory_rule",
            "confidence",
        ],
        "additionalProperties": False,
    };
}

def _verdict_output_schema() -> dict[str, any] {
    return {
        "type": "object",
        "properties": {
            "winner": {"type": "string", "enum": ["A", "B", "tie"]},
            "raw_score": {"type": "number"},
            "structured_score": {"type": "number"},
            "evidence_validity_winner": {"type": "string", "enum": ["A", "B", "tie"]},
            "pivot_quality_winner": {"type": "string", "enum": ["A", "B", "tie"]},
            "specificity_winner": {"type": "string", "enum": ["A", "B", "tie"]},
            "actionability_winner": {"type": "string", "enum": ["A", "B", "tie"]},
            "hallucination_winner": {"type": "string", "enum": ["A", "B", "tie"]},
            "rationale": {"type": "string"},
        },
        "required": [
            "winner",
            "raw_score",
            "structured_score",
            "evidence_validity_winner",
            "pivot_quality_winner",
            "specificity_winner",
            "actionability_winner",
            "hallucination_winner",
            "rationale",
        ],
        "additionalProperties": False,
    };
}

def _codex_cli_path() -> str {
    configured = str(getenv("TRACEFORGE_CODEX_CLI") or "");
    if configured {
        return configured;
    }
    return configured_codex_cli_path();
}

def _provider_key(provider: str) -> str {
    return configured_provider_key(provider);
}

def _provider_model(provider: str, model: str = "") -> str {
    return configured_provider_model(provider, model);
}

def _resolve_provider(provider: str = "auto", model: str = "") -> dict[str, any] {
    return provider_resolution_summary(provider, model);
}

def _codex_exec_prompt(system_prompt: str, user_prompt: str) -> str {
    lines: list[str] = [];
    lines.append("You are being used as an offline evaluator, not as a coding agent.");
    lines.append("Do not run commands, inspect files, or use tools.");
    lines.append("Answer only from the evidence in this prompt.");
    lines.append("");
    lines.append("Evaluator instructions:");
    lines.append(system_prompt);
    lines.append("");
    lines.append("Evidence:");
    lines.append(user_prompt);
    return "\n".join(lines);
}

def _codex_completion(system_prompt: str, user_prompt: str, model: str, schema: dict[str, any]) -> dict[str, any] {
    codex_path = _codex_cli_path();
    if not codex_path {
        raise RuntimeError("Codex CLI is not available on PATH.");
    }

    temp_root = Path(mkdtemp(prefix="traceforge_codex_eval_"));
    schema_path = temp_root.joinpath("schema.json");
    output_path = temp_root.joinpath("last_message.json");
    schema_path.write_text(json.dumps(schema, indent=2) + "\n", encoding="utf-8");
    prompt_text = _codex_exec_prompt(system_prompt, user_prompt);
    command = [
        codex_path,
        "exec",
        "--skip-git-repo-check",
        "--ephemeral",
        "--dangerously-bypass-approvals-and-sandbox",
        "--color",
        "never",
        "--output-schema",
        str(schema_path),
        "--output-last-message",
        str(output_path),
        "-C",
        str(temp_root),
    ];
    if model {
        command.extend(["-m", model]);
    }
    command.append("-");

    start = perf_counter();
    try {
        result = run(
            command,
            input=prompt_text,
            capture_output=True,
            text=True,
            check=False,
            timeout=300,
        );
        latency_ms = round((perf_counter() - start) * 1000.0, 2);
        if result.returncode != 0 {
            raise RuntimeError(
                "Codex CLI failed: "
                + truncate_text((result.stderr or result.stdout or "").strip(), 1200)
            );
        }
        if not output_path.exists() {
            raise RuntimeError("Codex CLI did not write an output message.");
        }
        text = output_path.read_text(encoding="utf-8").strip();
        completion_tokens = _pack_token_estimate(text);
        prompt_tokens = _pack_token_estimate(prompt_text);
        return {
            "text": text,
            "usage": {
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
                "total_tokens": prompt_tokens + completion_tokens,
            },
            "latency_ms": latency_ms,
            "provider": "codex",
            "model": model,
        };
    } finally {
        rmtree(temp_root, ignore_errors=True);
    }
}

def _http_post_json(url: str, headers: dict[str, str], payload: dict[str, any]) -> dict[str, any] {
    request = Request(
        url=url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    );
    start = perf_counter();
    try {
        response = urlopen(request);
        body_text = response.read().decode("utf-8");
        latency_ms = round((perf_counter() - start) * 1000.0, 2);
        return {
            "status": int(response.status),
            "body": json.loads(body_text),
            "latency_ms": latency_ms,
        };
    } except HTTPError as err {
        body_text = err.read().decode("utf-8");
        raise RuntimeError("HTTP " + str(err.code) + ": " + body_text);
    } except URLError as err {
        raise RuntimeError("Network error: " + str(err.reason));
    }
}

def _openai_completion(system_prompt: str, user_prompt: str, model: str) -> dict[str, any] {
    headers = {
        "Authorization": "Bearer " + _provider_key("openai"),
        "Content-Type": "application/json",
    };
    payload = {
        "model": model,
        "temperature": 0.0,
        "max_completion_tokens": 900,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    };
    response = _http_post_json("https://api.openai.com/v1/chat/completions", headers, payload);
    body = response["body"];
    choice = body.get("choices", [])[0];
    message = choice.get("message", {});
    content = str(message.get("content") or "");
    usage = body.get("usage", {});
    return {
        "text": content,
        "usage": {
            "prompt_tokens": int(usage.get("prompt_tokens") or 0),
            "completion_tokens": int(usage.get("completion_tokens") or 0),
            "total_tokens": int(usage.get("total_tokens") or 0),
        },
        "latency_ms": response["latency_ms"],
        "provider": "openai",
        "model": model,
    };
}

def _anthropic_completion(system_prompt: str, user_prompt: str, model: str) -> dict[str, any] {
    headers = {
        "x-api-key": _provider_key("anthropic"),
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    };
    payload = {
        "model": model,
        "system": system_prompt,
        "temperature": 0.0,
        "max_tokens": 900,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": user_prompt,
                    }
                ],
            }
        ],
    };
    response = _http_post_json("https://api.anthropic.com/v1/messages", headers, payload);
    body = response["body"];
    content_text = "";
    for block in body.get("content", []) {
        if str(block.get("type") or "") == "text" {
            content_text += str(block.get("text") or "");
        }
    }
    usage = body.get("usage", {});
    input_tokens = int(usage.get("input_tokens") or 0);
    output_tokens = int(usage.get("output_tokens") or 0);
    return {
        "text": content_text,
        "usage": {
            "prompt_tokens": input_tokens,
            "completion_tokens": output_tokens,
            "total_tokens": input_tokens + output_tokens,
        },
        "latency_ms": response["latency_ms"],
        "provider": "anthropic",
        "model": model,
    };
}

def _provider_completion(provider: str, model: str, system_prompt: str, user_prompt: str) -> dict[str, any] {
    if provider == "openai" {
        return _openai_completion(system_prompt, user_prompt, model);
    }
    if provider == "anthropic" {
        return _anthropic_completion(system_prompt, user_prompt, model);
    }
    raise RuntimeError("Unsupported provider: " + provider);
}

def _diagnosis_from_json(run_id: str, parsed: dict[str, any], pack_mode: str, prompt_pack: str, provider: str, model: str, latency_ms: float, usage: dict[str, any]) -> dict[str, any] {
    evidence = [];
    raw_evidence = parsed.get("evidence_refs") or parsed.get("evidence") or [];
    if isinstance(raw_evidence, list) {
        for item in raw_evidence {
            if not isinstance(item, dict) {
                continue;
            }
            evidence.append(
                {
                    "step_idx": _coerce_int(item.get("step_idx"), -1),
                    "artifact": str(item.get("artifact") or ""),
                    "quote": str(item.get("quote") or ""),
                }
            );
        }
    }
    return {
        "run_id": run_id,
        "mode": pack_mode,
        "failure_class": _normalize_failure_class(str(parsed.get("failure_class") or "UNKNOWN")),
        "critical_step_idx": _coerce_int(parsed.get("critical_step_idx"), -1),
        "irreversible_because": str(parsed.get("irreversible_because") or ""),
        "evidence": evidence,
        "evidence_refs": evidence,
        "confidence": float(parsed.get("confidence") or 0.0),
        "memory_rule": str(parsed.get("memory_rule") or ""),
        "llm_used": True,
        "status": "provider_api_diagnosis",
        "prompt_pack": prompt_pack,
        "pack_token_estimate": _pack_token_estimate(prompt_pack),
        "specificity": _specificity_label(len(evidence), _coerce_int(parsed.get("critical_step_idx"), -1), pack_mode),
        "provider": provider,
        "model": model,
        "latency_ms": latency_ms,
        "usage": usage,
        "raw_model_text": json.dumps(parsed, indent=2),
    };
}

def _verdict_from_json(parsed: dict[str, any], assignment: dict[str, str], provider: str, model: str, verifier_pack: str, latency_ms: float, usage: dict[str, any]) -> dict[str, any] {
    winner = str(parsed.get("winner") or "tie").lower();
    if winner == "a" {
        winner = assignment["A"];
    } elif winner == "b" {
        winner = assignment["B"];
    } elif winner not in {"baseline", "structured", "tie"} {
        winner = "tie";
    }
    blinded_winner = "tie";
    if winner == "baseline" {
        blinded_winner = "A" if assignment["A"] == "baseline" else "B";
    } elif winner == "structured" {
        blinded_winner = "A" if assignment["A"] == "structured" else "B";
    }
    return {
        "winner": winner,
        "blinded_winner": blinded_winner,
        "raw_score": float(parsed.get("raw_score") or 0.0),
        "structured_score": float(parsed.get("structured_score") or 0.0),
        "evidence_validity_winner": str(parsed.get("evidence_validity_winner") or "tie"),
        "pivot_quality_winner": str(parsed.get("pivot_quality_winner") or "tie"),
        "specificity_winner": str(parsed.get("specificity_winner") or "tie"),
        "actionability_winner": str(parsed.get("actionability_winner") or "tie"),
        "hallucination_winner": str(parsed.get("hallucination_winner") or "tie"),
        "rationale": str(parsed.get("rationale") or ""),
        "llm_used": True,
        "status": "provider_api_verdict",
        "verifier_pack": verifier_pack,
        "provider": provider,
        "model": model,
        "latency_ms": latency_ms,
        "usage": usage,
        "raw_model_text": json.dumps(parsed, indent=2),
    };
}

def _raw_turn_lines(parsed_run: any, max_turns: int = 120) -> list[str] {
    lines: list[str] = [];
    shown_turns = parsed_run.turns[: max_turns];
    for turn in shown_turns {
        if not turn.content and not turn.role {
            continue;
        }
        lines.append(
            "Turn "
            + str(turn.index)
            + " ["
            + str(turn.role).upper()
            + "]\n"
            + str(turn.content),
        );
    }
    if len(parsed_run.turns) > len(shown_turns) {
        lines.append(
            "... "
            + str(len(parsed_run.turns) - len(shown_turns))
            + " additional turns omitted from this raw prompt pack."
        );
    }
    return lines;
}

def _decision_step_lines(parsed_run: any, max_steps: int = 80) -> list[str] {
    lines: list[str] = [];
    shown_steps = parsed_run.steps[: max_steps];
    for step in shown_steps {
        lines.append(
            "Step "
            + str(step.index)
            + " ["
            + str(step.phase)
            + "]\n"
            + step_text(step),
        );
    }
    if len(parsed_run.steps) > len(shown_steps) {
        lines.append(
            "... "
            + str(len(parsed_run.steps) - len(shown_steps))
            + " additional decision steps omitted from this raw prompt pack."
        );
    }
    return lines;
}

def _step_window_lines(parsed_run: any, center_idx: int, radius: int = 1) -> list[str] {
    if center_idx < 0 or center_idx >= len(parsed_run.steps) {
        return [];
    }
    lines: list[str] = [];
    start = max(center_idx - radius, 0);
    stop = min(center_idx + radius, len(parsed_run.steps) - 1);
    for index = start while index<=stop with index+=1 {
        lines.append(
            "Step "
            + str(index)
            + " ["
            + str(parsed_run.steps[index].phase)
            + "]\n"
            + step_text(parsed_run.steps[index]),
        );
    }
    return lines;
}

def _exact_evidence_refs(parsed_run: any, critical_step_idx: int, limit: int = 3) -> list[dict[str, any]] {
    evidence: list[dict[str, any]] = [];
    if critical_step_idx < 0 {
        return evidence;
    }
    start = max(critical_step_idx - 1, 0);
    stop = min(critical_step_idx + 1, len(parsed_run.steps) - 1);
    for index = start while index<=stop with index+=1 {
        if len(evidence) >= limit {
            break;
        }
        evidence.append(
            {
                "step_idx": index,
                "artifact": str(parsed_run.steps[index].phase),
                "quote": truncate_text(step_text(parsed_run.steps[index]), 500),
            }
        );
    }
    return evidence;
}

def _first_interesting_step(parsed_run: any) -> int {
    for (index, step) in enumerate(parsed_run.steps) {
        lower = step_text(step).lower();
        if "traceback" in lower or "error" in lower or "exception" in lower or "failed" in lower {
            return index;
        }
    }
    for (index, step) in enumerate(parsed_run.steps) {
        lower = step_text(step).lower();
        if "submit" in lower or "final" in lower {
            return index;
        }
    }
    if len(parsed_run.steps) > 0 {
        return 0;
    }
    return -1;
}

def _raw_baseline_pack(parsed_run: any, run_view: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("Evidence mode: raw_transcript");
    lines.append("Run ID: " + str(run_view["run_id"]));
    lines.append("Task title: " + str(run_view["task_title"]));
    lines.append("Source path: " + str(run_view["source_path"]));
    lines.append("Transcript:");
    lines.extend(_raw_turn_lines(parsed_run));
    lines.append("Canonical decision step index map (use these 0-based step_idx values in the output JSON):");
    lines.extend(_decision_step_lines(parsed_run));
    return truncate_text("\n\n".join(lines), 14000);
}

def _structured_retrieval_pack(parsed_run: any, run_view: dict[str, any]) -> str {
    fingerprint = compute_run_fingerprint(parsed_run);
    critical = localize_critical_step(parsed_run, fingerprint);
    candidate_scores = sorted(
        critical["candidate_scores"],
        key=lambda (item: any) -> any { (-float(item["score"]), int(item["step_idx"])) },
    );

    lines: list[str] = [];
    lines.append("Evidence mode: traceforge_retrieval");
    lines.append("Run ID: " + str(run_view["run_id"]));
    lines.append("Task title: " + str(run_view["task_title"]));
    lines.append("Primary deterministic family: " + str(run_view["primary_failure"]));
    lines.append("Graph-linked clusters: " + str(run_view["artifacts"]["cluster_ids"]));
    lines.append("Top files: " + str(run_view["artifacts"]["fingerprint"].get("top_files", [])));
    lines.append("Top errors: " + str(run_view["artifacts"]["fingerprint"].get("top_error_keywords", [])));
    lines.append("Top tests: " + str(run_view["artifacts"]["fingerprint"].get("top_test_names", [])));
    lines.append("Retrieved evidence windows:");

    shown_candidates = candidate_scores[:3];
    for candidate in shown_candidates {
        lines.append(
            "Candidate step "
            + str(candidate["step_idx"])
            + " score "
            + str(candidate["score"])
        );
        for window_line in _step_window_lines(parsed_run, int(candidate["step_idx"])) {
            lines.append(window_line);
        }
    }

    if len(shown_candidates) == 0 and len(parsed_run.steps) > 0 {
        for window_line in _step_window_lines(parsed_run, 0) {
            lines.append(window_line);
        }
    }

    lines.append("Exact final-step context:");
    if len(parsed_run.steps) > 0 {
        for window_line in _step_window_lines(parsed_run, len(parsed_run.steps) - 1, 0) {
            lines.append(window_line);
        }
    } else {
        lines.append("No agent decision steps were recorded.");
    }

    return truncate_text("\n\n".join(lines), 12000);
}

def _diagnosis_to_dict(
    run_id: str,
    diagnosis: any,
    pack_mode: str,
    prompt_pack: str,
    llm_used: bool,
    status: str,
) -> dict[str, any] {
    failure_class = _normalize_failure_class(failure_class_name(diagnosis.failure_class));
    evidence = [];
    for item in diagnosis.evidence {
        evidence.append(
            {
                "step_idx": int(item.step_idx),
                "artifact": str(item.artifact),
                "quote": str(item.quote),
            }
        );
    }
    rule_lines = cluster_rule_lines(failure_class);
    chosen_rule = "";
    if len(rule_lines) > 0 {
        chosen_rule = rule_lines[0];
    }
    return {
        "run_id": run_id,
        "mode": pack_mode,
        "failure_class": failure_class,
        "critical_step_idx": int(diagnosis.critical_step_idx),
        "irreversible_because": str(diagnosis.irreversible_because),
        "evidence": evidence,
        "evidence_refs": evidence,
        "confidence": float(diagnosis.confidence),
        "memory_rule": chosen_rule,
        "llm_used": llm_used,
        "status": status,
        "prompt_pack": prompt_pack,
        "pack_token_estimate": _pack_token_estimate(prompt_pack),
        "specificity": _specificity_label(len(evidence), int(diagnosis.critical_step_idx), pack_mode),
    };
}

def _fallback_raw_diagnosis(run_view: dict[str, any], parsed_run: any, prompt_pack: str) -> dict[str, any] {
    raw_step = _first_interesting_step(parsed_run);
    failure_class = _normalize_failure_class(str(run_view.get("primary_failure") or "UNKNOWN"));
    if len(parsed_run.steps) == 0 {
        failure_class = "UNKNOWN";
        raw_step = -1;
    }
    evidence = [];
    if raw_step >= 0 {
        evidence.append(
            {
                "step_idx": raw_step,
                "artifact": str(parsed_run.steps[raw_step].phase),
                "quote": truncate_text(step_text(parsed_run.steps[raw_step]), 500),
            }
        );
    } else {
        evidence.append(
            {
                "step_idx": -1,
                "artifact": "run_status",
                "quote": str(run_view["summary"]),
            }
        );
    }
    rule_lines = cluster_rule_lines(failure_class);
    chosen_rule = "";
    if len(rule_lines) > 0 {
        chosen_rule = rule_lines[0];
    }
    return {
        "run_id": run_view["run_id"],
        "mode": "raw_transcript_prompt",
        "failure_class": failure_class,
        "critical_step_idx": raw_step,
        "irreversible_because": diagnosis_reason(failure_class),
        "evidence": evidence,
        "evidence_refs": evidence,
        "confidence": 0.42 if raw_step >= 0 else 0.18,
        "memory_rule": chosen_rule,
        "llm_used": False,
        "status": "deterministic_raw_diagnosis",
        "prompt_pack": prompt_pack,
        "pack_token_estimate": _pack_token_estimate(prompt_pack),
        "specificity": _specificity_label(len(evidence), raw_step, "raw_transcript_prompt"),
    };
}

def _fallback_structured_diagnosis(run_view: dict[str, any], parsed_run: any, prompt_pack: str) -> dict[str, any] {
    failure_class = _normalize_failure_class(str(run_view.get("primary_failure") or dominant_failure_label(run_view["artifacts"]["fingerprint"])));
    critical_step_idx = int(run_view["critical_step_idx"]);
    evidence = _exact_evidence_refs(parsed_run, critical_step_idx);
    if len(evidence) == 0 {
        evidence.append(
            {
                "step_idx": critical_step_idx,
                "artifact": "summary",
                "quote": str(run_view["summary"]),
            }
        );
    }
    rule_lines = cluster_rule_lines(failure_class);
    chosen_rule = "";
    if len(rule_lines) > 0 {
        chosen_rule = rule_lines[0];
    }
    return {
        "run_id": run_view["run_id"],
        "mode": "traceforge_retrieval_prompt",
        "failure_class": failure_class,
        "critical_step_idx": critical_step_idx,
        "irreversible_because": diagnosis_reason(failure_class),
        "evidence": evidence,
        "evidence_refs": evidence,
        "confidence": 0.7 if critical_step_idx >= 0 else 0.25,
        "memory_rule": chosen_rule,
        "llm_used": False,
        "status": "deterministic_structured_diagnosis",
        "prompt_pack": prompt_pack,
        "pack_token_estimate": _pack_token_estimate(prompt_pack),
        "specificity": _specificity_label(len(evidence), critical_step_idx, "traceforge_retrieval_prompt"),
    };
}

def _provider_diagnosis(prompt_pack: str, run_view: dict[str, any], pack_mode: str, provider: str = "auto", model: str = "") -> dict[str, any] {
    resolved = _resolve_provider(provider, model);
    if not resolved["available"] {
        raise RuntimeError("No configured model provider is available for rigorous evaluation.");
    }
    response = {};
    if str(resolved["provider"]) == "codex" {
        response = _codex_completion(
            _shared_run_diagnosis_instruction(),
            prompt_pack,
            str(resolved["model"]),
            _diagnosis_output_schema(),
        );
    } else {
        response = _provider_completion(
            str(resolved["provider"]),
            str(resolved["model"]),
            _shared_run_diagnosis_instruction(),
            prompt_pack,
        );
    }
    parsed = _extract_json_object(str(response["text"]));
    return _diagnosis_from_json(
        str(run_view["run_id"]),
        parsed,
        pack_mode,
        prompt_pack,
        str(response["provider"]),
        str(response["model"]),
        float(response["latency_ms"]),
        response["usage"],
    );
}

def _blind_assignment(run_id: str, batch_id: str) -> dict[str, str] {
    digest = hash_text(batch_id + ":" + run_id);
    even = int(digest[0], 16) % 2 == 0;
    if even {
        return {
            "A": "baseline",
            "B": "structured",
        };
    }
    return {
        "A": "structured",
        "B": "baseline",
    };
}

def _blinded_arms(baseline: dict[str, any], structured: dict[str, any], assignment: dict[str, str]) -> dict[str, any] {
    arm_a = baseline;
    arm_b = structured;
    if assignment["A"] == "structured" {
        arm_a = structured;
        arm_b = baseline;
    }
    return {
        "assignment": assignment,
        "arm_a": {
            "failure_class": arm_a["failure_class"],
            "critical_step_idx": arm_a["critical_step_idx"],
            "irreversible_because": arm_a["irreversible_because"],
            "evidence_refs": arm_a["evidence_refs"],
            "memory_rule": arm_a["memory_rule"],
            "confidence": arm_a["confidence"],
        },
        "arm_b": {
            "failure_class": arm_b["failure_class"],
            "critical_step_idx": arm_b["critical_step_idx"],
            "irreversible_because": arm_b["irreversible_because"],
            "evidence_refs": arm_b["evidence_refs"],
            "memory_rule": arm_b["memory_rule"],
            "confidence": arm_b["confidence"],
        },
    };
}

def _deterministic_verdict(
    run_view: dict[str, any],
    baseline: dict[str, any],
    structured: dict[str, any],
    assignment: dict[str, str],
) -> dict[str, any] {
    raw_score = 0.0;
    structured_score = 0.0;

    if baseline["critical_step_idx"] >= 0 {
        raw_score += 1.0;
    }
    if structured["critical_step_idx"] >= 0 {
        structured_score += 1.0;
    }
    raw_score += min(len(baseline["evidence_refs"]) * 0.2, 0.6);
    structured_score += min(len(structured["evidence_refs"]) * 0.2, 0.6);
    if baseline["failure_class"] != "UNKNOWN" {
        raw_score += 0.4;
    }
    if structured["failure_class"] != "UNKNOWN" {
        structured_score += 0.4;
    }
    if len(run_view["artifacts"]["cluster_ids"]) > 0 {
        structured_score += 0.3;
    }

    winner = "tie";
    if structured_score > raw_score {
        winner = "structured";
    } elif raw_score > structured_score {
        winner = "baseline";
    }

    blinded_winner = "tie";
    if winner == "baseline" {
        blinded_winner = "A" if assignment["A"] == "baseline" else "B";
    } elif winner == "structured" {
        blinded_winner = "A" if assignment["A"] == "structured" else "B";
    }

    return {
        "winner": winner,
        "blinded_winner": blinded_winner,
        "raw_score": round(raw_score, 4),
        "structured_score": round(structured_score, 4),
        "evidence_validity_winner": "structured" if len(structured["evidence_refs"]) >= len(baseline["evidence_refs"]) else "baseline",
        "pivot_quality_winner": "structured" if structured["critical_step_idx"] >= baseline["critical_step_idx"] else "baseline",
        "specificity_winner": "structured" if structured["specificity"] != baseline["specificity"] else "tie",
        "actionability_winner": "structured" if structured["memory_rule"] else ("baseline" if baseline["memory_rule"] else "tie"),
        "hallucination_winner": "structured" if baseline["critical_step_idx"] < 0 and structured["critical_step_idx"] >= 0 else "tie",
        "rationale": "Deterministic proxy verdict prefers the arm with stronger evidence refs, a localized pivot step, and cluster-grounded context.",
        "llm_used": False,
        "status": "deterministic_proxy_verdict",
    };
}

def _verifier_pack(run_view: dict[str, any], blinded: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("TraceForge blinded comparison verifier pack");
    lines.append("Judge which arm is better on evidence validity, pivot quality, specificity, actionability, and hallucination avoidance.");
    lines.append("Return a typed ComparisonVerdict. Winner must be A, B, or tie.");
    lines.append("Run summary: " + str(run_view["summary"]));
    lines.append("Arm A:");
    lines.append(json.dumps(blinded["arm_a"]));
    lines.append("Arm B:");
    lines.append(json.dumps(blinded["arm_b"]));
    return truncate_text("\n".join(lines), 12000);
}

def _provider_verdict(run_view: dict[str, any], blinded: dict[str, any], assignment: dict[str, str], provider: str = "auto", model: str = "") -> dict[str, any] {
    verifier_pack = _verifier_pack(run_view, blinded);
    resolved = _resolve_provider(provider, model);
    if not resolved["available"] {
        raise RuntimeError("No configured model provider is available for rigorous evaluation.");
    }
    response = {};
    if str(resolved["provider"]) == "codex" {
        response = _codex_completion(
            _shared_verdict_instruction(),
            verifier_pack,
            str(resolved["model"]),
            _verdict_output_schema(),
        );
    } else {
        response = _provider_completion(
            str(resolved["provider"]),
            str(resolved["model"]),
            _shared_verdict_instruction(),
            verifier_pack,
        );
    }
    parsed = _extract_json_object(str(response["text"]));
    return _verdict_from_json(
        parsed,
        assignment,
        str(response["provider"]),
        str(response["model"]),
        verifier_pack,
        float(response["latency_ms"]),
        response["usage"],
    );
}

def _run_group(run_item: dict[str, any]) -> str {
    if int(run_item.get("step_count") or 0) <= 0 {
        return "startup";
    }
    return "substantive";
}

def _selection_bucket(run_item: dict[str, any]) -> str {
    cluster_id = str(run_item.get("cluster_id") or "");
    if cluster_id {
        return "cluster:" + cluster_id;
    }
    return "family:" + str(run_item.get("primary_failure") or "UNKNOWN");
}

def _round_robin_select(run_items: list[dict[str, any]], limit: int, use_cluster_bucket: bool = True) -> list[dict[str, any]] {
    limit = _coerce_int(limit, 0);
    if limit <= 0 {
        return [];
    }
    buckets: dict[str, list[dict[str, any]]] = {};
    for run_item in sorted(
        run_items,
        key=lambda (item: any) -> any { (
            str(item.get("primary_failure") or "UNKNOWN"),
            -int(item.get("step_count") or 0),
            str(item.get("run_id") or "")
        ) },
    ) {
        bucket_name = "family:" + str(run_item.get("primary_failure") or "UNKNOWN");
        if use_cluster_bucket {
            bucket_name = _selection_bucket(run_item);
        }
        if bucket_name not in buckets {
            buckets[bucket_name] = [];
        }
        buckets[bucket_name].append(run_item);
    }

    selected: list[dict[str, any]] = [];
    bucket_names = sorted(buckets.keys());
    while len(selected) < limit {
        added_in_round = False;
        for bucket_name in bucket_names {
            bucket_items = buckets.get(bucket_name, []);
            if len(bucket_items) == 0 {
                continue;
            }
            selected.append(bucket_items.pop(0));
            added_in_round = True;
            if len(selected) >= limit {
                break;
            }
        }
        if not added_in_round {
            break;
        }
    }
    return selected;
}

def _selected_eval_runs(
    overview: dict[str, any],
    substantive_limit: int = 20,
    startup_limit: int = 5,
    explicit_run_ids: list[str] = [],
) -> dict[str, any] {
    substantive_limit = _coerce_int(substantive_limit, 20);
    startup_limit = _coerce_int(startup_limit, 5);
    by_run_id: dict[str, dict[str, any]] = {};
    for run_item in overview["runs"] {
        by_run_id[str(run_item["run_id"])] = run_item;
    }

    if len(explicit_run_ids) > 0 {
        selected_explicit: list[dict[str, any]] = [];
        for run_id in explicit_run_ids {
            run_item = by_run_id.get(str(run_id));
            if run_item is not None {
                selected_explicit.append(run_item);
            }
        }
        return {
            "selected": selected_explicit,
            "substantive": [item for item in selected_explicit if _run_group(item) == "substantive"],
            "startup": [item for item in selected_explicit if _run_group(item) == "startup"],
        };
    }

    substantive_runs: list[dict[str, any]] = [];
    startup_runs: list[dict[str, any]] = [];
    for run_item in overview["runs"] {
        if _run_group(run_item) == "startup" {
            startup_runs.append(run_item);
        } else {
            substantive_runs.append(run_item);
        }
    }

    selected_substantive = _round_robin_select(substantive_runs, substantive_limit, True);
    selected_startup = _round_robin_select(startup_runs, startup_limit, False);
    selected = selected_substantive + selected_startup;
    return {
        "selected": selected,
        "substantive": selected_substantive,
        "startup": selected_startup,
    };
}

def _evaluation_export_stem(batch_id: str, provider: str = "auto", model: str = "", resolved: dict[str, any] | None = None) -> str {
    requested_provider = str(provider or "auto").lower();
    requested_model = str(model or "");
    if requested_provider == "auto" and not requested_model {
        if resolved is None or (not resolved["available"] and not str(resolved["provider"] or "")) {
            return batch_id;
        }
    }

    label_provider = requested_provider;
    if label_provider == "auto" and resolved is not None and str(resolved["provider"] or "") {
        label_provider = str(resolved["provider"]);
    }
    if not label_provider or label_provider == "auto" {
        return batch_id;
    }

    label_model = requested_model;
    if not label_model and resolved is not None and str(resolved["model"] or "") {
        label_model = str(resolved["model"]);
    }
    stem = batch_id + "_" + _slugify_label(label_provider);
    if label_model {
        stem += "_" + _slugify_label(label_model);
    }
    return stem;
}

def _run_item_detail(root_node: any, batch_id: str, run_item: dict[str, any], field_name: str) -> str {
    direct_value = str(run_item.get(field_name) or "");
    if direct_value {
        return direct_value;
    }
    run_view = run_view_summary(root_node, str(run_item.get("run_id") or ""), batch_id);
    return str(run_view.get(field_name) or "");
}

def _baseline_blind_spots(baseline: dict[str, any]) -> list[str] {
    blind_spots = [
        "The baseline sees raw trajectory text only and gets no graph cluster context.",
        "The baseline does not get pre-ranked critical-step candidates.",
    ];
    if baseline["critical_step_idx"] < 0 {
        blind_spots.append("The baseline did not localize a concrete pivot step.");
    }
    return blind_spots;
}

def _structured_support_points(run_view: dict[str, any], structured: dict[str, any]) -> list[str] {
    points: list[str] = [];
    points.append("Retrieved exact evidence refs: " + str(len(structured["evidence_refs"])) + ".");
    if structured["critical_step_idx"] >= 0 {
        points.append("Critical step localized at step " + str(structured["critical_step_idx"]) + ".");
    }
    if run_view["artifacts"]["fingerprint"].get("top_files", []) {
        points.append("Top files: " + str(run_view["artifacts"]["fingerprint"].get("top_files", [])[:3]) + ".");
    }
    if len(run_view["artifacts"]["cluster_ids"]) > 0 {
        points.append("Cluster context: " + str(run_view["artifacts"]["cluster_ids"][:2]) + ".");
    }
    if structured["memory_rule"] {
        points.append("Operational memory rule synthesized: " + structured["memory_rule"]);
    }
    return points;
}

def _timeline_from_parsed(parsed_run: any) -> list[dict[str, any]] {
    timeline: list[dict[str, any]] = [];
    seen_hashes: set[str] = set();
    for step in parsed_run.steps {
        repeated = step.content_hash in seen_hashes;
        seen_hashes.add(step.content_hash);
        timeline.append(
            {
                "idx": step.index,
                "kind": step.kind,
                "phase": step.phase,
                "excerpt": step.excerpt,
                "touched_files": list(step.touched_files),
                "has_patch": bool(step.patch_text),
                "has_test": bool(step.test_text),
                "has_error": bool(step.error_text),
                "repeated": repeated,
            }
        );
    }
    return timeline;
}

def _critical_window_from_timeline(timeline: list[dict[str, any]], critical_step_idx: int, radius: int = 1) -> list[dict[str, any]] {
    if critical_step_idx < 0 {
        return [];
    }
    start = max(critical_step_idx - radius, 0);
    stop = min(critical_step_idx + radius, len(timeline) - 1);
    window: list[dict[str, any]] = [];
    for index = start while index<=stop with index+=1 {
        window.append(timeline[index]);
    }
    return window;
}

def _lightweight_run_view(batch_id: str, run_item: dict[str, any], parsed_run: any) -> dict[str, any] {
    fingerprint = compute_run_fingerprint(parsed_run);
    timeline = _timeline_from_parsed(parsed_run);
    critical = localize_critical_step(parsed_run, fingerprint);
    primary_failure = str(run_item.get("primary_failure") or dominant_failure_label(fingerprint));
    cluster_ids: list[str] = [];
    if str(run_item.get("cluster_id") or "") {
        cluster_ids.append(str(run_item["cluster_id"]));
    }
    return {
        "run_id": str(run_item.get("run_id") or parsed_run.run_id),
        "batch_id": batch_id,
        "task_title": str(run_item.get("task_title") or parsed_run.task_title or ""),
        "source_path": str(run_item.get("source_path") or parsed_run.source_path),
        "summary": str(run_item.get("summary") or ""),
        "primary_failure": primary_failure,
        "critical_step_idx": int(critical["critical_step_idx"]),
        "critical_evidence_window": _critical_window_from_timeline(timeline, int(critical["critical_step_idx"])),
        "timeline": timeline,
        "artifacts": {
            "turn_count": len(parsed_run.turns),
            "metadata": dict(parsed_run.metadata),
            "fingerprint": dict(fingerprint),
            "graph_preview": {
                "status": "eval_lightweight",
            },
            "failure_hypotheses": [],
            "cluster_ids": cluster_ids,
        },
        "status": "eval_lightweight",
    };
}

def _compare_from_run_view(
    run_id: str,
    target_batch_id: str,
    run_view: dict[str, any],
    parsed_run: any,
    provider: str = "auto",
    model: str = "",
) -> dict[str, any] {
    raw_pack = _raw_baseline_pack(parsed_run, run_view);
    structured_pack = _structured_retrieval_pack(parsed_run, run_view);
    resolved = _resolve_provider(provider, model);

    baseline = _fallback_raw_diagnosis(run_view, parsed_run, raw_pack);
    structured = _fallback_structured_diagnosis(run_view, parsed_run, structured_pack);

    if resolved["available"] {
        try {
            baseline = _provider_diagnosis(
                raw_pack,
                run_view,
                "raw_transcript_prompt",
                str(resolved["provider"]),
                str(resolved["model"]),
            );
        } except Exception as err {
            baseline["llm_error"] = str(err);
        }
        try {
            structured = _provider_diagnosis(
                structured_pack,
                run_view,
                "traceforge_retrieval_prompt",
                str(resolved["provider"]),
                str(resolved["model"]),
            );
        } except Exception as err {
            structured["llm_error"] = str(err);
        }
    }

    assignment = _blind_assignment(run_id, target_batch_id or run_id);
    blinded = _blinded_arms(baseline, structured, assignment);

    verdict = _deterministic_verdict(run_view, baseline, structured, assignment);
    comparison_mode = "deterministic_proxy";
    if resolved["available"] {
        try {
            verdict = _provider_verdict(
                run_view,
                blinded,
                assignment,
                str(resolved["provider"]),
                str(resolved["model"]),
            );
            comparison_mode = str(resolved["provider"]) + "_same_model_blinded";
        } except Exception as err {
            verdict["llm_error"] = str(err);
        }
    }

    why_better = "Structured retrieval narrows the search to exact evidence spans, adds cluster context, and still returns the same diagnosis schema as the raw baseline.";
    if verdict["winner"] == "baseline" {
        why_better = "The raw transcript arm won this case under the current verifier rubric.";
    } elif verdict["winner"] == "tie" {
        why_better = "Neither arm separated clearly under the current verifier rubric.";
    }

    return {
        "run_id": run_id,
        "batch_id": target_batch_id,
        "run_group": _run_group(
            {
                "step_count": len(run_view["timeline"]),
            }
        ),
        "step_count": len(run_view["timeline"]),
        "provider": str(resolved["provider"] or ""),
        "model": str(resolved["model"] or ""),
        "provider_available": bool(resolved["available"]),
        "comparison_mode": comparison_mode,
        "baseline": {
            "mode": baseline["mode"],
            "diagnosis": baseline["irreversible_because"],
            "compressed_trajectory": raw_pack,
            "raw_packet": raw_pack,
            "failure_class": baseline["failure_class"],
            "critical_step_idx": baseline["critical_step_idx"],
            "evidence_refs": baseline["evidence_refs"],
            "memory_rule": baseline["memory_rule"],
            "specificity": baseline["specificity"],
            "blind_spots": _baseline_blind_spots(baseline),
            "pack_token_estimate": baseline["pack_token_estimate"],
            "llm_used": baseline["llm_used"],
            "status": baseline["status"],
        },
        "structured": {
            "mode": structured["mode"],
            "failure_class": structured["failure_class"],
            "critical_step_idx": structured["critical_step_idx"],
            "diagnosis": structured["irreversible_because"],
            "evidence_window": run_view["critical_evidence_window"],
            "evidence_refs": structured["evidence_refs"],
            "memory_rule": structured["memory_rule"],
            "support_points": _structured_support_points(run_view, structured),
            "specificity": structured["specificity"],
            "pack_token_estimate": structured["pack_token_estimate"],
            "why_better": why_better,
            "llm_used": structured["llm_used"],
            "status": structured["status"],
            "prompt_pack": structured_pack,
        },
        "verifier": verdict,
        "blinded": blinded,
        "delta": {
            "critical_step_localized": structured["critical_step_idx"] >= 0,
            "cluster_context_added": len(run_view["artifacts"]["cluster_ids"]) > 0,
            "artifact_context_added": len(run_view["artifacts"]["fingerprint"].get("top_files", [])) > 0,
            "baseline_pack_token_estimate": baseline["pack_token_estimate"],
            "structured_pack_token_estimate": structured["pack_token_estimate"],
        },
        "status": "comparison_ready",
    };
}

def compare_run_harness_summary(
    root_node: any,
    run_id: str,
    batch_id: str = "",
    provider: str = "auto",
    model: str = "",
) -> dict[str, any] {
    run_view = run_view_summary(root_node, run_id, batch_id);
    if run_view["status"] == "stub" {
        return {
            "run_id": run_id,
            "status": "missing",
            "message": "Run was not found.",
        };
    }

    target_batch_id = batch_id;
    if not target_batch_id and len(run_view["artifacts"]["cluster_ids"]) > 0 {
        target_batch_id = str(run_view["artifacts"]["cluster_ids"][0]).split(":")[0];
    }
    parsed_run = parse_run(run_view["source_path"], run_id);
    return _compare_from_run_view(run_id, target_batch_id, run_view, parsed_run, provider, model);
}

def pack_run_summary(
    root_node: any,
    run_id: str,
    batch_id: str = "",
    mode: str = "structured",
) -> dict[str, any] {
    run_view = run_view_summary(root_node, run_id, batch_id);
    if run_view["status"] == "stub" {
        return {
            "run_id": run_id,
            "status": "missing",
            "message": "Run was not found.",
        };
    }

    target_batch_id = batch_id;
    if not target_batch_id and len(run_view["artifacts"]["cluster_ids"]) > 0 {
        target_batch_id = str(run_view["artifacts"]["cluster_ids"][0]).split(":")[0];
    }

    parsed_run = parse_run(run_view["source_path"], run_id);
    requested_mode = str(mode or "structured").lower();
    pack_text = "";
    pack_mode = "structured";
    prompt_mode = "traceforge_retrieval_prompt";
    if requested_mode == "raw" {
        pack_text = _raw_baseline_pack(parsed_run, run_view);
        pack_mode = "raw";
        prompt_mode = "raw_transcript_prompt";
    } else {
        pack_text = _structured_retrieval_pack(parsed_run, run_view);
    }

    return {
        "run_id": run_id,
        "batch_id": target_batch_id,
        "mode": pack_mode,
        "prompt_mode": prompt_mode,
        "text": pack_text,
        "token_estimate": _pack_token_estimate(pack_text),
        "task_title": str(run_view.get("task_title") or ""),
        "summary": str(run_view.get("summary") or ""),
        "primary_failure": str(run_view.get("primary_failure") or "UNKNOWN"),
        "critical_step_idx": int(run_view.get("critical_step_idx") or -1),
        "cluster_ids": list(run_view["artifacts"].get("cluster_ids", [])),
        "top_files": list(run_view["artifacts"]["fingerprint"].get("top_files", [])),
        "top_errors": list(run_view["artifacts"]["fingerprint"].get("top_error_keywords", [])),
        "top_tests": list(run_view["artifacts"]["fingerprint"].get("top_test_names", [])),
        "status": "pack_ready",
    };
}

def export_blinded_eval_summary(
    root_node: any,
    batch_id: str,
    limit: int = 10,
    substantive_only: bool = True,
    provider: str = "auto",
    model: str = "",
    run_ids: list[str] = [],
) -> dict[str, any] {
    limit = _coerce_int(limit, 10);
    substantive_only = _coerce_bool(substantive_only, True);
    overview = batch_overview_summary(root_node, batch_id);
    if overview["status"] == "missing" {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }

    selected_runs: list[str] = [];
    selected_items: list[dict[str, any]] = [];
    if len(run_ids) > 0 {
        selected_runs = [str(run_id) for run_id in run_ids];
        by_run_id: dict[str, dict[str, any]] = {};
        for run_item in overview["runs"] {
            by_run_id[str(run_item["run_id"])] = run_item;
        }
        for run_id in selected_runs {
            if str(run_id) in by_run_id {
                selected_items.append(by_run_id[str(run_id)]);
            }
        }
    } else {
        selection = _selected_eval_runs(
            overview,
            limit if substantive_only else max(limit - 2, 0),
            0 if substantive_only else min(2, limit),
        );
        selected_items = selection["selected"][: max(limit, 0)];
        selected_runs = [str(run_item["run_id"]) for run_item in selected_items];
        if len(selected_runs) == 0 {
            selected_items = overview["runs"][: max(limit, 0)];
            selected_runs = [str(run_item["run_id"]) for run_item in selected_items];
        }
    }

    resolved = _resolve_provider(provider, model);
    export_stem = _evaluation_export_stem(batch_id, provider, model, resolved);
    comparisons: list[dict[str, any]] = [];
    blind_key: dict[str, any] = {};
    blinded_lines: list[str] = [
        "# TraceForge Blinded Evaluation Sheet",
        "",
        "- Batch ID: `" + batch_id + "`",
        "- Requested provider: `" + str(provider) + "`",
        "- Requested model: `" + str(model or "default") + "`",
        "- Comparison mode: same-model blinded when a provider API key is present, deterministic proxy otherwise",
        "- Selected runs: " + str(len(selected_runs)),
        "",
        "Score each case on evidence validity, pivot quality, specificity, actionability, and hallucination avoidance.",
        "",
    ];

    for run_item in selected_items {
        run_id = str(run_item["run_id"]);
        parsed_run = parse_run(_run_item_detail(root_node, batch_id, run_item, "source_path"), run_id);
        light_run_view = _lightweight_run_view(batch_id, run_item, parsed_run);
        comparison = _compare_from_run_view(run_id, batch_id, light_run_view, parsed_run, provider, model);
        comparisons.append(comparison);
        blind_key[run_id] = comparison["blinded"]["assignment"];

        blinded_lines.append("## Run `" + run_id + "`");
        blinded_lines.append("");
        blinded_lines.append("### Arm A");
        blinded_lines.append("");
        blinded_lines.append("```json");
        blinded_lines.append(json.dumps(comparison["blinded"]["arm_a"], indent=2));
        blinded_lines.append("```");
        blinded_lines.append("");
        blinded_lines.append("### Arm B");
        blinded_lines.append("");
        blinded_lines.append("```json");
        blinded_lines.append(json.dumps(comparison["blinded"]["arm_b"], indent=2));
        blinded_lines.append("```");
        blinded_lines.append("");
        blinded_lines.append("### Rubric");
        blinded_lines.append("- Evidence validity winner: ____");
        blinded_lines.append("- Pivot quality winner: ____");
        blinded_lines.append("- Specificity winner: ____");
        blinded_lines.append("- Actionability winner: ____");
        blinded_lines.append("- Hallucination winner: ____");
        blinded_lines.append("- Overall winner: ____");
        blinded_lines.append("");
    }

    export_dir = Path("exports/evals");
    export_dir.mkdir(parents=True, exist_ok=True);
    blind_md_path = export_dir.joinpath(export_stem + "_blind.md");
    blind_key_path = export_dir.joinpath(export_stem + "_blind_key.json");
    summary_json_path = export_dir.joinpath(export_stem + "_comparison.json");

    blind_md_text = "\n".join(blinded_lines).strip() + "\n";
    blind_md_path.write_text(blind_md_text, encoding="utf-8");
    blind_key_path.write_text(json.dumps(blind_key, indent=2) + "\n", encoding="utf-8");
    summary_json_path.write_text(json.dumps(comparisons, indent=2) + "\n", encoding="utf-8");

    return {
        "batch_id": batch_id,
        "status": "exported",
        "selected_run_count": len(selected_runs),
        "comparison_mode": comparisons[0]["comparison_mode"] if len(comparisons) > 0 else "deterministic_proxy",
        "provider": comparisons[0]["provider"] if len(comparisons) > 0 else "",
        "model": comparisons[0]["model"] if len(comparisons) > 0 else "",
        "blind_sheet_path": str(blind_md_path),
        "blind_key_path": str(blind_key_path),
        "summary_json_path": str(summary_json_path),
        "preview": truncate_text(blind_md_text, 1200),
    };
}

def _gold_template_record(root_node: any, batch_id: str, run_item: dict[str, any]) -> dict[str, any] {
    return {
        "batch_id": batch_id,
        "run_id": str(run_item["run_id"]),
        "group": _run_group(run_item),
        "task_title": _run_item_detail(root_node, batch_id, run_item, "task_title"),
        "source_path": _run_item_detail(root_node, batch_id, run_item, "source_path"),
        "step_count": int(run_item.get("step_count") or 0),
        "annotation_instructions": "Annotate from the raw trajectory and visible run context only. Do not inspect model outputs while labeling.",
        "gold_failure_class": "",
        "gold_critical_step_idx": -1,
        "gold_supporting_steps": [],
        "gold_short_rationale": "",
        "gold_memory_rule_useful": "",
    };
}

def export_gold_annotation_template_summary(
    root_node: any,
    batch_id: str,
    substantive_limit: int = 20,
    startup_limit: int = 5,
) -> dict[str, any] {
    substantive_limit = _coerce_int(substantive_limit, 20);
    startup_limit = _coerce_int(startup_limit, 5);
    overview = batch_overview_summary(root_node, batch_id);
    if overview["status"] == "missing" {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }

    selection = _selected_eval_runs(overview, substantive_limit, startup_limit);
    annotations: list[dict[str, any]] = [];
    markdown_lines: list[str] = [
        "# TraceForge Gold Annotation Worksheet",
        "",
        "- Batch ID: `" + batch_id + "`",
        "- Substantive runs: " + str(len(selection["substantive"])),
        "- Startup runs: " + str(len(selection["startup"])),
        "",
        "Annotate each run from the raw trajectory only.",
        "",
    ];

    for run_item in selection["selected"] {
        record = _gold_template_record(root_node, batch_id, run_item);
        annotations.append(record);
        markdown_lines.append("## Run `" + str(record["run_id"]) + "`");
        markdown_lines.append("");
        markdown_lines.append("- Group: " + str(record["group"]));
        markdown_lines.append("- Task title: " + str(record["task_title"]));
        markdown_lines.append("- Source path: `" + str(record["source_path"]) + "`");
        markdown_lines.append("- Step count: " + str(record["step_count"]));
        markdown_lines.append("- Gold failure class: ____");
        markdown_lines.append("- Gold critical step idx: ____");
        markdown_lines.append("- Gold supporting steps: ____");
        markdown_lines.append("- Gold short rationale: ____");
        markdown_lines.append("- Gold memory rule useful (yes/no): ____");
        markdown_lines.append("");
    }

    payload = {
        "batch_id": batch_id,
        "substantive_limit": substantive_limit,
        "startup_limit": startup_limit,
        "annotations": annotations,
    };
    export_dir = Path("exports/evals");
    export_dir.mkdir(parents=True, exist_ok=True);
    json_path = export_dir.joinpath(batch_id + "_gold_template.json");
    md_path = export_dir.joinpath(batch_id + "_gold_template.md");
    json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8");
    md_text = "\n".join(markdown_lines).strip() + "\n";
    md_path.write_text(md_text, encoding="utf-8");

    return {
        "batch_id": batch_id,
        "status": "exported",
        "substantive_run_count": len(selection["substantive"]),
        "startup_run_count": len(selection["startup"]),
        "selected_run_count": len(selection["selected"]),
        "json_path": str(json_path),
        "markdown_path": str(md_path),
        "preview": truncate_text(md_text, 1200),
    };
}

def _load_gold_annotations(annotation_path: str) -> list[dict[str, any]] {
    payload = json.loads(Path(annotation_path).read_text(encoding="utf-8"));
    if isinstance(payload, dict) and isinstance(payload.get("annotations"), list) {
        return payload["annotations"];
    }
    if isinstance(payload, list) {
        return payload;
    }
    return [];
}

def _gold_annotations_by_run(annotation_path: str) -> dict[str, dict[str, any]] {
    annotation_map: dict[str, dict[str, any]] = {};
    for item in _load_gold_annotations(annotation_path) {
        if not isinstance(item, dict) {
            continue;
        }
        batch_id = str(item.get("batch_id") or "");
        run_id = str(item.get("run_id") or "");
        if not run_id {
            continue;
        }
        annotation_map[batch_id + "::" + run_id] = item;
    }
    return annotation_map;
}

def _arm_score(prediction: dict[str, any], gold: dict[str, any], step_count: int) -> dict[str, any] {
    gold_failure_class = _normalize_failure_class(str(gold.get("gold_failure_class") or "UNKNOWN"));
    gold_step = _coerce_int(gold.get("gold_critical_step_idx"), -1);
    gold_supporting_steps = [];
    for step_idx in gold.get("gold_supporting_steps", []) {
        gold_supporting_steps.append(int(step_idx));
    }
    if len(gold_supporting_steps) == 0 and gold_step >= 0 {
        gold_supporting_steps.append(gold_step);
    }
    useful_rule_expected = str(gold.get("gold_memory_rule_useful") or "").lower() == "yes";

    failure_class_match = bool(gold_failure_class) and prediction["failure_class"] == gold_failure_class;
    critical_step_exact = gold_step >= 0 and int(prediction["critical_step_idx"]) == gold_step;
    critical_step_adjacent = gold_step >= 0 and abs(int(prediction["critical_step_idx"]) - gold_step) <= 1;
    evidence_support_hit = False;
    invalid_evidence_ref = False;
    for evidence in prediction["evidence_refs"] {
        evidence_step = _coerce_int(evidence.get("step_idx"), -1);
        if evidence_step in gold_supporting_steps {
            evidence_support_hit = True;
        }
        if step_count <= 0 {
            if evidence_step >= 0 {
                invalid_evidence_ref = True;
            }
        } elif evidence_step < 0 or evidence_step >= step_count {
            invalid_evidence_ref = True;
        }
    }

    useful_rule_present = bool(str(prediction.get("memory_rule") or "").strip());
    score = 0.0;
    if failure_class_match {
        score += 1.0;
    }
    if critical_step_exact {
        score += 1.0;
    } elif critical_step_adjacent {
        score += 0.5;
    }
    if evidence_support_hit {
        score += 1.0;
    }
    if useful_rule_expected and useful_rule_present {
        score += 0.5;
    }
    if invalid_evidence_ref {
        score -= 1.0;
    }
    return {
        "score": round(score, 4),
        "failure_class_match": failure_class_match,
        "critical_step_exact": critical_step_exact,
        "critical_step_adjacent": critical_step_adjacent,
        "evidence_support_hit": evidence_support_hit,
        "useful_rule_expected": useful_rule_expected,
        "useful_rule_present": useful_rule_present,
        "invalid_evidence_ref": invalid_evidence_ref,
    };
}

def _aggregate_arm_results(rows: list[dict[str, any]], arm_key: str) -> dict[str, any] {
    total = len(rows);
    if total == 0 {
        return {
            "run_count": 0,
            "mean_objective_score": 0.0,
            "failure_class_accuracy": 0.0,
            "critical_step_exact_rate": 0.0,
            "critical_step_adjacent_rate": 0.0,
            "evidence_support_rate": 0.0,
            "useful_rule_coverage": 0.0,
            "invalid_evidence_ref_rate": 0.0,
        };
    }
    score_sum = 0.0;
    failure_matches = 0;
    exact_matches = 0;
    adjacent_matches = 0;
    evidence_hits = 0;
    useful_rule_denominator = 0;
    useful_rule_hits = 0;
    invalid_refs = 0;
    for row in rows {
        result = row[arm_key];
        score_sum += float(result["score"]);
        if result["failure_class_match"] {
            failure_matches += 1;
        }
        if result["critical_step_exact"] {
            exact_matches += 1;
        }
        if result["critical_step_adjacent"] {
            adjacent_matches += 1;
        }
        if result["evidence_support_hit"] {
            evidence_hits += 1;
        }
        if result["useful_rule_expected"] {
            useful_rule_denominator += 1;
            if result["useful_rule_present"] {
                useful_rule_hits += 1;
            }
        }
        if result["invalid_evidence_ref"] {
            invalid_refs += 1;
        }
    }
    return {
        "run_count": total,
        "mean_objective_score": round(score_sum / total, 4),
        "failure_class_accuracy": round(failure_matches / total, 4),
        "critical_step_exact_rate": round(exact_matches / total, 4),
        "critical_step_adjacent_rate": round(adjacent_matches / total, 4),
        "evidence_support_rate": round(evidence_hits / total, 4),
        "useful_rule_coverage": round(useful_rule_hits / useful_rule_denominator, 4) if useful_rule_denominator > 0 else 0.0,
        "invalid_evidence_ref_rate": round(invalid_refs / total, 4),
    };
}

def _score_comparison_payload(comparisons: list[dict[str, any]], annotation_path: str) -> dict[str, any] {
    gold_by_run = _gold_annotations_by_run(annotation_path);
    scored_rows: list[dict[str, any]] = [];
    structured_wins = 0;
    baseline_wins = 0;
    ties = 0;

    for comparison in comparisons {
        run_key = str(comparison.get("batch_id") or "") + "::" + str(comparison["run_id"]);
        gold = gold_by_run.get(run_key);
        if gold is None {
            continue;
        }
        baseline_row = _arm_score(comparison["baseline"], gold, int(comparison.get("step_count") or 0));
        structured_row = _arm_score(comparison["structured"], gold, int(comparison.get("step_count") or 0));
        if float(structured_row["score"]) > float(baseline_row["score"]) {
            structured_wins += 1;
        } elif float(baseline_row["score"]) > float(structured_row["score"]) {
            baseline_wins += 1;
        } else {
            ties += 1;
        }
        scored_rows.append(
            {
                "run_id": comparison["run_id"],
                "batch_id": comparison["batch_id"],
                "group": comparison.get("run_group") or "substantive",
                "gold_failure_class": gold.get("gold_failure_class"),
                "gold_critical_step_idx": gold.get("gold_critical_step_idx"),
                "baseline": baseline_row,
                "structured": structured_row,
                "verifier_winner": comparison["verifier"]["winner"],
            }
        );
    }

    baseline_metrics = _aggregate_arm_results(scored_rows, "baseline");
    structured_metrics = _aggregate_arm_results(scored_rows, "structured");
    return {
        "annotation_path": annotation_path,
        "labeled_run_count": len(scored_rows),
        "pairwise_wins": {
            "baseline": baseline_wins,
            "structured": structured_wins,
            "tie": ties,
        },
        "baseline": baseline_metrics,
        "structured": structured_metrics,
        "uplift": {
            "mean_objective_score_delta": round(structured_metrics["mean_objective_score"] - baseline_metrics["mean_objective_score"], 4),
            "failure_class_accuracy_delta": round(structured_metrics["failure_class_accuracy"] - baseline_metrics["failure_class_accuracy"], 4),
            "critical_step_exact_delta": round(structured_metrics["critical_step_exact_rate"] - baseline_metrics["critical_step_exact_rate"], 4),
            "critical_step_adjacent_delta": round(structured_metrics["critical_step_adjacent_rate"] - baseline_metrics["critical_step_adjacent_rate"], 4),
            "evidence_support_delta": round(structured_metrics["evidence_support_rate"] - baseline_metrics["evidence_support_rate"], 4),
            "useful_rule_coverage_delta": round(structured_metrics["useful_rule_coverage"] - baseline_metrics["useful_rule_coverage"], 4),
            "invalid_evidence_ref_delta": round(structured_metrics["invalid_evidence_ref_rate"] - baseline_metrics["invalid_evidence_ref_rate"], 4),
        },
        "rows": scored_rows,
    };
}

def _rigorous_eval_markdown(
    batch_id: str,
    provider: str,
    model: str,
    comparisons: list[dict[str, any]],
    score_summary: dict[str, any] = {},
) -> str {
    verifier_counts = {
        "baseline": 0,
        "structured": 0,
        "tie": 0,
    };
    baseline_tokens = 0;
    structured_tokens = 0;
    for comparison in comparisons {
        winner = str(comparison["verifier"]["winner"] or "tie");
        if winner not in verifier_counts {
            winner = "tie";
        }
        verifier_counts[winner] += 1;
        baseline_tokens += int(comparison["baseline"]["pack_token_estimate"]);
        structured_tokens += int(comparison["structured"]["pack_token_estimate"]);
    }

    lines: list[str] = [
        "# TraceForge Rigorous Evaluation Summary",
        "",
        "- Batch ID: `" + batch_id + "`",
        "- Provider: `" + str(provider or "deterministic_fallback") + "`",
        "- Model: `" + str(model or "default") + "`",
        "- Compared runs: " + str(len(comparisons)),
        "- Comparison mode: " + (comparisons[0]["comparison_mode"] if len(comparisons) > 0 else "deterministic_proxy"),
        "",
        "## Blinded Verifier Counts",
        "",
        "- Structured wins: " + str(verifier_counts["structured"]),
        "- Raw wins: " + str(verifier_counts["baseline"]),
        "- Ties: " + str(verifier_counts["tie"]),
    ];

    if len(comparisons) > 0 {
        lines.extend([
            "",
            "## Prompt Budget Snapshot",
            "",
            "- Mean raw pack token estimate: " + str(round(baseline_tokens / len(comparisons), 2)),
            "- Mean TraceForge pack token estimate: " + str(round(structured_tokens / len(comparisons), 2)),
        ]);
    }

    if score_summary and int(score_summary.get("labeled_run_count") or 0) > 0 {
        lines.extend([
            "",
            "## Gold-Scored Uplift",
            "",
            "- Labeled runs: " + str(score_summary["labeled_run_count"]),
            "- Pairwise structured wins: " + str(score_summary["pairwise_wins"]["structured"]),
            "- Pairwise raw wins: " + str(score_summary["pairwise_wins"]["baseline"]),
            "- Pairwise ties: " + str(score_summary["pairwise_wins"]["tie"]),
            "",
            "### Objective Metrics",
            "",
            "- Raw failure-class accuracy: " + str(score_summary["baseline"]["failure_class_accuracy"]),
            "- TraceForge failure-class accuracy: " + str(score_summary["structured"]["failure_class_accuracy"]),
            "- Raw critical-step exact rate: " + str(score_summary["baseline"]["critical_step_exact_rate"]),
            "- TraceForge critical-step exact rate: " + str(score_summary["structured"]["critical_step_exact_rate"]),
            "- Raw evidence support rate: " + str(score_summary["baseline"]["evidence_support_rate"]),
            "- TraceForge evidence support rate: " + str(score_summary["structured"]["evidence_support_rate"]),
            "- Objective score delta (TraceForge - Raw): " + str(score_summary["uplift"]["mean_objective_score_delta"]),
        ]);
    }

    return "\n".join(lines).strip() + "\n";
}

def run_rigorous_eval_summary(
    root_node: any,
    batch_id: str,
    provider: str = "auto",
    model: str = "",
    substantive_limit: int = 20,
    startup_limit: int = 5,
    annotation_path: str = "",
) -> dict[str, any] {
    substantive_limit = _coerce_int(substantive_limit, 20);
    startup_limit = _coerce_int(startup_limit, 5);
    overview = batch_overview_summary(root_node, batch_id);
    if overview["status"] == "missing" {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }

    selection = _selected_eval_runs(overview, substantive_limit, startup_limit);
    selected_run_ids = [str(run_item["run_id"]) for run_item in selection["selected"]];
    blinded_export = export_blinded_eval_summary(
        root_node,
        batch_id,
        len(selected_run_ids),
        False,
        provider,
        model,
        selected_run_ids,
    );
    comparisons = json.loads(Path(blinded_export["summary_json_path"]).read_text(encoding="utf-8"));

    score_summary = {};
    score_json_path = "";
    if annotation_path and Path(annotation_path).exists() {
        score_summary = _score_comparison_payload(comparisons, annotation_path);
        score_json_path = str(
            Path("exports/evals").joinpath(
                batch_id
                + "_"
                + _slugify_label(str(blinded_export["provider"] or provider or "deterministic"))
                + "_"
                + _slugify_label(str(blinded_export["model"] or model or "default"))
                + "_gold_score.json"
            )
        );
        Path(score_json_path).write_text(json.dumps(score_summary, indent=2) + "\n", encoding="utf-8");
    }

    export_dir = Path("exports/evals");
    export_dir.mkdir(parents=True, exist_ok=True);
    summary_md_path = export_dir.joinpath(
        batch_id
        + "_"
        + _slugify_label(str(blinded_export["provider"] or provider or "deterministic"))
        + "_"
        + _slugify_label(str(blinded_export["model"] or model or "default"))
        + "_rigorous_eval.md"
    );
    summary_md_text = _rigorous_eval_markdown(
        batch_id,
        str(blinded_export["provider"] or provider),
        str(blinded_export["model"] or model),
        comparisons,
        score_summary,
    );
    summary_md_path.write_text(summary_md_text, encoding="utf-8");

    return {
        "batch_id": batch_id,
        "status": "evaluated",
        "provider": blinded_export["provider"],
        "model": blinded_export["model"],
        "selected_run_count": len(selected_run_ids),
        "substantive_run_count": len(selection["substantive"]),
        "startup_run_count": len(selection["startup"]),
        "comparison_mode": blinded_export["comparison_mode"],
        "blind_sheet_path": blinded_export["blind_sheet_path"],
        "blind_key_path": blinded_export["blind_key_path"],
        "summary_json_path": blinded_export["summary_json_path"],
        "summary_markdown_path": str(summary_md_path),
        "gold_score_path": score_json_path,
        "score_summary": score_summary,
        "preview": truncate_text(summary_md_text, 1200),
    };
}

def score_rigorous_eval_summary(comparison_json_path: str, annotation_path: str) -> dict[str, any] {
    if not Path(comparison_json_path).exists() {
        return {
            "status": "missing",
            "message": "Comparison export was not found.",
            "comparison_json_path": comparison_json_path,
        };
    }
    if not Path(annotation_path).exists() {
        return {
            "status": "missing",
            "message": "Annotation file was not found.",
            "annotation_path": annotation_path,
        };
    }
    comparisons = json.loads(Path(comparison_json_path).read_text(encoding="utf-8"));
    score_summary = _score_comparison_payload(comparisons, annotation_path);
    export_dir = Path("exports/evals");
    export_dir.mkdir(parents=True, exist_ok=True);
    stem = Path(comparison_json_path).stem;
    score_json_path = export_dir.joinpath(stem + "_gold_score.json");
    score_md_path = export_dir.joinpath(stem + "_gold_score.md");
    score_json_path.write_text(json.dumps(score_summary, indent=2) + "\n", encoding="utf-8");
    score_md_text = _rigorous_eval_markdown("scored-from-export", "", "", comparisons, score_summary);
    score_md_path.write_text(score_md_text, encoding="utf-8");
    return {
        "status": "scored",
        "comparison_json_path": comparison_json_path,
        "annotation_path": annotation_path,
        "labeled_run_count": score_summary["labeled_run_count"],
        "score_json_path": str(score_json_path),
        "score_markdown_path": str(score_md_path),
        "score_summary": score_summary,
        "preview": truncate_text(score_md_text, 1200),
    };
}
