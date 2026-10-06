import json;
import hashlib;
import from pathlib { Path }

obj RawTurn {
    has index: int;
    has role: str;
    has content: str;
    has raw: dict[str, any] = {};
}

obj ParsedStep {
    has index: int;
    has role: str = "other";
    has kind: str = "OTHER";
    has phase: str = "other";
    has excerpt: str = "";
    has content_hash: str = "";
    has assistant_content: str = "";
    has trailing_turns: list[RawTurn] = [];
    has touched_files: list[str] = [];
    has command_text: str = "";
    has patch_text: str = "";
    has test_text: str = "";
    has error_text: str = "";
    has submit_text: str = "";
}

obj ParsedRun {
    has run_id: str;
    has source_path: str;
    has raw: dict[str, any] = {};
    has turns: list[RawTurn] = [];
    has steps: list[ParsedStep] = [];
    has metadata: dict[str, any] = {};
    has instance_id: str = "";
    has task_title: str = "";
}

def truncate_text(text: str, limit: int = 280) -> str {
    clean = text.strip();
    if len(clean) <= limit {
        return clean;
    }
    return clean[: max(limit - 3, 0)].rstrip() + "...";
}

def unique_strings(items: list[str]) -> list[str] {
    seen: set[str] = set();
    output: list[str] = [];
    for item in items {
        if item in seen {
            continue;
        }
        seen.add(item);
        output.append(item);
    }
    return output;
}

def path_run_stem(path: str) -> str {
    name = Path(path).name;
    if name.endswith(".traj.json") {
        return name.removesuffix(".traj.json");
    }
    return Path(path).stem;
}

def load_trajectory_file(path: str) -> dict[str, any] {
    text = Path(path).read_text(encoding="utf-8");
    data = json.loads(text);
    if not isinstance(data, dict) {
        raise ValueError("trajectory file must decode to a JSON object");
    }
    return data;
}

def _turn_role(item: dict[str, any]) -> str {
    role = item.get("role");
    if role is None {
        role = item.get("speaker");
    }
    if role is None {
        role = item.get("type");
    }
    if role is None {
        role = "other";
    }
    return str(role).lower();
}

def _tool_call_name(call: dict[str, any]) -> str {
    function_payload = call.get("function");
    if isinstance(function_payload, dict) {
        name = function_payload.get("name");
        if name is not None and str(name) {
            return str(name);
        }
    }
    name = call.get("name");
    if name is not None and str(name) {
        return str(name);
    }
    return "tool_call";
}

def _tool_call_arguments(call: dict[str, any]) -> str {
    function_payload = call.get("function");
    if isinstance(function_payload, dict) {
        arguments = function_payload.get("arguments");
        if arguments is not None and str(arguments) {
            return str(arguments);
        }
    }
    arguments = call.get("arguments");
    if arguments is not None and str(arguments) {
        return str(arguments);
    }
    return "";
}

def _tool_call_summary(item: dict[str, any]) -> str {
    tool_calls = item.get("tool_calls");
    if not isinstance(tool_calls, list) {
        return "";
    }
    rendered: list[str] = [];
    for call in tool_calls {
        if not isinstance(call, dict) {
            continue;
        }
        line = "- " + _tool_call_name(call);
        arguments = _tool_call_arguments(call);
        if arguments {
            line += " args=" + truncate_text(arguments, 160);
        }
        rendered.append(line);
    }
    if not rendered {
        return "";
    }
    return "Tool calls:\n" + "\n".join(rendered);
}

def _turn_content(item: dict[str, any]) -> str {
    parts: list[str] = [];
    role = _turn_role(item);
    if role == "tool" {
        tool_name = item.get("name");
        if tool_name is not None and str(tool_name) {
            parts.append("Tool: " + str(tool_name));
        }
        tool_call_id = item.get("tool_call_id");
        if tool_call_id is not None and str(tool_call_id) {
            parts.append("Tool call id: " + str(tool_call_id));
        }
    }

    content = item.get("content");
    if content is None {
        content = item.get("text");
    }
    if content is None {
        content = item.get("message");
    }
    content_text = "";
    if content is not None {
        if isinstance(content, str) {
            content_text = content;
        } else {
            content_text = json.dumps(content);
        }
    }
    if content_text {
        parts.append(content_text);
    }

    tool_call_text = _tool_call_summary(item);
    if tool_call_text {
        parts.append(tool_call_text);
    }

    return "\n".join([part for part in parts if part]).strip();
}

def extract_turns(raw: dict[str, any]) -> list[RawTurn] {
    items: list[any] = [];
    candidates = [
        raw.get("trajectory"),
        raw.get("messages"),
        raw.get("history"),
        raw.get("turns"),
    ];
    for candidate in candidates {
        if isinstance(candidate, list) {
            items = candidate;
            break;
        }
    }

    turns: list[RawTurn] = [];
    for (index, item) in enumerate(items) {
        if not isinstance(item, dict) {
            continue;
        }
        item_dict = dict(item);
        turns.append(
            RawTurn(
                index=index,
                role=_turn_role(item_dict),
                content=_turn_content(item_dict),
                raw=item_dict,
            )
        );
    }
    return turns;
}

def hash_text(text: str) -> str {
    return hashlib.sha256(text.encode("utf-8")).hexdigest();
}

def _contains_any(lower: str, tokens: list[str]) -> bool {
    for token in tokens {
        if token in lower {
            return True;
        }
    }
    return False;
}

def _nonempty_lines(text: str) -> list[str] {
    lines: list[str] = [];
    for raw_line in text.split("\n") {
        line = raw_line.strip();
        if line {
            lines.append(line);
        }
    }
    return lines;
}

def _looks_like_shell_command(text: str) -> bool {
    lower = text.lower().strip();
    if not lower {
        return False;
    }
    prefixes = [
        "$ ",
        "python ",
        "pytest ",
        "py.test ",
        "bash ",
        "sh ",
        "git ",
        "ls ",
        "find ",
        "grep ",
        "rg ",
        "sed ",
        "cat ",
        "head ",
        "tail ",
        "apply_patch",
    ];
    if _contains_any(lower, ["returncode", "exit code", "non-zero exit", "command failed"]) {
        return True;
    }
    for line in _nonempty_lines(text) {
        lower_line = line.lower();
        for prefix in prefixes {
            if lower_line.startswith(prefix) {
                return True;
            }
        }
    }
    return False;
}

def _looks_like_patch_payload(text: str) -> bool {
    lower = text.lower();
    if _contains_any(lower, ["apply_patch", "diff --git", "*** begin patch", "@@ ", "--- ", "+++ "]) {
        return True;
    }
    plus_lines = 0;
    minus_lines = 0;
    for line in text.split("\n") {
        if line.startswith("+++") or line.startswith("---") {
            continue;
        }
        if line.startswith("+") {
            plus_lines += 1;
        } elif line.startswith("-") {
            minus_lines += 1;
        }
    }
    return plus_lines + minus_lines >= 3;
}

def _looks_like_test_signal(text: str) -> bool {
    lower = text.lower();
    return _contains_any(
        lower,
        [
            "pytest",
            "py.test",
            "test session starts",
            "collected ",
            "::",
            " passed",
            " failed",
            "assert ",
            "failing tests",
        ],
    );
}

def _looks_like_error_signal(text: str) -> bool {
    lower = text.lower();
    return _contains_any(
        lower,
        [
            "traceback",
            "exception",
            "syntaxerror",
            "importerror",
            "module not found",
            "assertionerror",
            "error:",
            " error ",
            "failed",
        ],
    );
}

def _looks_like_submit_signal(text: str) -> bool {
    lower = text.lower();
    return _contains_any(
        lower,
        [
            "submit",
            "final answer",
            "final response",
            "ready to submit",
            "i will submit",
            "i'll submit",
            "submitting now",
        ],
    );
}

def _looks_like_inspect_signal(text: str) -> bool {
    lower = text.lower();
    return _contains_any(lower, ["grep ", "ls ", "find ", "read ", "inspect", "open ", "cat ", "sed ", "rg "]);
}

def infer_kind(role: str, text: str) -> str {
    lower = text.lower();
    if _looks_like_submit_signal(text) {
        return "SUBMIT";
    }
    if _looks_like_patch_payload(text) {
        return "EDIT";
    }
    if _looks_like_test_signal(text) {
        return "TEST";
    }
    if _looks_like_error_signal(text) {
        return "ERROR";
    }
    if _looks_like_shell_command(text) {
        return "COMMAND";
    }
    if role in {"tool", "command"} {
        return "TOOL";
    }
    if role == "system" {
        return role.upper();
    }
    if role in {"assistant", "agent"} {
        return "ASSISTANT";
    }
    return "OTHER";
}

def infer_phase(text: str) -> str {
    if _looks_like_submit_signal(text) {
        return "submit";
    }
    if _looks_like_patch_payload(text) {
        return "edit";
    }
    if _looks_like_test_signal(text) {
        return "test";
    }
    if _looks_like_error_signal(text) {
        return "error";
    }
    if _looks_like_inspect_signal(text) {
        return "inspect";
    }
    if _looks_like_shell_command(text) {
        return "command";
    }
    return "reason";
}

def extract_file_tokens(text: str) -> list[str] {
    tokens: list[str] = [];
    for chunk in text.replace("`", " ").split() {
        cleaned = chunk.strip(" ,:;()[]{}<>");
        if not cleaned {
            continue;
        }
        if "/" in cleaned or "::" in cleaned {
            tokens.append(cleaned);
            continue;
        }
        if (
            cleaned.endswith(".py")
            or cleaned.endswith(".md")
            or cleaned.endswith(".json")
            or cleaned.endswith(".toml")
            or cleaned.endswith(".yaml")
            or cleaned.endswith(".yml")
        ) {
            tokens.append(cleaned);
        }
    }
    return unique_strings(tokens);
}

def step_text(step: ParsedStep) -> str {
    parts: list[str] = [];
    if step.assistant_content {
        parts.append(step.assistant_content);
    }
    for turn in step.trailing_turns {
        if turn.content {
            parts.append(turn.content);
        }
    }
    return "\n".join(parts);
}

def step_has_command(step: ParsedStep) -> bool {
    return bool(step.command_text);
}

def step_has_patch(step: ParsedStep) -> bool {
    return bool(step.patch_text);
}

def step_has_test(step: ParsedStep) -> bool {
    return bool(step.test_text);
}

def step_has_error(step: ParsedStep) -> bool {
    return bool(step.error_text);
}

def step_has_submit(step: ParsedStep) -> bool {
    return bool(step.submit_text);
}

def _final_kind_from_step(step: ParsedStep, full_text: str) -> str {
    if step_has_submit(step) {
        return "SUBMIT";
    }
    if step_has_patch(step) {
        return "EDIT";
    }
    if step_has_test(step) {
        return "TEST";
    }
    if step_has_error(step) {
        return "ERROR";
    }
    if step_has_command(step) {
        return "COMMAND";
    }
    return infer_kind(step.role, full_text);
}

def _final_phase_from_step(step: ParsedStep, full_text: str) -> str {
    if step_has_submit(step) {
        return "submit";
    }
    if step_has_patch(step) {
        return "edit";
    }
    if step_has_test(step) {
        return "test";
    }
    if step_has_error(step) {
        return "error";
    }
    if step_has_command(step) and _looks_like_inspect_signal(step.command_text) {
        return "inspect";
    }
    if step_has_command(step) {
        return "command";
    }
    return infer_phase(full_text);
}

def finalize_step(step: ParsedStep) -> ParsedStep {
    text = step_text(step);
    if not step.content_hash {
        step.content_hash = hash_text(text);
    }
    if not step.excerpt {
        step.excerpt = truncate_text(text);
    }
    step.touched_files = extract_file_tokens(text);
    command_matches: list[str] = [];
    patch_matches: list[str] = [];
    test_matches: list[str] = [];
    error_matches: list[str] = [];
    submit_matches: list[str] = [];
    payloads: list[str] = [];
    if step.assistant_content {
        payloads.append(step.assistant_content);
    }
    for turn in step.trailing_turns {
        if turn.content {
            payloads.append(turn.content);
        }
    }
    for payload in payloads {
        if _looks_like_shell_command(payload) {
            command_matches.append(payload);
        }
        if _looks_like_patch_payload(payload) {
            patch_matches.append(payload);
        }
        if _looks_like_test_signal(payload) {
            test_matches.append(payload);
        }
        if _looks_like_error_signal(payload) {
            error_matches.append(payload);
        }
        if _looks_like_submit_signal(payload) {
            submit_matches.append(payload);
        }
    }
    if command_matches {
        step.command_text = truncate_text("\n".join(command_matches), 600);
    }
    if patch_matches {
        step.patch_text = truncate_text("\n".join(patch_matches), 600);
    }
    if test_matches {
        step.test_text = truncate_text("\n".join(test_matches), 600);
    }
    if error_matches {
        step.error_text = truncate_text("\n".join(error_matches), 600);
    }
    if submit_matches {
        step.submit_text = truncate_text("\n".join(submit_matches), 280);
    }
    step.kind = _final_kind_from_step(step, text);
    step.phase = _final_phase_from_step(step, text);
    return step;
}

def segment_steps(turns: list[RawTurn]) -> list[ParsedStep] {
    steps: list[ParsedStep] = [];
    current = ParsedStep(index=0);
    has_current = False;

    for turn in turns {
        is_assistant = turn.role in {"assistant", "agent"};
        if is_assistant {
            if has_current {
                steps.append(finalize_step(current));
            }
            current = ParsedStep(index=len(steps));
            has_current = True;
            current.role = turn.role;
            current.assistant_content = turn.content;
            current.excerpt = truncate_text(turn.content);
            current.content_hash = hash_text(turn.content);
            continue;
        }

        if not has_current {
            current = ParsedStep(index=len(steps));
            has_current = True;
            current.role = turn.role;
        }

        current.trailing_turns.append(turn);
        current.excerpt = truncate_text((current.excerpt + "\n" + turn.content).strip());
        if turn.content {
            if current.content_hash {
                current.content_hash = hash_text(current.content_hash + turn.content);
            } else {
                current.content_hash = hash_text(turn.content);
            }
        }
    }

    if has_current {
        steps.append(finalize_step(current));
    }

    return steps;
}

def inferred_task_title(turns: list[RawTurn]) -> str {
    for turn in turns {
        if turn.role != "user" or not turn.content {
            continue;
        }
        first_line = turn.content.split("\n")[0].strip();
        if not first_line {
            continue;
        }
        if first_line.lower().startswith("task:") {
            return truncate_text(first_line[5:].strip(), 160);
        }
        return truncate_text(first_line, 160);
    }
    return "";
}

def _int_or_default(value: int | float | str | None, fallback: int = 0) -> int {
    if value is None or value == "" {
        return fallback;
    }
    return int(float(value));
}

def _float_or_default(value: int | float | str | None, fallback: float = 0.0) -> float {
    if value is None or value == "" {
        return fallback;
    }
    return float(value);
}

def _normalized_metadata(raw: dict[str, any]) -> dict[str, any] {
    metadata = raw.get("metadata");
    if not isinstance(metadata, dict) {
        metadata = {};
    }
    normalized = dict(metadata);

    info = raw.get("info");
    if isinstance(info, dict) {
        exit_status = info.get("exit_status");
        if exit_status is not None and str(exit_status) {
            normalized["status"] = str(exit_status);
            normalized["exit_status"] = str(exit_status);
        }

        traceback_text = info.get("traceback");
        if traceback_text is not None and str(traceback_text) {
            normalized["traceback"] = str(traceback_text);
        }

        submission = info.get("submission");
        submission_text = str(submission) if submission is not None else "";
        if submission_text {
            normalized["submission"] = submission_text;
        }

        mini_version = info.get("mini_version");
        if mini_version is not None and str(mini_version) {
            normalized["mini_version"] = str(mini_version);
        }

        model_stats = info.get("model_stats");
        if isinstance(model_stats, dict) {
            api_calls_value = model_stats.get("api_calls");
            instance_cost_value = model_stats.get("instance_cost");
            normalized["api_calls"] = _int_or_default(api_calls_value, normalized.get("api_calls", 0));
            normalized["instance_cost"] = _float_or_default(instance_cost_value, normalized.get("instance_cost", 0.0));
        }
    }

    trajectory_format = raw.get("trajectory_format");
    if trajectory_format is not None and str(trajectory_format) {
        normalized["trajectory_format"] = str(trajectory_format);
    }
    if "status" in normalized and "exit_status" not in normalized {
        normalized["exit_status"] = str(normalized["status"]);
    }
    return normalized;
}

def parse_run(source_path: str, run_id: str = "") -> ParsedRun {
    raw = load_trajectory_file(source_path);
    turns = extract_turns(raw);
    steps = segment_steps(turns);
    metadata = _normalized_metadata(raw);
    info_dict: dict[str, any] = {};
    raw_info = raw.get("info");
    if isinstance(raw_info, dict) {
        info_dict = raw_info;
    }
    chosen_run_id = run_id;
    if not chosen_run_id {
        raw_run_id = raw.get("run_id");
        raw_instance_id = raw.get("instance_id");
        if raw_run_id is not None and str(raw_run_id) {
            chosen_run_id = str(raw_run_id);
        } elif raw_instance_id is not None and str(raw_instance_id) {
            chosen_run_id = str(raw_instance_id);
        } else {
            chosen_run_id = path_run_stem(source_path);
        }
    }
    return ParsedRun(
        run_id=chosen_run_id,
        source_path=source_path,
        raw=raw,
        turns=turns,
        steps=steps,
        metadata=metadata,
        instance_id=str(raw.get("instance_id") or info_dict.get("instance_id") or ""),
        task_title=str(raw.get("task_title") or raw.get("task") or info_dict.get("task_title") or inferred_task_title(turns)),
    );
}
