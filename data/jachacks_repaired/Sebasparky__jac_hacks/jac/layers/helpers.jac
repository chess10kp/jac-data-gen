"""
Jac-native helper backend layer.

Purpose:
- Persist real helper definitions, backend-owned agent specs, and helper runs.
- Normalize browser telemetry into helper-friendly browser world state.
- Execute a first read-only browser-backed helper runtime without introducing a parallel backend.
"""

import os;
import sys;
import json;
import time;
import uuid;
import re;
import from html { unescape }
import from urllib.parse { urlparse, parse_qs, quote_plus, unquote }
import from urllib.request { Request, urlopen }
import from urllib.error { HTTPError, URLError }
import from jac.layers.trace_utils { read_trace }
import from jac.layers.helpers_v2 { run_helper_v2 }
import from jac.llm.runtime_state { current_runtime_state }

glob DATA_ROOT: str = "./jac/layer_data";
glob HELPER_ROOT: str = DATA_ROOT + "/helpers";
glob HELPER_DEF_DIR: str = HELPER_ROOT + "/definitions";
glob AGENT_SPEC_DIR: str = HELPER_ROOT + "/agent_specs";
glob HELPER_RUN_DIR: str = HELPER_ROOT + "/runs";

glob VALID_HELPER_FREQUENCIES: list[str] = ["once", "daily", "weekly"];
glob VALID_HELPER_STATUSES: list[str] = ["active", "paused", "archived"];
glob VALID_HELPER_KINDS: list[str] = ["briefing", "monitor", "research", "browser_read"];
glob VALID_RUNTIME_MODES: list[str] = ["browser_read"];
glob VALID_RUNTIME_VERSIONS: list[str] = ["v1", "v2"];
glob VALID_RUN_STATUSES: list[str] = ["success", "partial", "blocked", "failed"];
glob SEARCH_WEB_PROVIDER: str = "duckduckgo_html";
glob SEARCH_WEB_ENDPOINT: str = "https://html.duckduckgo.com/html/?q=";
glob SEARCH_WEB_USER_AGENT: str = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
    "AppleWebKit/537.36 (KHTML, like Gecko) " +
    "Chrome/124.0.0.0 Safari/537.36"
);
glob OPEN_PAGE_MAX_BYTES: int = 120000;

"""R: Return an ISO-like UTC timestamp used across helper persistence records.
M: Uses `time.gmtime()` and `strftime` so records sort lexicographically.
E: Precision is seconds, which is sufficient for helper definition and run history.
"""
def timestamp_now() -> str {
    t: any = time.gmtime();
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", t);
}

"""R: Generate a stable prefixed identifier for helper layer records.
M: Builds ids from UUID v4 and trims them for concise file names.
E: Collisions are extremely unlikely under the current single-user desktop flow.
"""
def new_id(prefix: str) -> str {
    uid: str = str(uuid.uuid4()).replace("-", "");
    return prefix + uid[:16];
}

def new_helper_id() -> str { return new_id("helper_"); }
def new_agent_spec_id() -> str { return new_id("spec_"); }
def new_run_id() -> str { return new_id("run_"); }

"""R: Bound arbitrary values into small plain-text fields for persisted helper records.
M: String-casts, trims whitespace, and truncates long values to a caller-provided limit.
E: `None` and empty-like values normalize to the empty string.
"""
def safe_text(value: any, max_len: int = 240) -> str {
    text: str = str(value or "").strip();
    if len(text) > max_len {
        return text[:max_len];
    }
    return text;
}

"""R: Normalize helper instruction text before persistence, planning, or display.
M: Collapses whitespace, removes accidental duplicated leading clauses, and keeps the original wording otherwise intact.
E: Only long repeated prefixes are collapsed so legitimate short repetition and emphasis are preserved.
"""
def normalize_instruction_text(raw_text: any, max_len: int = 2000) -> str {
    normalized: str = " ".join(str(raw_text or "").split());
    if not normalized {
        return "";
    }

    best_prefix: str = "";
    best_suffix: str = "";
    max_scan: int = len(normalized) - 20;
    if max_scan > 320 {
        max_scan = 320;
    }

    index: int = 40;
    while index < max_scan {
        if index >= len(normalized) {
            break;
        }
        previous_char: str = normalized[index - 1:index];
        current_char: str = normalized[index:index + 1];
        if re.search(r"[A-Za-z0-9]", previous_char) and re.search(r"[A-Za-z0-9]", current_char) {
            index += 1;
            continue;
        }

        prefix: str = normalized[:index].rstrip(" ,;:-");
        if len(prefix.split()) < 5 {
            index += 1;
            continue;
        }

        remainder: str = normalized[index:].lstrip(" ,;:-");
        if not remainder {
            index += 1;
            continue;
        }

        if remainder.lower().startswith(prefix.lower()) and len(prefix) > len(best_prefix) {
            suffix: str = remainder[len(prefix):].lstrip(" ,;:-");
            if suffix {
                best_prefix = prefix;
                best_suffix = suffix;
            }
        }
        index += 1;
    }

    if best_prefix and best_suffix {
        normalized = best_prefix + " " + best_suffix;
    }

    return safe_text(normalized, max_len);
}

"""R: Keep nested JSON-like payloads safe for helper persistence and renderer transport.
M: Recursively bounds nesting, collection size, and string length while preserving primitive values.
E: Unsupported objects fall back to bounded string output so helper storage never raises on odd payloads.
"""
def sanitize_json_value(raw: any, depth: int = 4, max_items: int = 16, max_len: int = 280) -> any {
    if depth <= 0 {
        return safe_text(raw, max_len);
    }

    if isinstance(raw, dict) {
        normalized: dict[str, any] = {};
        count: int = 0;
        for key in raw {
            if count >= max_items {
                break;
            }
            normalized[safe_text(key, 80)] = sanitize_json_value(raw[key], depth - 1, max_items, max_len);
            count += 1;
        }
        return normalized;
    }

    if isinstance(raw, list) {
        normalized_list: list[any] = [];
        count: int = 0;
        for item in raw {
            if count >= max_items {
                break;
            }
            normalized_list.append(sanitize_json_value(item, depth - 1, max_items, max_len));
            count += 1;
        }
        return normalized_list;
    }

    if isinstance(raw, bool) or isinstance(raw, int) or isinstance(raw, float) {
        return raw;
    }

    return safe_text(raw, max_len);
}

"""R: Normalize untrusted list-like inputs into bounded string lists.
M: Iterates only real lists, trims each item, drops blanks, and caps both length and item count.
E: Non-list values return an empty list.
"""
def normalize_text_list(raw: any, max_items: int = 12, max_len: int = 180) -> list[str] {
    results: list[str] = [];
    if not isinstance(raw, list) {
        return results;
    }

    count: int = 0;
    for item in raw {
        if count >= max_items {
            break;
        }
        text: str = safe_text(item, max_len);
        if not text or text in results {
            continue;
        }
        results.append(text);
        count += 1;
    }

    return results;
}

"""R: Clamp integer-like output limits into a small predictable range for final helper shaping.
M: Uses integer inputs when present, otherwise falls back, then enforces caller-provided min and max bounds.
E: Invalid or extreme values collapse to conservative defaults instead of widening result size unexpectedly.
"""
def clamp_int_limit(raw_value: any, fallback: int, min_value: int, max_value: int) -> int {
    value: int = fallback;
    if isinstance(raw_value, int) {
        value = raw_value;
    }
    if value < min_value {
        return min_value;
    }
    if value > max_value {
        return max_value;
    }
    return value;
}

"""R: Turn longer text into one bounded sentence-sized excerpt for summaries and highlights.
M: Collapses whitespace, prefers the first sentence boundary when present, and trims to the requested length.
E: Empty inputs stay empty, and punctuation-free text is still returned in bounded form.
"""
def concise_sentence(raw_text: any, max_len: int = 160) -> str {
    collapsed: str = " ".join(str(raw_text or "").split());
    if not collapsed {
        return "";
    }

    sentence_match: any = re.search(r"^(.+?[.!?])(?:\s|$)", collapsed);
    if sentence_match {
        return safe_text(sentence_match.group(1), max_len);
    }
    return safe_text(collapsed, max_len);
}

"""R: Ensure helper persistence directories exist before reading or writing records.
M: Creates definitions, specs, and runs folders under `jac/layer_data/helpers`.
E: Safe to call repeatedly before every operation.
"""
def ensure_helper_dirs() {
    os.makedirs(HELPER_DEF_DIR, exist_ok=True);
    os.makedirs(AGENT_SPEC_DIR, exist_ok=True);
    os.makedirs(HELPER_RUN_DIR, exist_ok=True);
}

def helper_file(helper_id: str) -> str { return HELPER_DEF_DIR + "/" + helper_id + ".json"; }
def agent_spec_file(agent_spec_id: str) -> str { return AGENT_SPEC_DIR + "/" + agent_spec_id + ".json"; }
def helper_run_file(run_id: str) -> str { return HELPER_RUN_DIR + "/" + run_id + ".json"; }

"""R: Read one JSON record from disk for the helper layer.
M: Loads the file and returns only dict payloads so callers get stable shapes.
E: Missing, unreadable, or non-dict files normalize to the empty dict.
"""
def read_json_file(path: str) -> dict[str, any] {
    if not os.path.exists(path) {
        return {};
    }

    try {
        with open(path, "r") as file {
            parsed: any = json.load(file);
            if isinstance(parsed, dict) {
                return parsed;
            }
        }
    } except json.JSONDecodeError {
        return {};
    } except OSError {
        return {};
    }

    return {};
}

"""R: Persist one helper-layer record as formatted JSON.
M: Creates parent directories when needed and writes the normalized payload with indentation.
E: Filesystem errors are surfaced to the caller because silent partial writes would be misleading.
"""
def write_json_file(path: str, payload: dict[str, any]) {
    ensure_helper_dirs();
    with open(path, "w") as file {
        json.dump(payload, file, indent=2);
    }
}

"""R: List all persisted dict records from one helper-layer directory.
M: Scans `.json` files only and ignores unreadable or invalid payloads.
E: Missing directories return an empty list instead of raising.
"""
def list_json_records(dir_path: str) -> list[any] {
    ensure_helper_dirs();
    results: list[any] = [];
    if not os.path.exists(dir_path) or not os.path.isdir(dir_path) {
        return results;
    }

    for name in os.listdir(dir_path) {
        if not str(name).endswith(".json") {
            continue;
        }
        candidate: dict[str, any] = read_json_file(dir_path + "/" + str(name));
        if candidate {
            results.append(candidate);
        }
    }

    return results;
}

def normalize_helper_frequency(raw_frequency: any) -> str {
    frequency: str = safe_text(raw_frequency, 24).lower();
    if frequency in VALID_HELPER_FREQUENCIES {
        return frequency;
    }
    return "once";
}

def helper_frequency_label(frequency: str) -> str {
    if frequency == "daily" {
        return "Daily";
    }
    if frequency == "weekly" {
        return "Weekly";
    }
    return "Just once";
}

def normalize_helper_status(raw_status: any) -> str {
    status: str = safe_text(raw_status, 24).lower();
    if status in VALID_HELPER_STATUSES {
        return status;
    }
    return "active";
}

def normalize_helper_kind(raw_kind: any) -> str {
    kind: str = safe_text(raw_kind, 32).lower();
    if kind in VALID_HELPER_KINDS {
        return kind;
    }
    return "browser_read";
}

def normalize_runtime_mode(raw_mode: any) -> str {
    runtime_mode: str = safe_text(raw_mode, 40).lower();
    if runtime_mode in VALID_RUNTIME_MODES {
        return runtime_mode;
    }
    return "browser_read";
}

"""R: Normalize helper runtime version labels into the small reversible migration set.
M: Accepts only known runtime ids and otherwise falls back to a caller-provided safe default.
E: Missing or unknown values collapse to `v1` so older helpers never migrate implicitly.
"""
def normalize_runtime_version(raw_version: any, fallback: str = "v1") -> str {
    runtime_version: str = safe_text(raw_version, 16).lower();
    if runtime_version in VALID_RUNTIME_VERSIONS {
        return runtime_version;
    }

    normalized_fallback: str = safe_text(fallback, 16).lower();
    if normalized_fallback in VALID_RUNTIME_VERSIONS {
        return normalized_fallback;
    }
    return "v1";
}

def normalize_run_status(raw_status: any) -> str {
    status: str = safe_text(raw_status, 24).lower();
    if status in VALID_RUN_STATUSES {
        return status;
    }
    return "failed";
}

"""R: Infer the initial helper kind from the user goal with deterministic Jac-owned rules.
M: Uses a small ordered keyword classifier so simple UI input becomes a stable backend category.
E: Mixed or weak goals fall back to `browser_read` rather than blocking helper creation.
"""
def infer_helper_kind(goal_text: any) -> str {
    lowered: str = safe_text(goal_text, 1600).lower();
    if not lowered {
        return "browser_read";
    }

    if (
        "brief" in lowered or
        "digest" in lowered or
        "summary" in lowered or
        "summarize" in lowered or
        "briefing" in lowered
    ) {
        return "briefing";
    }

    if (
        "monitor" in lowered or
        "watch" in lowered or
        "track" in lowered or
        "alert" in lowered or
        "check for changes" in lowered
    ) {
        return "monitor";
    }

    if (
        "research" in lowered or
        "investigate" in lowered or
        "compare" in lowered or
        "find" in lowered or
        "look up" in lowered or
        "lookup" in lowered
    ) {
        return "research";
    }

    return "browser_read";
}

"""R: Reuse one bounded keyword check across helper inference helpers.
M: Scans a lowered goal string against a short list of phrases and returns on the first match.
E: Empty text or empty term lists return `False` without raising.
"""
def goal_mentions_any(lowered_goal: str, terms: list[str]) -> bool {
    if not lowered_goal or len(terms) == 0 {
        return False;
    }

    for term in terms {
        keyword: str = safe_text(term, 80).lower();
        if keyword and keyword in lowered_goal {
            return True;
        }
    }

    return False;
}

"""R: Build the structured task requirements that later capability and plan inference consume.
M: Applies deterministic goal-text heuristics for freshness, search, page context, synthesis, and monitoring needs.
E: Ambiguous goals stay read-only and conservative so new helpers never claim unsupported autonomy.
"""
def infer_task_requirements(goal_text: str, kind: str) -> dict[str, any] {
    lowered: str = normalize_instruction_text(goal_text, 1600).lower();
    needs_current_page_context: bool = goal_mentions_any(lowered, [
        "this page",
        "current page",
        "on this page",
        "from this page",
        "page you are on",
        "page i'm on",
        "page i am on"
    ]);

    if not needs_current_page_context and "summarize the page" in lowered {
        needs_current_page_context = True;
    }
    if not needs_current_page_context and "summarise the page" in lowered {
        needs_current_page_context = True;
    }
    if not needs_current_page_context and kind == "browser_read" and "page" in lowered {
        needs_current_page_context = True;
    }

    freshness_required: bool = goal_mentions_any(lowered, [
        "latest",
        "recent",
        "today",
        "new",
        "fresh",
        "breaking",
        "updates",
        "update",
        "news"
    ]);

    needs_monitoring: bool = kind == "monitor" or goal_mentions_any(lowered, [
        "monitor",
        "watch",
        "track",
        "alert",
        "check for changes",
        "price changes"
    ]);

    explicit_search: bool = goal_mentions_any(lowered, [
        "search for",
        "look up",
        "lookup",
        "web",
        "internet",
        "latest",
        "recent",
        "news",
        "updates"
    ]);

    needs_search: bool = explicit_search;
    if not needs_search and kind == "research" and not needs_current_page_context {
        needs_search = True;
    }

    needs_multi_source_synthesis: bool = goal_mentions_any(lowered, [
        "compare",
        "across sources",
        "multiple sources",
        "latest",
        "recent",
        "news",
        "updates"
    ]);
    if needs_search and not needs_current_page_context {
        needs_multi_source_synthesis = True;
    }

    freshness_window: str = "";
    if freshness_required {
        freshness_window = "48h";
    }

    return {
        "freshness_required": freshness_required,
        "freshness_window": freshness_window,
        "needs_search": needs_search,
        "needs_current_page_context": needs_current_page_context,
        "needs_multi_source_synthesis": needs_multi_source_synthesis,
        "needs_monitoring": needs_monitoring,
        "read_only": True
    };
}

"""R: Convert the helper goal into a persisted objective block owned by the helper domain.
M: Captures the primary goal, success definition, and output style in task-specific language.
E: Falls back to stable default wording when helper copy is sparse.
"""
def infer_objective(name: str, goal: str, kind: str, requirements: dict[str, any]) -> dict[str, any] {
    primary_goal: str = normalize_instruction_text(goal, 1400) or "Read the active browser context and report what matters.";
    helper_name: str = safe_text(name, 120) or "Helper";
    success_definition: str = "Produce a truthful read-only result that satisfies the saved output contract.";

    if bool(requirements.get("needs_search", False)) {
        success_definition = (
            "Gather relevant sources, preserve freshness requirements, and synthesize the result without inventing missing findings."
        );
    } elif bool(requirements.get("needs_monitoring", False)) {
        success_definition = (
            "Inspect observable signals for the requested page or target and clearly report whether monitoring could be completed."
        );
    } elif bool(requirements.get("needs_current_page_context", False)) {
        success_definition = "Use the current page context to produce a concise read-only result for " + helper_name + ".";
    }

    return {
        "primary_goal": primary_goal,
        "success_definition": success_definition,
        "output_style": kind
    };
}

"""R: Persist explicit execution constraints so runtime and UI can see the same task limits.
M: Uses deterministic caps for sources, list sizes, output length, and non-destructive guarantees.
E: Search-oriented tasks allow a source budget while current-page tasks keep that budget at zero.
"""
def infer_constraints(kind: str, requirements: dict[str, any]) -> dict[str, any] {
    max_sources: int = 0;
    if bool(requirements.get("needs_search", False)) or bool(requirements.get("needs_multi_source_synthesis", False)) {
        max_sources = 5;
    }

    max_output_items: int = 5;
    if kind == "monitor" {
        max_output_items = 6;
    }

    return {
        "max_sources": max_sources,
        "max_output_items": max_output_items,
        "max_output_chars": 1200,
        "disallow_destructive_actions": True,
        "disallow_auth_writes": True
    };
}

def append_capability(capabilities: list[str], capability: str) {
    normalized: str = safe_text(capability, 60);
    if normalized and normalized not in capabilities {
        capabilities.append(normalized);
    }
}

"""R: Select reusable runtime capabilities from inferred requirements rather than fixed helper modes.
M: Maps search, page-observation, extraction, comparison, and monitoring needs to a small generic capability set.
E: Capability order is deterministic so persisted specs stay diff-friendly across repeated runs.
"""
def select_capabilities(goal: str, kind: str, requirements: dict[str, any]) -> list[str] {
    lowered: str = normalize_instruction_text(goal, 1600).lower();
    capabilities: list[str] = [];

    if bool(requirements.get("needs_current_page_context", False)) or bool(requirements.get("needs_monitoring", False)) {
        append_capability(capabilities, "observe_browser");
        append_capability(capabilities, "extract_page_content");
    }

    if bool(requirements.get("needs_search", False)) {
        append_capability(capabilities, "search_web");
        append_capability(capabilities, "rank_sources");
        append_capability(capabilities, "open_page");
        append_capability(capabilities, "extract_page_content");
    }

    if kind == "research" or goal_mentions_any(lowered, ["link", "links", "source", "sources", "reference", "references"]) {
        append_capability(capabilities, "extract_links");
    }

    if kind == "monitor" or goal_mentions_any(lowered, ["action", "actions", "button", "buttons", "form", "forms"]) {
        append_capability(capabilities, "extract_actions");
    }

    if bool(requirements.get("needs_multi_source_synthesis", False)) {
        append_capability(capabilities, "dedupe");
    }

    if kind == "research" and goal_mentions_any(lowered, ["compare", "versus", "vs", "difference"]) {
        append_capability(capabilities, "compare");
    }

    if bool(requirements.get("needs_monitoring", False)) {
        append_capability(capabilities, "monitor_condition");
    }

    append_capability(capabilities, "summarize");
    return capabilities;
}

def build_plan_step(step_id: str, step_type: str, input_from: str = "", query: str = "", params: dict[str, any] = {}) -> dict[str, any] {
    step: dict[str, any] = {
        "step_id": safe_text(step_id, 80),
        "type": safe_text(step_type, 60)
    };

    normalized_input: str = safe_text(input_from, 80);
    if normalized_input {
        step["input_from"] = normalized_input;
    }

    normalized_query: str = safe_text(query, 320);
    if normalized_query {
        step["query"] = normalized_query;
    }

    if isinstance(params, dict) and len(params) > 0 {
        step["params"] = sanitize_json_value(params, 3, 10, 180);
    }

    return step;
}

"""R: Convert one saved helper goal into a cleaner web-search query without hardcoding task families.
M: Removes common instruction boilerplate, browser-context caveats, and duplicated clauses while preserving the subject and freshness cues.
E: If cleanup becomes too aggressive, the normalized original goal is used so plan execution never loses the user’s topic.
"""
def derive_search_query(goal: str) -> str {
    normalized_goal: str = normalize_instruction_text(goal, 320);
    if not normalized_goal {
        return "";
    }

    query: str = normalized_goal;
    query = re.sub(r"(?i)^\s*(please\s+)?(summari[sz]e|brief|digest|research|investigate|look up|lookup|find|track|monitor|compare)\b\s*", "", query);
    query = re.sub(r"(?i)\b(and\s+)?(provide|give|return)\b[^.]{0,80}\b(summary|briefing|report|digest|overview|updates?)\b", "", query);
    query = re.sub(r"(?i)\b(from|using)\s+(current|fresh|live)\s+(web|internet|online)\s+sources\b", "", query);
    query = re.sub(r"(?i)\bnot\s+(the\s+)?(current|this)\s+page\b", "", query);
    query = re.sub(r"(?i)\buse\s+normalized\s+browser\s+state\s+only\b", "", query);
    query = re.sub(r"(?i)\bdo\s+not\s+perform\b.*$", "", query);
    query = " ".join(query.replace(" ,", ",").split());
    query = query.strip(" ,;:-");

    if len(query.split()) < 3 {
        return normalized_goal;
    }
    return safe_text(query, 320);
}

"""R: Generate the saved task plan that new helpers execute before any legacy fallback path.
M: Builds a short deterministic sequence from inferred requirements and selected capabilities.
E: The planner stays explicit and shallow on purpose; unsupported steps can still be surfaced honestly at runtime.
"""
def generate_agent_plan(
    goal: str,
    kind: str,
    requirements: dict[str, any],
    capabilities: list[str],
    constraints: dict[str, any]
) -> list[any] {
    plan: list[any] = [];
    max_output_items: int = 5;
    if isinstance(constraints.get("max_output_items", 5), int) {
        max_output_items = constraints.get("max_output_items", 5);
    }
    max_sources: int = 5;
    if isinstance(constraints.get("max_sources", 5), int) {
        max_sources = constraints.get("max_sources", 5);
    }
    max_output_chars: int = 1200;
    if isinstance(constraints.get("max_output_chars", 1200), int) {
        max_output_chars = constraints.get("max_output_chars", 1200);
    }

    if bool(requirements.get("needs_search", False)) {
        search_params: dict[str, any] = {"limit": 8};
        freshness_window: str = safe_text(requirements.get("freshness_window", ""), 32);
        if freshness_window {
            search_params["freshness_window"] = freshness_window;
        }

        plan.append(build_plan_step("search_task_sources", "search_web", "", derive_search_query(goal), search_params));
        plan.append(build_plan_step("rank_sources", "rank_sources", "search_task_sources", "", {"top_k": max_sources}));
        plan.append(build_plan_step("open_sources", "open_page", "rank_sources"));
        plan.append(build_plan_step("extract_source_content", "extract_page_content", "open_sources"));
        if "dedupe" in capabilities {
            plan.append(build_plan_step("dedupe_source_content", "dedupe", "extract_source_content"));
            plan.append(build_plan_step(
                "synthesize_result",
                "summarize",
                "dedupe_source_content",
                "",
                {"max_items": max_output_items, "max_chars": max_output_chars, "style": kind}
            ));
        } else {
            plan.append(build_plan_step(
                "synthesize_result",
                "summarize",
                "extract_source_content",
                "",
                {"max_items": max_output_items, "max_chars": max_output_chars, "style": kind}
            ));
        }
        return plan;
    }

    if bool(requirements.get("needs_current_page_context", False)) or bool(requirements.get("needs_monitoring", False)) {
        plan.append(build_plan_step("observe_current_page", "observe_browser"));
        plan.append(build_plan_step("extract_current_page", "extract_page_content", "observe_current_page"));

        if "extract_links" in capabilities {
            plan.append(build_plan_step("extract_current_links", "extract_links", "extract_current_page"));
        }
        if "extract_actions" in capabilities {
            plan.append(build_plan_step("extract_current_actions", "extract_actions", "extract_current_page"));
        }
        if "monitor_condition" in capabilities {
            input_step: str = "extract_current_page";
            has_action_step: bool = False;
            for step in plan {
                if isinstance(step, dict) and safe_text(step.get("step_id", ""), 80) == "extract_current_actions" {
                    has_action_step = True;
                    break;
                }
            }
            if has_action_step {
                input_step = "extract_current_actions";
            }
            plan.append(build_plan_step("evaluate_monitor_condition", "monitor_condition", input_step));
        }

        last_step_id: str = "extract_current_page";
        if len(plan) > 0 and isinstance(plan[len(plan) - 1], dict) {
            last_step_id = safe_text(plan[len(plan) - 1].get("step_id", "extract_current_page"), 80) or "extract_current_page";
        }
        plan.append(build_plan_step(
            "synthesize_result",
            "summarize",
            last_step_id,
            "",
            {"max_items": max_output_items, "max_chars": max_output_chars, "style": kind}
        ));
        return plan;
    }

    plan.append(build_plan_step("observe_current_page", "observe_browser"));
    plan.append(build_plan_step("extract_current_page", "extract_page_content", "observe_current_page"));
    plan.append(build_plan_step(
        "synthesize_result",
        "summarize",
        "extract_current_page",
        "",
        {"max_items": max_output_items, "max_chars": max_output_chars, "style": kind}
    ));
    return plan;
}

"""R: Convert simple user intent into the backend mission text a runtime will execute.
M: Combines helper name, goal, kind, and read-only constraints into one explicit mission string.
E: Empty names still yield a stable mission so helper creation never depends on optional copy polish.
"""
def build_helper_mission(name: str, goal: str, kind: str) -> str {
    helper_name: str = safe_text(name, 120) or "Helper";
    base_goal: str = normalize_instruction_text(goal, 1400) or "Read the active browser context and report what matters.";
    return (
        helper_name + " is a read-only " + kind + " helper. " +
        "Mission: " + base_goal + " " +
        "Use normalized browser state only. " +
        "Do not perform destructive browser actions, account changes, or uncontrolled form submissions."
    );
}

"""R: Build the browser access policy for the first read-only helper runtime.
M: Encodes allowed read-only browser capabilities and explicit non-goals in one persisted policy object.
E: This v1 policy always stays read-only even if future helper kinds expand.
"""
def infer_browser_policy(kind: str) -> dict[str, any] {
    return {
        "environment": "browser_world",
        "state_source": "normalized_observation_trace",
        "allowed_capabilities": [
            "bind_browser_session",
            "inspect_page_state",
            "read_dom_snapshot",
            "extract_structured_text",
            "summarize_findings"
        ],
        "blocked_capabilities": [
            "destructive_writes",
            "message_sends",
            "account_changes",
            "purchases",
            "uncontrolled_form_submission"
        ],
        "default_kind_focus": kind,
        "read_only": True
    };
}

"""R: Build the tool policy for helper runtime decisions without bypassing Jac ownership.
M: Records which Jac-owned seams are allowed and whether LLM runtime availability was detected.
E: LLM availability is metadata only in this slice; spec inference remains deterministic.
"""
def infer_tool_policy() -> dict[str, any] {
    runtime_state: dict[str, any] = current_runtime_state();
    return {
        "llm_runtime_active": bool(runtime_state.get("active", False)),
        "llm_runtime_provider": safe_text(runtime_state.get("provider", ""), 40),
        "llm_enrichment_attempted": False,
        "llm_enrichment_used": False,
        "allowed_tools": [
            "helper_spec_validation",
            "browser_state_normalization",
            "run_result_persistence"
        ]
    };
}

"""R: Build the helper memory policy so future runtimes have explicit persistence expectations.
M: Stores recent run history and normalized observation context while keeping memory bounded and predictable.
E: This slice keeps memory simple and run-scoped; no long-horizon autonomous planning is added yet.
"""
def infer_memory_policy(frequency: str) -> dict[str, any] {
    return {
        "store_run_history": True,
        "store_browser_snapshots": True,
        "max_recent_runs": 24,
        "refresh_hint": helper_frequency_label(frequency),
        "session_scope": "run_scoped"
    };
}

"""R: Build the execution policy that constrains first-pass browser helper runs.
M: Encodes a small read-only step budget and explicit stop conditions for clean runtime behavior.
E: Monitor helpers get a slightly larger read budget, but no helper in this slice can mutate the browser.
"""
def infer_execution_policy(kind: str) -> dict[str, any] {
    max_steps: int = 3;
    if kind == "monitor" or kind == "research" {
        max_steps = 4;
    }

    return {
        "max_steps": max_steps,
        "observe_before_decide": True,
        "stop_on_missing_browser_state": True,
        "retry_budget": 0,
        "read_only": True
    };
}

"""R: Define the structured output contract persisted for one helper kind.
M: Returns required fields and shape hints so both runtime output and UI consumers stay aligned.
E: Unknown kinds fall back to the generic browser-read output contract.
"""
def infer_output_contract(kind: str, requirements: dict[str, any]) -> dict[str, any] {
    if kind == "briefing" {
        required_fields: list[str] = ["summary", "highlights"];
        if bool(requirements.get("needs_search", False)) or bool(requirements.get("needs_multi_source_synthesis", False)) {
            required_fields.append("sources");
        } else {
            required_fields.append("page_summary");
        }
        return {
            "kind": kind,
            "required_fields": required_fields,
            "result_shape": "briefing_report"
        };
    }

    if kind == "monitor" {
        return {
            "kind": kind,
            "required_fields": ["summary", "watch_points", "notable_signals", "candidate_links"],
            "result_shape": "monitor_snapshot"
        };
    }

    if kind == "research" {
        return {
            "kind": kind,
            "required_fields": ["summary", "findings", "detected_entities", "candidate_links"],
            "result_shape": "research_snapshot"
        };
    }

    return {
        "kind": "browser_read",
        "required_fields": ["summary", "page_summary", "candidate_links", "visible_actions"],
        "result_shape": "browser_read_snapshot"
    };
}

"""R: Build the backend-owned agent spec from the simple helper form fields.
M: Applies deterministic inference for kind, runtime mode, policies, mission, and output contract.
E: LLM runtime availability is recorded in tool policy metadata but does not bypass Jac validation.
"""
def build_agent_spec(helper_id: str, name: str, goal: str, frequency: str) -> dict[str, any] {
    kind: str = infer_helper_kind(goal);
    runtime_mode: str = "browser_read";
    agent_spec_id: str = new_agent_spec_id();
    requirements: dict[str, any] = infer_task_requirements(goal, kind);
    objective: dict[str, any] = infer_objective(name, goal, kind, requirements);
    constraints: dict[str, any] = infer_constraints(kind, requirements);
    capabilities: list[str] = select_capabilities(goal, kind, requirements);
    plan: list[any] = generate_agent_plan(goal, kind, requirements, capabilities, constraints);

    return {
        "agent_spec_id": agent_spec_id,
        "helper_id": helper_id,
        "goal_text": safe_text(goal, 1600),
        "kind": kind,
        "mission": build_helper_mission(name, goal, kind),
        "runtime_mode": runtime_mode,
        "objective": objective,
        "requirements": requirements,
        "constraints": constraints,
        "capabilities": capabilities,
        "plan": plan,
        "trigger": {
            "frequency": frequency,
            "label": helper_frequency_label(frequency),
            "trigger_type": "manual_or_scheduled"
        },
        "browser_policy": infer_browser_policy(kind),
        "tool_policy": infer_tool_policy(),
        "memory_policy": infer_memory_policy(frequency),
        "execution_policy": infer_execution_policy(kind),
        "output_contract": infer_output_contract(kind, requirements),
        "read_only": True,
        "version": "1.1"
    };
}

"""R: Decide whether a helper belongs to the narrow safe slice allowed onto the v2 runtime.
M: Uses helper kind plus explicit read-only state so routing stays capability-based instead of name-based.
E: Anything ambiguous or non-read-only stays on v1 by default to keep migration conservative.
"""
def helper_is_v2_eligible(agent_spec: dict[str, any]) -> bool {
    return (
        bool(agent_spec.get("read_only", True)) and
        normalize_helper_kind(agent_spec.get("kind", "browser_read")) == "briefing"
    );
}

"""R: Resolve the persisted runtime version for one helper at creation time.
M: Honors explicit v1/v2 requests when safe, otherwise applies a conservative default based on helper suitability.
E: Explicit v2 requests for unsupported helper slices degrade to v1 rather than widening the migration unexpectedly.
"""
def resolve_helper_runtime_version(raw_requested_version: any, agent_spec: dict[str, any]) -> str {
    default_version: str = "v2" if helper_is_v2_eligible(agent_spec) else "v1";
    requested_version: str = safe_text(raw_requested_version, 16).lower();
    if not requested_version {
        return default_version;
    }
    if requested_version == "v1" {
        return "v1";
    }
    if requested_version == "v2" and helper_is_v2_eligible(agent_spec) {
        return "v2";
    }
    return "v1";
}

"""R: Normalize the persisted objective block so runtime logic sees one stable task description shape.
M: Sanitizes nested fields and fills missing goal, success, and output-style values from deterministic defaults.
E: Legacy specs without an objective still normalize cleanly from mission-derived defaults.
"""
def normalize_agent_objective(raw_objective: any, default_objective: dict[str, any]) -> dict[str, any] {
    objective: dict[str, any] = {};
    if isinstance(raw_objective, dict) {
        objective = sanitize_json_value(raw_objective, 3, 8, 220);
    }

    primary_goal: str = safe_text(objective.get("primary_goal", ""), 1400) or safe_text(default_objective.get("primary_goal", ""), 1400);
    success_definition: str = safe_text(objective.get("success_definition", ""), 420) or safe_text(default_objective.get("success_definition", ""), 420);
    output_style: str = safe_text(objective.get("output_style", ""), 40) or safe_text(default_objective.get("output_style", ""), 40);

    return {
        "primary_goal": primary_goal,
        "success_definition": success_definition,
        "output_style": output_style
    };
}

"""R: Normalize persisted task requirements into one strict helper-runtime schema.
M: Coerces booleans and freshness windows while preserving the project-wide read-only guarantee.
E: Missing legacy requirement blocks fall back to deterministic defaults derived from the saved mission.
"""
def normalize_agent_requirements(raw_requirements: any, defaults: dict[str, any]) -> dict[str, any] {
    requirements: dict[str, any] = {};
    if isinstance(raw_requirements, dict) {
        requirements = sanitize_json_value(raw_requirements, 3, 10, 180);
    }

    freshness_required: bool = bool(requirements.get("freshness_required", defaults.get("freshness_required", False)));
    freshness_window: str = safe_text(requirements.get("freshness_window", ""), 32) or safe_text(defaults.get("freshness_window", ""), 32);
    if freshness_required and not freshness_window {
        freshness_window = "48h";
    }

    return {
        "freshness_required": freshness_required,
        "freshness_window": freshness_window,
        "needs_search": bool(requirements.get("needs_search", defaults.get("needs_search", False))),
        "needs_current_page_context": bool(requirements.get("needs_current_page_context", defaults.get("needs_current_page_context", False))),
        "needs_multi_source_synthesis": bool(requirements.get("needs_multi_source_synthesis", defaults.get("needs_multi_source_synthesis", False))),
        "needs_monitoring": bool(requirements.get("needs_monitoring", defaults.get("needs_monitoring", False))),
        "read_only": bool(requirements.get("read_only", defaults.get("read_only", True)))
    };
}

"""R: Normalize persisted helper constraints into one compact runtime contract.
M: Coerces bounded integers and read-only safety flags from stored JSON.
E: Invalid numeric values fall back to conservative defaults rather than widening runtime scope.
"""
def normalize_agent_constraints(raw_constraints: any, defaults: dict[str, any]) -> dict[str, any] {
    constraints: dict[str, any] = {};
    if isinstance(raw_constraints, dict) {
        constraints = sanitize_json_value(raw_constraints, 3, 10, 180);
    }

    max_sources: int = defaults.get("max_sources", 0) if isinstance(defaults.get("max_sources", 0), int) else 0;
    if isinstance(constraints.get("max_sources", 0), int) {
        max_sources = constraints.get("max_sources", 0);
    }

    max_output_items: int = defaults.get("max_output_items", 5) if isinstance(defaults.get("max_output_items", 5), int) else 5;
    if isinstance(constraints.get("max_output_items", 0), int) {
        max_output_items = constraints.get("max_output_items", 0);
    }

    max_output_chars: int = defaults.get("max_output_chars", 1200) if isinstance(defaults.get("max_output_chars", 1200), int) else 1200;
    if isinstance(constraints.get("max_output_chars", 0), int) {
        max_output_chars = constraints.get("max_output_chars", 0);
    }

    return {
        "max_sources": max_sources,
        "max_output_items": max_output_items,
        "max_output_chars": max_output_chars,
        "disallow_destructive_actions": bool(constraints.get("disallow_destructive_actions", defaults.get("disallow_destructive_actions", True))),
        "disallow_auth_writes": bool(constraints.get("disallow_auth_writes", defaults.get("disallow_auth_writes", True)))
    };
}

"""R: Normalize persisted capabilities into a deterministic unique list.
M: Filters non-string values, trims entries, and preserves insertion order.
E: Empty or invalid inputs return an empty list so legacy specs can keep using fallback execution.
"""
def normalize_agent_capabilities(raw_capabilities: any) -> list[str] {
    capabilities: list[str] = [];
    if not isinstance(raw_capabilities, list) {
        return capabilities;
    }

    for capability in raw_capabilities {
        append_capability(capabilities, str(capability));
    }
    return capabilities;
}

"""R: Normalize persisted agent-plan steps so runtime execution can trust the saved schema.
M: Keeps only bounded step ids, types, inputs, queries, and params for each explicit plan step.
E: Invalid steps are skipped rather than poisoning plan-driven execution.
"""
def normalize_agent_plan(raw_plan: any) -> list[any] {
    plan: list[any] = [];
    if not isinstance(raw_plan, list) {
        return plan;
    }

    count: int = 0;
    for raw_step in raw_plan {
        if count >= 16 or not isinstance(raw_step, dict) {
            continue;
        }

        step_type: str = safe_text(raw_step.get("type", ""), 60);
        if not step_type {
            continue;
        }

        step_id: str = safe_text(raw_step.get("step_id", ""), 80);
        if not step_id {
            step_id = "step_" + str(count + 1);
        }

        normalized_step: dict[str, any] = {
            "step_id": step_id,
            "type": step_type
        };

        input_from: str = safe_text(raw_step.get("input_from", ""), 80);
        if input_from {
            normalized_step["input_from"] = input_from;
        }

        query: str = safe_text(raw_step.get("query", ""), 320);
        if query {
            normalized_step["query"] = query;
        }

        raw_params: any = raw_step.get("params", {});
        if isinstance(raw_params, dict) and len(raw_params) > 0 {
            normalized_step["params"] = sanitize_json_value(raw_params, 3, 10, 180);
        }

        plan.append(normalized_step);
        count += 1;
    }

    return plan;
}

"""R: Normalize one helper definition read from disk or built from input.
M: Reconstructs required fields, clamps optional payloads, and restores a stable user-definition block.
E: Records missing critical ids or user-facing fields normalize to the empty dict.
"""
def normalize_helper_definition(candidate: any) -> dict[str, any] {
    if not isinstance(candidate, dict) {
        return {};
    }

    helper_id: str = safe_text(candidate.get("helper_id", ""), 80);
    name: str = safe_text(candidate.get("name", ""), 140);
    goal: str = normalize_instruction_text(candidate.get("goal", ""), 2000);
    agent_spec_id: str = safe_text(candidate.get("agent_spec_id", ""), 80);
    if not helper_id or not name or not goal or not agent_spec_id {
        return {};
    }

    frequency: str = normalize_helper_frequency(candidate.get("frequency", "once"));
    runtime_version: str = normalize_runtime_version(candidate.get("runtime_version", "v1"));
    created_at: str = safe_text(candidate.get("created_at", ""), 32) or timestamp_now();
    updated_at: str = safe_text(candidate.get("updated_at", ""), 32) or created_at;
    status: str = normalize_helper_status(candidate.get("status", "active"));

    source_context: dict[str, any] = {};
    raw_source_context: any = candidate.get("source_context", {});
    if isinstance(raw_source_context, dict) {
        source_context = sanitize_json_value(raw_source_context, 4, 12, 220);
    }

    user_definition: dict[str, any] = {};
    raw_user_definition: any = candidate.get("user_definition", {});
    if isinstance(raw_user_definition, dict) {
        user_definition = sanitize_json_value(raw_user_definition, 3, 8, 220);
    }
    if not user_definition {
        user_definition = {
            "name": name,
            "goal": goal,
            "frequency": frequency
        };
    }

    return {
        "helper_id": helper_id,
        "name": name,
        "goal": goal,
        "frequency": frequency,
        "runtime_version": runtime_version,
        "created_at": created_at,
        "updated_at": updated_at,
        "status": status,
        "agent_spec_id": agent_spec_id,
        "user_definition": user_definition,
        "source_context": source_context
    };
}

"""R: Normalize one backend-owned agent spec so helper runtime code sees a strict schema.
M: Validates ids and enum-like fields, then sanitizes nested policies without changing ownership boundaries.
E: Missing critical fields normalize to the empty dict so corrupted specs never execute.
"""
def normalize_agent_spec(candidate: any) -> dict[str, any] {
    if not isinstance(candidate, dict) {
        return {};
    }

    agent_spec_id: str = safe_text(candidate.get("agent_spec_id", ""), 80);
    helper_id: str = safe_text(candidate.get("helper_id", ""), 80);
    mission: str = safe_text(candidate.get("mission", ""), 2200);
    if not agent_spec_id or not helper_id or not mission {
        return {};
    }

    kind: str = normalize_helper_kind(candidate.get("kind", "browser_read"));
    runtime_mode: str = normalize_runtime_mode(candidate.get("runtime_mode", "browser_read"));
    version: str = safe_text(candidate.get("version", ""), 16) or "1.0";
    goal_text: str = normalize_instruction_text(candidate.get("goal_text", ""), 1600);
    inference_text: str = goal_text or mission;
    inferred_requirements: dict[str, any] = infer_task_requirements(inference_text, kind);
    requirements: dict[str, any] = normalize_agent_requirements(candidate.get("requirements", {}), inferred_requirements);
    default_objective: dict[str, any] = infer_objective("", inference_text, kind, requirements);
    objective: dict[str, any] = normalize_agent_objective(candidate.get("objective", {}), default_objective);
    default_constraints: dict[str, any] = infer_constraints(kind, requirements);
    constraints: dict[str, any] = normalize_agent_constraints(candidate.get("constraints", {}), default_constraints);

    trigger: dict[str, any] = {};
    raw_trigger: any = candidate.get("trigger", {});
    if isinstance(raw_trigger, dict) {
        trigger = sanitize_json_value(raw_trigger, 3, 8, 180);
    }
    if not trigger {
        trigger = {
            "frequency": "once",
            "label": helper_frequency_label("once"),
            "trigger_type": "manual_or_scheduled"
        };
    }

    browser_policy: dict[str, any] = {};
    if isinstance(candidate.get("browser_policy", {}), dict) {
        browser_policy = sanitize_json_value(candidate.get("browser_policy", {}), 4, 18, 220);
    }
    if not browser_policy {
        browser_policy = infer_browser_policy(kind);
    }

    tool_policy: dict[str, any] = {};
    if isinstance(candidate.get("tool_policy", {}), dict) {
        tool_policy = sanitize_json_value(candidate.get("tool_policy", {}), 4, 18, 220);
    }
    if not tool_policy {
        tool_policy = infer_tool_policy();
    }

    memory_policy: dict[str, any] = {};
    if isinstance(candidate.get("memory_policy", {}), dict) {
        memory_policy = sanitize_json_value(candidate.get("memory_policy", {}), 4, 18, 220);
    }
    if not memory_policy {
        memory_policy = infer_memory_policy(str(trigger.get("frequency", "once")));
    }

    execution_policy: dict[str, any] = {};
    if isinstance(candidate.get("execution_policy", {}), dict) {
        execution_policy = sanitize_json_value(candidate.get("execution_policy", {}), 4, 18, 220);
    }
    if not execution_policy {
        execution_policy = infer_execution_policy(kind);
    }

    output_contract: dict[str, any] = {};
    if isinstance(candidate.get("output_contract", {}), dict) {
        output_contract = sanitize_json_value(candidate.get("output_contract", {}), 4, 18, 220);
    }
    if not output_contract {
        output_contract = infer_output_contract(kind, requirements);
    }

    capabilities: list[str] = normalize_agent_capabilities(candidate.get("capabilities", []));
    if len(capabilities) == 0 {
        capabilities = select_capabilities(inference_text, kind, requirements);
    }

    plan: list[any] = normalize_agent_plan(candidate.get("plan", []));
    for step in plan {
        if not isinstance(step, dict) {
            continue;
        }
        append_capability(capabilities, safe_text(step.get("type", ""), 60));
    }

    return {
        "agent_spec_id": agent_spec_id,
        "helper_id": helper_id,
        "goal_text": goal_text,
        "kind": kind,
        "mission": mission,
        "runtime_mode": runtime_mode,
        "objective": objective,
        "requirements": requirements,
        "constraints": constraints,
        "capabilities": capabilities,
        "plan": plan,
        "trigger": trigger,
        "browser_policy": browser_policy,
        "tool_policy": tool_policy,
        "memory_policy": memory_policy,
        "execution_policy": execution_policy,
        "output_contract": output_contract,
        "read_only": bool(candidate.get("read_only", True)),
        "version": version
    };
}

"""R: Normalize one persisted helper run into the strict backend schema consumed by UI and runtime code.
M: Validates ids and status fields, then bounds nested structured output, logs, errors, and runtime state.
E: Incomplete or corrupted run records normalize to the empty dict so callers can ignore them safely.
"""
def normalize_helper_run(candidate: any) -> dict[str, any] {
    if not isinstance(candidate, dict) {
        return {};
    }

    run_id: str = safe_text(candidate.get("run_id", ""), 80);
    helper_id: str = safe_text(candidate.get("helper_id", ""), 80);
    agent_spec_id: str = safe_text(candidate.get("agent_spec_id", ""), 80);
    started_at: str = safe_text(candidate.get("started_at", ""), 32);
    if not run_id or not helper_id or not agent_spec_id or not started_at {
        return {};
    }

    finished_at: str = safe_text(candidate.get("finished_at", ""), 32);
    status: str = normalize_run_status(candidate.get("status", "failed"));
    trigger_type: str = safe_text(candidate.get("trigger_type", ""), 40) or "manual";
    browser_session_id: str = safe_text(candidate.get("browser_session_id", ""), 120);
    summary: str = safe_text(candidate.get("summary", ""), 4000);

    structured_output: any = sanitize_json_value(candidate.get("structured_output", {}), 7, 40, 260);
    runtime_state: any = sanitize_json_value(candidate.get("runtime_state", {}), 7, 40, 260);
    logs: list[str] = normalize_text_list(candidate.get("logs", []), 48, 240);
    errors: list[str] = normalize_text_list(candidate.get("errors", []), 24, 240);

    return {
        "run_id": run_id,
        "helper_id": helper_id,
        "agent_spec_id": agent_spec_id,
        "started_at": started_at,
        "finished_at": finished_at,
        "status": status,
        "trigger_type": trigger_type,
        "browser_session_id": browser_session_id,
        "summary": summary,
        "structured_output": structured_output,
        "runtime_state": runtime_state,
        "logs": logs,
        "errors": errors
    };
}

def load_helper_definition(helper_id: str) -> dict[str, any] {
    return normalize_helper_definition(read_json_file(helper_file(helper_id)));
}

def load_agent_spec(agent_spec_id: str) -> dict[str, any] {
    return normalize_agent_spec(read_json_file(agent_spec_file(agent_spec_id)));
}

def load_helper_run(run_id: str) -> dict[str, any] {
    return normalize_helper_run(read_json_file(helper_run_file(run_id)));
}

"""R: Sort helper-layer records newest-first without relying on external runtime helpers.
M: Uses a simple in-place selection sort over one timestamp-like string field.
E: Missing field values naturally sink toward the end of the returned list.
"""
def sort_records_by_field_desc(records: list[any], field_name: str) -> list[any] {
    items: list[any] = [];
    for record in records {
        items.append(record);
    }

    size: int = len(items);
    i: int = 0;
    while i < size {
        best_index: int = i;
        j: int = i + 1;
        while j < size {
            left_value: str = "";
            right_value: str = "";
            if isinstance(items[best_index], dict) {
                left_value = safe_text(items[best_index].get(field_name, ""), 40);
            }
            if isinstance(items[j], dict) {
                right_value = safe_text(items[j].get(field_name, ""), 40);
            }
            if right_value > left_value {
                best_index = j;
            }
            j += 1;
        }

        if best_index != i {
            temp: any = items[i];
            items[i] = items[best_index];
            items[best_index] = temp;
        }
        i += 1;
    }

    return items;
}

"""R: Load all persisted runs for one helper so history can be listed and summarized.
M: Reads every run file, keeps only matching helper ids, and returns newest-first records.
E: Invalid run files are skipped rather than aborting the helper history request.
"""
def load_runs_for_helper(helper_id: str) -> list[any] {
    runs: list[any] = [];
    for raw_run in list_json_records(HELPER_RUN_DIR) {
        normalized_run: dict[str, any] = normalize_helper_run(raw_run);
        if not normalized_run {
            continue;
        }
        if str(normalized_run.get("helper_id", "")) == helper_id {
            runs.append(normalized_run);
        }
    }

    return sort_records_by_field_desc(runs, "started_at");
}

def latest_run_for_helper(helper_id: str) -> dict[str, any] {
    runs: list[any] = load_runs_for_helper(helper_id);
    if len(runs) > 0 and isinstance(runs[0], dict) {
        return runs[0];
    }
    return {};
}

"""R: Bundle a helper definition with its agent spec and latest run for API responses.
M: Keeps storage records separate on disk while returning one ergonomic backend view for renderer consumers.
E: Missing agent specs or run history still return a valid helper view with empty nested payloads.
"""
def helper_bundle(helper: dict[str, any], agent_spec: dict[str, any], latest_run: dict[str, any] = {}) -> dict[str, any] {
    return {
        "helper": helper,
        "agent_spec": agent_spec,
        "latest_run": latest_run
    };
}

"""R: Build the compact helper bundle used by the renderer list refresh path.
M: Keeps full helper definition fields but trims agent spec and latest run down to the stable UI fields the Electron shell actually reads.
E: Missing nested data collapses to empty dicts so list responses stay small without breaking helpers that have never run.
"""
def helper_list_bundle(helper: dict[str, any], agent_spec: dict[str, any], latest_run: dict[str, any] = {}) -> dict[str, any] {
    compact_agent_spec: dict[str, any] = {
        "kind": safe_text(agent_spec.get("kind", ""), 40),
        "read_only": bool(agent_spec.get("read_only", True))
    };

    compact_latest_run: dict[str, any] = {};
    if isinstance(latest_run, dict) and latest_run {
        compact_latest_run = {
            "run_id": safe_text(latest_run.get("run_id", ""), 80),
            "helper_id": safe_text(latest_run.get("helper_id", ""), 80),
            "started_at": safe_text(latest_run.get("started_at", ""), 40),
            "finished_at": safe_text(latest_run.get("finished_at", ""), 40),
            "status": safe_text(latest_run.get("status", ""), 40),
            "trigger_type": safe_text(latest_run.get("trigger_type", ""), 40),
            "browser_session_id": safe_text(latest_run.get("browser_session_id", ""), 120),
            "summary": safe_text(latest_run.get("summary", ""), 1200),
            "structured_output": sanitize_json_value(latest_run.get("structured_output", {}), 2, 6, 180),
            "runtime_state": sanitize_json_value(latest_run.get("runtime_state", {}), 2, 6, 180),
            "errors": sanitize_json_value(latest_run.get("errors", []), 1, 4, 180)
        };
    }

    return {
        "helper": helper,
        "agent_spec": compact_agent_spec,
        "latest_run": compact_latest_run
    };
}

"""R: Validate and normalize the simple Create Helper payload before inference runs.
M: Requires name and goal, normalizes frequency, and preserves optional source context for future evolution.
E: Validation fails fast on blank name or goal so partial helpers never get persisted.
"""
def validate_create_helper_payload(payload: dict[str, any]) -> dict[str, any] {
    name: str = safe_text(payload.get("name", ""), 140);
    goal: str = safe_text(payload.get("goal", ""), 2000);
    frequency: str = normalize_helper_frequency(payload.get("frequency", "once"));
    if not name {
        return {"ok": False, "error": "name is required"};
    }
    if not goal {
        return {"ok": False, "error": "goal is required"};
    }

    source_context: dict[str, any] = {};
    raw_source_context: any = payload.get("source_context", {});
    if isinstance(raw_source_context, dict) {
        source_context = sanitize_json_value(raw_source_context, 4, 12, 220);
    }

    runtime_version: str = "";
    if "runtime_version" in payload {
        runtime_version = safe_text(payload.get("runtime_version", ""), 16).lower();
        if runtime_version and runtime_version not in VALID_RUNTIME_VERSIONS {
            return {"ok": False, "error": "runtime_version must be v1 or v2"};
        }
    }

    return {
        "ok": True,
        "name": name,
        "goal": goal,
        "frequency": frequency,
        "source_context": source_context,
        "runtime_version": runtime_version
    };
}

"""R: Create one persisted helper definition plus backend-owned agent spec from the simple UI contract.
M: Validates input, applies deterministic inference, writes both records to disk, and returns the bundled result.
E: Spec inference remains Jac-owned even when LLM runtime metadata is present, so persistence always uses the strict schema.
"""
def create_helper(payload: dict[str, any]) -> dict[str, any] {
    ensure_helper_dirs();
    validation: dict[str, any] = validate_create_helper_payload(payload);
    if not bool(validation.get("ok", False)) {
        return validation;
    }

    helper_id: str = new_helper_id();
    name: str = str(validation.get("name", ""));
    goal: str = str(validation.get("goal", ""));
    frequency: str = str(validation.get("frequency", "once"));
    now: str = timestamp_now();

    agent_spec: dict[str, any] = normalize_agent_spec(build_agent_spec(helper_id, name, goal, frequency));
    if not agent_spec {
        return {"ok": False, "error": "agent spec normalization failed"};
    }

    runtime_version: str = resolve_helper_runtime_version(validation.get("runtime_version", ""), agent_spec);

    helper: dict[str, any] = normalize_helper_definition({
        "helper_id": helper_id,
        "name": name,
        "goal": goal,
        "frequency": frequency,
        "runtime_version": runtime_version,
        "created_at": now,
        "updated_at": now,
        "status": "active",
        "agent_spec_id": str(agent_spec.get("agent_spec_id", "")),
        "user_definition": {
            "name": name,
            "goal": goal,
            "frequency": frequency
        },
        "source_context": validation.get("source_context", {})
    });
    if not helper {
        return {"ok": False, "error": "helper normalization failed"};
    }

    write_json_file(agent_spec_file(str(agent_spec.get("agent_spec_id", ""))), agent_spec);
    write_json_file(helper_file(helper_id), helper);

    return {
        "ok": True,
        "helper_id": helper_id,
        "agent_spec_id": str(agent_spec.get("agent_spec_id", "")),
        "runtime_version": runtime_version,
        "helper_bundle": helper_bundle(helper, agent_spec, {})
    };
}

"""R: List all persisted helpers for renderer workspace and task-launcher views.
M: Loads definitions, resolves each linked agent spec, adds latest run metadata, and returns newest-first bundles.
E: Helpers with missing specs are skipped so partially corrupted records do not break the whole list endpoint.
"""
def list_helpers(payload: dict[str, any]) -> dict[str, any] {
    ensure_helper_dirs();
    filter_status: str = safe_text(payload.get("status", ""), 24).lower();
    bundles: list[any] = [];

    helpers: list[any] = [];
    for raw_helper in list_json_records(HELPER_DEF_DIR) {
        helper: dict[str, any] = normalize_helper_definition(raw_helper);
        if not helper {
            continue;
        }
        if filter_status and str(helper.get("status", "")) != filter_status {
            continue;
        }
        helpers.append(helper);
    }

    helpers = sort_records_by_field_desc(helpers, "updated_at");
    for helper in helpers {
        agent_spec: dict[str, any] = load_agent_spec(str(helper.get("agent_spec_id", "")));
        if not agent_spec {
            continue;
        }
        bundles.append(helper_list_bundle(helper, agent_spec, latest_run_for_helper(str(helper.get("helper_id", "")))));
    }

    return {"ok": True, "helpers": bundles, "count": len(bundles)};
}

"""R: Fetch one helper plus its system spec and most recent run metadata.
M: Loads the definition, resolves the linked agent spec, and returns one bundled record.
E: Missing helper ids or unknown records return explicit errors instead of empty success payloads.
"""
def get_helper(payload: dict[str, any]) -> dict[str, any] {
    helper_id: str = safe_text(payload.get("helper_id", ""), 80);
    if not helper_id {
        return {"ok": False, "error": "helper_id is required"};
    }

    helper: dict[str, any] = load_helper_definition(helper_id);
    if not helper {
        return {"ok": False, "error": "helper not found", "helper_id": helper_id};
    }

    agent_spec: dict[str, any] = load_agent_spec(str(helper.get("agent_spec_id", "")));
    if not agent_spec {
        return {"ok": False, "error": "agent spec not found", "helper_id": helper_id};
    }

    return {
        "ok": True,
        "helper_bundle": helper_bundle(helper, agent_spec, latest_run_for_helper(helper_id))
    };
}

def add_unique_text(values: list[str], raw_value: any, max_len: int = 180) {
    text: str = safe_text(raw_value, max_len);
    if not text {
        return;
    }
    if text not in values {
        values.append(text);
    }
}

"""R: Derive a host/domain from one browser URL for browser-state normalization.
M: Uses `urlparse` and falls back to the empty string on malformed values.
E: Empty or invalid URLs return the empty string instead of raising.
"""
def domain_from_url(raw_url: any) -> str {
    url_value: str = safe_text(raw_url, 400);
    if not url_value {
        return "";
    }

    try {
        parsed: any = urlparse(url_value);
        return safe_text(parsed.netloc or parsed.path or "", 180);
    } except ValueError {
        return "";
    }
}

def normalize_search_limit(raw_limit: any, fallback: int = 8) -> int {
    limit: int = fallback;
    if isinstance(raw_limit, int) {
        limit = raw_limit;
    }
    if limit < 1 {
        return 1;
    }
    if limit > 10 {
        return 10;
    }
    return limit;
}

"""R: Normalize one URL into a lowercase path so ranking and extraction heuristics can reason about page shape.
M: Parses the URL with stdlib helpers and falls back to the raw text when only a path-like value is available.
E: Invalid URLs return `/` for empty input or the bounded raw value when parsing cannot recover a path.
"""
def url_path_from_value(raw_url: any) -> str {
    url_value: str = safe_text(raw_url, 500);
    if not url_value {
        return "/";
    }

    try {
        parsed: any = urlparse(url_value);
        path_value: str = safe_text(parsed.path or "", 260).lower();
        if path_value {
            return path_value;
        }
        if url_value.startswith("/") {
            return safe_text(url_value, 260).lower();
        }
    } except ValueError {
        if url_value.startswith("/") {
            return safe_text(url_value, 260).lower();
        }
    }

    return "/";
}

"""R: Split one normalized URL path into skimmable segments for source-quality heuristics.
M: Trims slash-separated path parts, lowercases them, and removes empty segments.
E: Empty or root-only paths return an empty list.
"""
def path_segments(raw_path: any) -> list[str] {
    segments: list[str] = [];
    path_value: str = safe_text(raw_path, 260).lower();
    for raw_segment in path_value.split("/") {
        segment: str = safe_text(raw_segment, 80).lower();
        if segment {
            segments.append(segment);
        }
    }
    return segments;
}

"""R: Detect date-like URL segments that often indicate concrete reporting pages instead of hubs.
M: Matches common `/YYYY/MM/DD/` and slug-style date fragments inside normalized paths.
E: Non-date numeric segments simply return `False` instead of over-boosting arbitrary ids.
"""
def path_has_date_signal(raw_path: any) -> bool {
    path_value: str = safe_text(raw_path, 260).lower();
    if not path_value {
        return False;
    }
    if re.search(r"/20\d{2}/\d{1,2}/\d{1,2}(?:/|$)", path_value) {
        return True;
    }
    if re.search(r"(?:^|/)(20\d{2}-\d{2}-\d{2}|20\d{2}[/-]\d{1,2})(?:/|$|-)", path_value) {
        return True;
    }
    return False;
}

"""R: Detect URL path slugs that look like topic-category pages rather than specific story pages.
M: Checks known subject-area slug patterns, aggregation-URL formats, and generic news-hub slug endings.
E: Slugs containing specific company names, years, or concrete product terms return False so legitimate articles are not penalized.
"""
def path_slug_is_topic_area(raw_slug: any) -> bool {
    slug: str = safe_text(raw_slug, 120).lower().strip("-_");
    if not slug {
        return False;
    }

    if slug in [
        "artificial-intelligence",
        "artificial_intelligence",
        "machine-learning",
        "machine_learning",
        "deep-learning",
        "deep_learning",
        "natural-language-processing",
        "generative-ai",
        "generative_ai",
        "ai-and-machine-learning",
        "computers_math",
        "computers-math"
    ] {
        return True;
    }

    if re.search(r"^latest[-_].+[-_](news|updates)$", slug) {
        return True;
    }
    if re.search(r"^.+[-_](news[-_]and[-_]updates|news[-_]updates)$", slug) {
        return True;
    }
    if (slug.endswith("-news") or slug.endswith("_news")) and not re.search(r"20\d{2}", slug) {
        return True;
    }

    return False;
}

"""R: Identify homepage, topic, and archive-like URL shapes that usually lead to index pages rather than articles.
M: Checks normalized path segments against a compact list of hub markers and exact hub paths, and detects topic-area slug endings.
E: Paths with a date signal are treated as dated articles and return False even when other segment patterns would otherwise match.
"""
def url_looks_hub_like(raw_url: any) -> bool {
    path_value: str = url_path_from_value(raw_url);
    if path_value == "/" {
        return True;
    }

    if path_has_date_signal(path_value) {
        return False;
    }

    if path_value in [
        "/news",
        "/news/",
        "/category",
        "/category/",
        "/categories",
        "/categories/",
        "/tag",
        "/tag/",
        "/tags",
        "/tags/",
        "/topic",
        "/topic/",
        "/topics",
        "/topics/",
        "/archive",
        "/archive/",
        "/latest",
        "/latest/"
    ] {
        return True;
    }

    segments: list[str] = path_segments(path_value);
    if len(segments) == 0 {
        return True;
    }
    if len(segments) <= 2 {
        for segment in segments {
            if segment in ["category", "categories", "tag", "tags", "topic", "topics", "archive", "latest"] {
                return True;
            }
        }
    }

    last_segment: str = segments[len(segments) - 1] if len(segments) > 0 else "";
    if last_segment and len(segments) <= 3 and path_slug_is_topic_area(last_segment) {
        return True;
    }

    return False;
}

"""R: Detect article-like URL shapes so ranking can reward concrete stories over generic hubs.
M: Looks for deeper paths, date markers, article/story slugs, and descriptive hyphenated endpoints.
E: Hub-like URLs return `False` even if they contain long text because landing pages often do too.
"""
def url_looks_article_like(raw_url: any) -> bool {
    path_value: str = url_path_from_value(raw_url);
    if url_looks_hub_like(path_value) {
        return False;
    }

    segments: list[str] = path_segments(path_value);
    if path_has_date_signal(path_value) {
        return True;
    }
    if "/article/" in path_value or "/story/" in path_value {
        return True;
    }
    if len(segments) >= 3 {
        return True;
    }
    if len(segments) == 0 {
        return False;
    }

    last_segment: str = segments[len(segments) - 1];
    if "-" in last_segment and len(last_segment) >= 14 {
        return True;
    }
    return False;
}

"""R: Detect generic news-hub titles that should lose to concrete article headlines during ranking and synthesis.
M: Normalizes punctuation and compares against a small set of generic title patterns plus loose hub-style regexes.
E: Specific headlines with entities or event verbs are allowed through even when they mention news.
"""
def title_looks_hub_like(raw_title: any) -> bool {
    title_value: str = safe_text(raw_title, 240).lower();
    if not title_value {
        return False;
    }

    normalized_title: str = re.sub(r"[^a-z0-9\s]", " ", title_value);
    normalized_title = " ".join(normalized_title.split());
    if normalized_title in [
        "ai news",
        "latest ai news",
        "artificial intelligence news",
        "latest updates",
        "news"
    ] {
        return True;
    }

    if re.search(r"^(ai news|latest ai news|artificial intelligence news)(?:\s*[:|\-].*)?$", title_value) {
        if not re.search(r"\b(openai|google|meta|microsoft|anthropic|amazon|nvidia|xai|lawsuit|launch|launched|release|released|update|updated|deal|partnership|acquire|acquires|funding)\b", title_value) {
            return True;
        }
    }

    if normalized_title in ["artificial intelligence latest", "artificial intelligence latest news"] {
        return True;
    }

    if re.search(r"\b(ai|artificial intelligence)\b", normalized_title) and re.search(r"\b(latest|news|updates|breakthroughs|coverage|analysis)\b", normalized_title) {
        if not text_has_concrete_reporting_signals(normalized_title) {
            return True;
        }
    }

    if re.search(r"\b(latest|news|updates)\b", normalized_title) and re.search(r"\b(hub|roundup|round up|digest|briefing)\b", normalized_title) {
        return True;
    }

    return False;
}

"""R: Detect provider, search, and generic error copy that should never feed synthesized helper summaries.
M: Matches a compact set of error-page phrases seen in search providers and failed content pages after normalizing whitespace.
E: Returns `False` for normal article troubleshooting coverage because multiple explicit error signals are required.
"""
def text_looks_error_page(raw_text: any) -> bool {
    text_value: str = " ".join(str(raw_text or "").lower().split());
    if not text_value {
        return False;
    }

    if re.search(r"\boops[,! ]+there was an error\b", text_value) {
        return True;
    }
    if re.search(r"\b(error|unable|failed)\b", text_value) and re.search(r"\b(please try again|try again later|something went wrong|request could not be completed)\b", text_value) {
        return True;
    }
    if re.search(r"\b(access denied|forbidden|service unavailable|temporarily unavailable|too many requests|captcha)\b", text_value) {
        return True;
    }
    if re.search(r"\b(enable javascript|browser is unsupported|verify you are human)\b", text_value) {
        return True;
    }

    return False;
}

"""R: Detect generic news-landing copy that talks about “latest updates” without concrete reporting signals.
M: Looks for AI-news roundup language and rejects it when the text lacks entities, events, or article-specific specificity.
E: Concrete headlines that happen to mention updates still return `False` because specificity beats generic news wording.
"""
def text_looks_generic_news_landing(raw_text: any) -> bool {
    text_value: str = " ".join(str(raw_text or "").lower().split());
    if not text_value {
        return False;
    }

    mentions_ai: bool = bool(re.search(r"\b(ai|artificial intelligence|machine learning|robotics)\b", text_value));
    mentions_generic_news: bool = bool(re.search(r"\b(latest|news|updates|breakthroughs|coverage|analysis|headlines)\b", text_value));
    if not mentions_ai or not mentions_generic_news {
        return False;
    }

    if re.search(r"\b(stay updated|get the latest|latest ai news|latest ai news and updates|ai breakthroughs that matter most)\b", text_value) {
        if not text_has_concrete_reporting_signals(text_value) {
            return True;
        }
    }

    if mentions_ai and mentions_generic_news and not text_has_concrete_reporting_signals(text_value) {
        if re.search(r"\b(roundup|round up|hub|digest|section|topic|category)\b", text_value) {
            return True;
        }
    }

    return False;
}

"""R: Detect marketing-heavy landing-page copy so helper summaries do not quote slogans as factual findings.
M: Requires promotional phrasing plus either a CTA or broad product-language signals while also lacking article specificity.
E: Product launch articles are preserved because concrete entities and event verbs keep this classifier `False`.
"""
def text_looks_marketing_landing(raw_text: any) -> bool {
    text_value: str = " ".join(str(raw_text or "").lower().split());
    if not text_value or text_has_concrete_reporting_signals(text_value) {
        return False;
    }

    if re.search(r"\b(step into the future|transform|elevate|unlock|reimagine|discover|explore)\b", text_value) and re.search(r"\b(cx|customer experience|platform|solution|product|brand|team)\b", text_value) {
        return True;
    }
    if re.search(r"\b(book a demo|request a demo|talk to sales|contact sales|learn more|get started)\b", text_value) {
        return True;
    }
    if re.search(r"\b(customer experience|platform|solution|workflow automation)\b", text_value) and re.search(r"\b(latest ai news|latest updates|breakthroughs that matter most)\b", text_value) {
        return True;
    }

    return False;
}

"""R: Detect concrete event or entity signals that make text feel like reporting instead of generic roundup copy.
M: Matches reporting verbs and named companies or model families while intentionally ignoring year-only freshness cues.
E: Returns `False` for date-only headlines so generic “latest AI news 2026” pages still classify as low-signal.
"""
def text_has_concrete_reporting_signals(raw_text: any) -> bool {
    text_value: str = safe_text(raw_text, 360).lower();
    if not text_value {
        return False;
    }

    if re.search(
        r"\b(announced|launch|launched|release|released|update|updated|unveiled|raises|raising|funding|acquires|acquired|partnership|deal|lawsuit|probe|pricing|enterprise|benchmark|rollout|regulator|safety)\b",
        text_value
    ) {
        return True;
    }
    if re.search(r"\b(openai|google|meta|microsoft|anthropic|amazon|nvidia|xai|tesla|apple|claude|gemini|llama|gpt[- ]?\d)\b", text_value) {
        return True;
    }
    return False;
}

"""R: Detect concrete entity and event language that usually marks a story headline or substantive snippet.
M: Looks for reporting verbs, notable company names, model names, and date or version markers in the text.
E: Generic promotional text returns `False` so ranking does not confuse “latest updates” copy for reporting.
"""
def text_has_specificity_signals(raw_text: any) -> bool {
    text_value: str = safe_text(raw_text, 360).lower();
    if not text_value {
        return False;
    }

    if text_has_concrete_reporting_signals(text_value) {
        return True;
    }
    if re.search(r"\b20\d{2}\b", text_value) {
        return True;
    }
    return False;
}

"""R: Filter code, config, and site-shell lines out of fetched page content before summarization.
M: Uses lightweight regex checks for JS/CSS payloads, tracking blobs, long tokens, and navigation boilerplate.
E: Legitimate prose lines remain eligible even if they contain a few symbols or one short URL.
"""
def line_should_drop_from_content(raw_line: any) -> bool {
    line: str = " ".join(str(raw_line or "").split());
    if not line {
        return True;
    }

    lowered: str = line.lower();
    if re.search(
        r"(window\.datalayer|webfont\.load|googletagmanager|gtag\(|__next_data__|webpack|font-family|font-weight|cookieconsent|application/ld\+json|function\s*\(|=>)",
        lowered
    ) {
        return True;
    }
    if re.search(r"(privacy policy|terms of use|all rights reserved|subscribe now|sign up for|skip to (main )?content|enable javascript)", lowered) {
        return True;
    }
    if re.search(r"[A-Za-z0-9+/]{45,}", line) {
        return True;
    }
    if (line.count(";") >= 2 or line.count("=") >= 3) and ("{" in line or "}" in line or ":" in line) {
        return True;
    }
    if "{" in line and "}" in line and (":" in line or ";" in line) {
        return True;
    }
    if len(line) > 320 and not re.search(r"[.!?]", line) {
        return True;
    }

    alpha_matches: any = re.findall(r"[A-Za-z]", line);
    if len(alpha_matches) < 12 and len(line) > 40 {
        return True;
    }

    longest_token: int = 0;
    for token in line.split() {
        if len(token) > longest_token {
            longest_token = len(token);
        }
    }
    if longest_token >= 48 and not re.search(r"[.!?]", line) {
        return True;
    }

    return False;
}

"""R: Decide whether cleaned text is substantive enough to support article-level synthesis.
M: Rejects payload-like lines, then requires enough natural-language words and alphabetic density.
E: Short titles and labels return `False` so summaries do not mistake headings for extracted content.
"""
def text_is_substantive_content(raw_text: any) -> bool {
    text_value: str = " ".join(str(raw_text or "").split());
    if not text_value or line_should_drop_from_content(text_value) {
        return False;
    }

    words: list[str] = [];
    for token in text_value.split() {
        cleaned_token: str = safe_text(re.sub(r"[^A-Za-z0-9\-]", "", token), 40);
        if cleaned_token {
            words.append(cleaned_token);
        }
    }

    alpha_matches: any = re.findall(r"[A-Za-z]", text_value);
    if len(alpha_matches) < 24 or len(words) < 6 {
        return False;
    }
    if not re.search(r"[.!?]", text_value) and len(words) < 10 {
        return False;
    }
    return True;
}

"""R: Convert lightweight HTML fragments into bounded plain text for search result fields.
M: Removes tags, unescapes entities, and collapses repeated whitespace into one readable line.
E: Empty or malformed fragments normalize to the empty string.
"""
def clean_html_text(raw_html: any, max_len: int = 220) -> str {
    html_text: str = str(raw_html or "");
    if not html_text {
        return "";
    }

    without_comments: str = re.sub("<!--.*?-->", " ", html_text, flags=re.DOTALL);
    without_embeds: str = without_comments;
    for tag_name in ["script", "style", "noscript", "svg", "iframe"] {
        without_embeds = re.sub(
            "<" + tag_name + r"\b[^>]*>.*?</" + tag_name + ">",
            " ",
            without_embeds,
            flags=re.IGNORECASE | re.DOTALL
        );
    }

    with_breaks: str = re.sub(
        r"</?(article|section|main|header|footer|aside|nav|div|p|br|li|ul|ol|h[1-6]|blockquote|tr|td)[^>]*>",
        "\n",
        without_embeds,
        flags=re.IGNORECASE
    );
    without_tags: str = re.sub("<[^>]+>", " ", with_breaks);
    decoded: str = str(unescape(without_tags)).replace("&nbsp;", " ");
    decoded = re.sub(r"\r", "\n", decoded);
    decoded = re.sub(r"\n+", "\n", decoded);

    cleaned_lines: list[str] = [];
    for raw_line in decoded.split("\n") {
        line: str = " ".join(str(raw_line or "").split());
        if not line or line_should_drop_from_content(line) {
            continue;
        }
        add_unique_text(cleaned_lines, line, 280);
    }

    collapsed: str = " ".join(cleaned_lines);
    if not collapsed {
        fallback: str = " ".join(decoded.split());
        if line_should_drop_from_content(fallback) {
            return "";
        }
        collapsed = fallback;
    }

    return safe_text(collapsed, max_len);
}

def decode_search_result_href(raw_href: any) -> str {
    href: str = str(unescape(str(raw_href or ""))).strip();
    if not href {
        return "";
    }

    if href.startswith("//") {
        href = "https:" + href;
    } elif href.startswith("/") {
        href = "https://duckduckgo.com" + href;
    }

    try {
        parsed: any = urlparse(href);
        query_items: dict[str, any] = parse_qs(parsed.query);
        uddg_values: any = query_items.get("uddg", []);
        if isinstance(uddg_values, list) and len(uddg_values) > 0 {
            return safe_text(unquote(str(uddg_values[0])), 500);
        }
    } except ValueError {
        return safe_text(href, 500);
    }

    return safe_text(href, 500);
}

"""R: Parse search result rows from one DuckDuckGo HTML response into structured reusable sources.
M: Finds result anchors, extracts nearby snippets, and normalizes each target URL, title, and domain.
E: Unexpected HTML structures simply yield fewer results rather than raising.
"""
def parse_duckduckgo_search_results(raw_html: str, max_results: int = 8) -> list[any] {
    results: list[any] = [];
    if not raw_html {
        return results;
    }

    anchor_pattern: any = re.compile(
        '<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
        re.IGNORECASE | re.DOTALL
    );
    anchors: any = list(anchor_pattern.finditer(raw_html));
    index: int = 0;
    while index < len(anchors) and len(results) < max_results {
        anchor_match: any = anchors[index];
        href: str = decode_search_result_href(anchor_match.group(1));
        title: str = clean_html_text(anchor_match.group(2), 180);
        if not href or not title {
            index += 1;
            continue;
        }

        next_start: int = int(anchor_match.end());
        next_end: int = len(raw_html);
        if index + 1 < len(anchors) {
            next_end = int(anchors[index + 1].start());
        }

        snippet_window: str = str(raw_html[next_start:next_end]);
        snippet_match: any = re.search(
            'class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</',
            snippet_window,
            re.IGNORECASE | re.DOTALL
        );
        snippet: str = "";
        if snippet_match {
            snippet = clean_html_text(snippet_match.group(1), 240);
        }

        results.append({
            "href": href,
            "text": title,
            "domain": domain_from_url(href),
            "snippet": snippet,
            "rank": len(results) + 1,
            "provider": SEARCH_WEB_PROVIDER
        });
        index += 1;
    }

    return results;
}

"""R: Fetch raw search HTML for the generic `search_web` capability in a testable backend-owned way.
M: Uses a fixture override when present, otherwise performs one stdlib HTTP GET to the configured search provider.
E: Network and HTTP failures return a structured error payload so plan execution can stay truthful.
"""
def fetch_search_html(query: str) -> dict[str, any] {
    fixture_html: str = str(os.environ.get("HELPER_SEARCH_WEB_FIXTURE_HTML", "") or "");
    if fixture_html {
        return {
            "ok": True,
            "provider": SEARCH_WEB_PROVIDER,
            "search_url": "fixture://search_web",
            "raw_html": fixture_html,
            "from_fixture": True
        };
    }

    encoded_query: str = quote_plus(str(query or "").strip());
    if not encoded_query {
        return {"ok": False, "error": "query is required"};
    }

    search_url: str = SEARCH_WEB_ENDPOINT + encoded_query;
    request: any = Request(
        search_url,
        headers={
            "User-Agent": SEARCH_WEB_USER_AGENT,
            "Accept-Language": "en-US,en;q=0.9"
        },
        method="GET"
    );

    try {
        response: any = urlopen(request, timeout=12);
        raw_bytes: any = response.read();
        response.close();
        return {
            "ok": True,
            "provider": SEARCH_WEB_PROVIDER,
            "search_url": search_url,
            "raw_html": str(raw_bytes.decode("utf-8", errors="ignore")),
            "from_fixture": False
        };
    } except HTTPError as err {
        return {"ok": False, "error": "search_http_" + str(err.code), "search_url": search_url};
    } except URLError as err {
        return {"ok": False, "error": "search_network_error", "details": safe_text(err.reason or err, 180), "search_url": search_url};
    } except OSError as err {
        return {"ok": False, "error": "search_os_error", "details": safe_text(err, 180), "search_url": search_url};
    }
}

"""R: Perform the generic `search_web` capability and return structured results for plan consumers.
M: Fetches provider HTML, parses reusable sources, and records whether freshness filtering was actually enforced.
E: Empty queries, network failures, and zero-result responses return explicit status metadata rather than fake sources.
"""
def perform_web_search(query: str, params: dict[str, any] = {}) -> dict[str, any] {
    normalized_query: str = safe_text(query, 320);
    if not normalized_query {
        return {
            "status": "blocked",
            "reason": "missing_query",
            "summary": "The `search_web` step requires a non-empty query.",
            "output": {"query": ""}
        };
    }

    limit: int = normalize_search_limit(params.get("limit", 8), 8);
    freshness_window: str = safe_text(params.get("freshness_window", ""), 32);
    fetch_result: dict[str, any] = fetch_search_html(normalized_query);
    if not bool(fetch_result.get("ok", False)) {
        return {
            "status": "blocked",
            "reason": safe_text(fetch_result.get("error", ""), 80) or "search_request_failed",
            "summary": "Web search could not be completed for this plan step.",
            "output": {
                "query": normalized_query,
                "provider": safe_text(fetch_result.get("provider", SEARCH_WEB_PROVIDER), 40),
                "search_url": safe_text(fetch_result.get("search_url", ""), 400),
                "details": safe_text(fetch_result.get("details", ""), 180),
                "implementation_state": "request_failed"
            }
        };
    }

    sources: list[any] = parse_duckduckgo_search_results(str(fetch_result.get("raw_html", "")), limit);
    if len(sources) == 0 {
        return {
            "status": "partial",
            "reason": "no_search_results",
            "summary": "Web search completed, but no structured search results were parsed.",
            "output": {
                "query": normalized_query,
                "provider": safe_text(fetch_result.get("provider", SEARCH_WEB_PROVIDER), 40),
                "search_url": safe_text(fetch_result.get("search_url", ""), 400),
                "requested_limit": limit,
                "freshness_window_requested": freshness_window,
                "freshness_filter_applied": False,
                "result_count": 0,
                "sources": []
            }
        };
    }

    return {
        "status": "success",
        "reason": "",
        "summary": "Web search succeeded and returned " + str(len(sources)) + " result" + ("s" if len(sources) != 1 else "") + ".",
        "output": {
            "query": normalized_query,
            "provider": safe_text(fetch_result.get("provider", SEARCH_WEB_PROVIDER), 40),
            "search_url": safe_text(fetch_result.get("search_url", ""), 400),
            "requested_limit": limit,
            "freshness_window_requested": freshness_window,
            "freshness_filter_applied": False,
            "result_count": len(sources),
            "sources": sources
        }
    };
}

def opened_pages_from_value(raw_value: any, max_items: int = 8) -> list[any] {
    normalized_pages: list[any] = [];
    if isinstance(raw_value, dict) {
        raw_opened_pages: any = raw_value.get("opened_pages", []);
        if isinstance(raw_opened_pages, list) {
            for raw_page in raw_opened_pages {
                if len(normalized_pages) >= max_items {
                    break;
                }
                normalized_pages.append(sanitize_json_value(raw_page, 4, 14, 240));
            }
            return normalized_pages;
        }
        raw_pages: any = raw_value.get("pages", []);
        if isinstance(raw_pages, list) {
            for raw_page in raw_pages {
                if len(normalized_pages) >= max_items {
                    break;
                }
                normalized_pages.append(sanitize_json_value(raw_page, 4, 14, 240));
            }
            return normalized_pages;
        }
    }
    return [];
}

def extracted_pages_from_value(raw_value: any, max_items: int = 8) -> list[any] {
    normalized_pages: list[any] = [];
    raw_extracted_pages: any = raw_value.get("extracted_pages", []) if isinstance(raw_value, dict) else [];
    if isinstance(raw_extracted_pages, list) {
        for raw_page in raw_extracted_pages {
            if len(normalized_pages) >= max_items {
                break;
            }
            normalized_pages.append(sanitize_json_value(raw_page, 4, 14, 240));
        }
        return normalized_pages;
    }
    return [];
}

"""R: Fetch one page through the generic helper capability in a bounded and testable way.
M: Uses fixture JSON when present, otherwise performs one GET request and records normalized text/title metadata.
E: Network errors, unsupported content types, and decode failures return structured per-page failures instead of raising.
"""
def fetch_open_page(url: str) -> dict[str, any] {
    normalized_url: str = safe_text(url, 500);
    if not normalized_url {
        return {
            "url": "",
            "status": "failed",
            "error": "missing_url",
            "content_type": "",
            "title": "",
            "normalized_content": ""
        };
    }

    fixture_json: str = str(os.environ.get("HELPER_OPEN_PAGE_FIXTURE_JSON", "") or "");
    if fixture_json {
        try {
            parsed_fixture: any = json.loads(fixture_json);
            if isinstance(parsed_fixture, dict) and isinstance(parsed_fixture.get(normalized_url, {}), dict) {
                fixture_entry: dict[str, any] = parsed_fixture.get(normalized_url, {});
                body: str = str(fixture_entry.get("body", "") or "");
                content_type: str = safe_text(fixture_entry.get("content_type", "text/html"), 120);
                title: str = safe_text(fixture_entry.get("title", ""), 180);
                normalized_content: str = clean_html_text(body, 2200);
                if not title {
                    title_match: any = re.search("<title[^>]*>(.*?)</title>", body, re.IGNORECASE | re.DOTALL);
                    if title_match {
                        title = clean_html_text(title_match.group(1), 180);
                    }
                }
                return {
                    "url": normalized_url,
                    "status": safe_text(fixture_entry.get("status", "success"), 24) or "success",
                    "http_status": fixture_entry.get("http_status", 200) if isinstance(fixture_entry.get("http_status", 200), int) else 200,
                    "content_type": content_type,
                    "title": title,
                    "normalized_content": normalized_content,
                    "content_excerpt": safe_text(normalized_content, 900),
                    "error": safe_text(fixture_entry.get("error", ""), 180),
                    "source": "fixture"
                };
            }
        } except json.JSONDecodeError {
            return {
                "url": normalized_url,
                "status": "failed",
                "error": "invalid_open_page_fixture",
                "content_type": "",
                "title": "",
                "normalized_content": "",
                "content_excerpt": "",
                "source": "fixture"
            };
        }
    }

    request: any = Request(
        normalized_url,
        headers={
            "User-Agent": SEARCH_WEB_USER_AGENT,
            "Accept-Language": "en-US,en;q=0.9"
        },
        method="GET"
    );

    try {
        response: any = urlopen(request, timeout=12);
        raw_bytes: any = response.read(OPEN_PAGE_MAX_BYTES);
        headers: any = response.info();
        status_code: int = int(response.getcode()) if response.getcode() else 200;
        response.close();

        content_type: str = safe_text(headers.get("Content-Type", ""), 120);
        decoded_body: str = str(raw_bytes.decode("utf-8", errors="ignore"));
        title: str = "";
        if "html" in content_type or "<html" in decoded_body.lower() {
            title_match: any = re.search("<title[^>]*>(.*?)</title>", decoded_body, re.IGNORECASE | re.DOTALL);
            if title_match {
                title = clean_html_text(title_match.group(1), 180);
            }
        }

        normalized_content: str = clean_html_text(decoded_body, 2200);
        page_status: str = "success";
        fetch_error: str = "";
        if not normalized_content and "text" not in content_type and "html" not in content_type and "json" not in content_type and "xml" not in content_type {
            page_status = "partial";
            fetch_error = "unsupported_content_type";
        }

        return {
            "url": normalized_url,
            "status": page_status,
            "http_status": status_code,
            "content_type": content_type,
            "title": title,
            "normalized_content": normalized_content,
            "content_excerpt": safe_text(normalized_content, 900),
            "error": fetch_error,
            "source": "network"
        };
    } except HTTPError as err {
        return {
            "url": normalized_url,
            "status": "failed",
            "http_status": err.code,
            "content_type": "",
            "title": "",
            "normalized_content": "",
            "content_excerpt": "",
            "error": "http_" + str(err.code),
            "source": "network"
        };
    } except URLError as err {
        return {
            "url": normalized_url,
            "status": "failed",
            "http_status": 0,
            "content_type": "",
            "title": "",
            "normalized_content": "",
            "content_excerpt": "",
            "error": "network_error: " + safe_text(err.reason or err, 180),
            "source": "network"
        };
    } except OSError as err {
        return {
            "url": normalized_url,
            "status": "failed",
            "http_status": 0,
            "content_type": "",
            "title": "",
            "normalized_content": "",
            "content_excerpt": "",
            "error": "os_error: " + safe_text(err, 180),
            "source": "network"
        };
    }
}

"""R: Open a bounded set of ranked source pages for downstream extraction and synthesis steps.
M: Fetches each source URL, preserves source metadata, and returns a partial result when some pages fail.
E: Empty source inputs or complete fetch failure block the step instead of fabricating page content.
"""
def perform_open_page(step_input: any, params: dict[str, any] = {}) -> dict[str, any] {
    requested_sources: list[any] = source_items_from_value(step_input, 8);
    if len(requested_sources) == 0 {
        return {
            "status": "blocked",
            "reason": "missing_sources",
            "summary": "The `open_page` step requires ranked sources from an earlier plan step.",
            "output": {"opened_pages": []}
        };
    }

    max_pages: int = len(requested_sources);
    if isinstance(params.get("limit", len(requested_sources)), int) {
        max_pages = params.get("limit", len(requested_sources));
    }
    max_pages = normalize_search_limit(max_pages, len(requested_sources));

    opened_pages: list[any] = [];
    success_count: int = 0;
    failure_count: int = 0;
    partial_count: int = 0;
    index: int = 0;
    while index < len(requested_sources) and len(opened_pages) < max_pages {
        source: any = requested_sources[index];
        if not isinstance(source, dict) {
            index += 1;
            continue;
        }

        page_result: dict[str, any] = fetch_open_page(safe_text(source.get("href", ""), 500));
        opened_page: dict[str, any] = {
            "url": safe_text(page_result.get("url", ""), 500),
            "title": safe_text(page_result.get("title", ""), 180) or safe_text(source.get("text", ""), 180),
            "status": safe_text(page_result.get("status", ""), 24),
            "http_status": page_result.get("http_status", 0) if isinstance(page_result.get("http_status", 0), int) else 0,
            "content_type": safe_text(page_result.get("content_type", ""), 120),
            "normalized_content": safe_text(page_result.get("normalized_content", ""), 2200),
            "content_excerpt": safe_text(page_result.get("content_excerpt", ""), 900),
            "fetch_error": safe_text(page_result.get("error", ""), 180),
            "domain": safe_text(source.get("domain", ""), 180) or domain_from_url(page_result.get("url", "")),
            "source_rank": source.get("rank", 0) if isinstance(source.get("rank", 0), int) else 0,
            "source_snippet": safe_text(source.get("snippet", ""), 240)
        };
        opened_pages.append(opened_page);

        page_status: str = safe_text(page_result.get("status", ""), 24);
        if page_status == "success" {
            success_count += 1;
        } elif page_status == "partial" {
            partial_count += 1;
        } else {
            failure_count += 1;
        }
        index += 1;
    }

    if success_count == 0 and partial_count == 0 {
        return {
            "status": "blocked",
            "reason": "page_fetch_failed",
            "summary": "The `open_page` step could not fetch any source pages successfully.",
            "output": {
                "opened_pages": opened_pages,
                "requested_pages": max_pages,
                "opened_count": 0,
                "failed_count": failure_count
            }
        };
    }

    step_status: str = "success";
    summary: str = "Opened " + str(success_count) + " source page" + ("s" if success_count != 1 else "") + ".";
    if failure_count > 0 or partial_count > 0 {
        step_status = "partial";
        summary = (
            "Opened " + str(success_count) + " source page" + ("s" if success_count != 1 else "") +
            ", with " + str(failure_count + partial_count) + " page fetch issue" +
            ("s" if (failure_count + partial_count) != 1 else "") + "."
        );
    }

    return {
        "status": step_status,
        "reason": "",
        "summary": summary,
        "output": {
            "opened_pages": opened_pages,
            "requested_pages": max_pages,
            "opened_count": success_count,
            "partial_count": partial_count,
            "failed_count": failure_count
        }
    };
}

"""R: Build the recent navigation chain from raw observation events.
M: Walks the event list in order, keeps navigation-like URLs, and collapses adjacent duplicates.
E: Missing event urls are ignored so noisy traces do not inflate the chain.
"""
def recent_navigation_chain(trace_data: dict[str, any], max_items: int = 6) -> list[str] {
    chain: list[str] = [];
    raw_events: any = trace_data.get("events", []);
    if not isinstance(raw_events, list) {
        return chain;
    }

    for event in raw_events {
        if not isinstance(event, dict) {
            continue;
        }

        event_type: str = safe_text(event.get("type", ""), 40);
        if event_type not in ["navigate", "page_ready", "tab_switched"] {
            continue;
        }

        url_value: str = safe_text(event.get("url", ""), 320);
        if not url_value {
            continue;
        }

        if len(chain) > 0 and chain[len(chain) - 1] == url_value {
            continue;
        }

        chain.append(url_value);
        if len(chain) > max_items {
            chain = chain[len(chain) - max_items:];
        }
    }

    return chain;
}

"""R: Turn the latest telemetry-rich trace record into a helper-friendly normalized browser state snapshot.
M: Reuses stored semantic, DOM, session, and navigation fields instead of exposing raw event logs to helper runtime code.
E: Missing traces still produce a stable empty snapshot that the runtime can block on honestly.
"""
def normalize_browser_state_from_trace(trace_data: dict[str, any], browser_hint: dict[str, any] = {}) -> dict[str, any] {
    semantic: dict[str, any] = {};
    dom_snapshot: dict[str, any] = {};
    session_state: dict[str, any] = {};

    if isinstance(trace_data.get("latest_semantic", {}), dict) {
        semantic = sanitize_json_value(trace_data.get("latest_semantic", {}), 4, 18, 220);
    }
    if isinstance(trace_data.get("latest_dom_snapshot", {}), dict) {
        dom_snapshot = sanitize_json_value(trace_data.get("latest_dom_snapshot", {}), 4, 18, 220);
    }
    if isinstance(trace_data.get("latest_session_state", {}), dict) {
        session_state = sanitize_json_value(trace_data.get("latest_session_state", {}), 4, 18, 220);
    }

    hint_url: str = "";
    hint_title: str = "";
    if isinstance(browser_hint, dict) {
        hint_url = safe_text(browser_hint.get("current_url", ""), 320);
        hint_title = safe_text(browser_hint.get("title", ""), 180);
    }

    current_url: str = safe_text(trace_data.get("source_url", ""), 320) or hint_url;
    navigation_chain: list[str] = recent_navigation_chain(trace_data, 6);
    if len(navigation_chain) > 0 {
        current_url = navigation_chain[len(navigation_chain) - 1];
    }
    if not current_url {
        current_url = hint_url;
    }

    title: str = safe_text(semantic.get("title", ""), 180);
    if not title {
        title = safe_text(dom_snapshot.get("title", ""), 180);
    }
    if not title {
        title = hint_title;
    }

    visible_actions: list[any] = [];
    for label in normalize_text_list(semantic.get("primary_actions", []), 8, 120) {
        visible_actions.append({"label": label, "kind": "primary_action"});
    }

    raw_buttons: any = dom_snapshot.get("buttons", []);
    if isinstance(raw_buttons, list) {
        count: int = 0;
        for button in raw_buttons {
            if count >= 8 {
                break;
            }
            if not isinstance(button, dict) {
                continue;
            }
            action_label: str = safe_text(button.get("label", ""), 120) or safe_text(button.get("text", ""), 120);
            if not action_label {
                continue;
            }
            visible_actions.append({
                "label": action_label,
                "path": safe_text(button.get("path", ""), 220),
                "kind": "button"
            });
            count += 1;
        }
    }

    extracted_text_blocks: list[str] = [];
    add_unique_text(extracted_text_blocks, dom_snapshot.get("body_text_sample", ""), 220);
    for heading in normalize_text_list(dom_snapshot.get("headings", []), 8, 140) {
        add_unique_text(extracted_text_blocks, heading, 140);
    }
    for heading in normalize_text_list(semantic.get("headings", []), 8, 140) {
        add_unique_text(extracted_text_blocks, heading, 140);
    }

    candidate_links: list[any] = [];
    raw_links: any = dom_snapshot.get("links", []);
    if isinstance(raw_links, list) {
        count: int = 0;
        for link in raw_links {
            if count >= 8 {
                break;
            }
            if not isinstance(link, dict) {
                continue;
            }
            href: str = safe_text(link.get("href", ""), 320);
            text: str = safe_text(link.get("text", ""), 140);
            if not href and not text {
                continue;
            }
            candidate_links.append({
                "href": href,
                "text": text,
                "path": safe_text(link.get("path", ""), 220),
                "domain": domain_from_url(href)
            });
            count += 1;
        }
    }

    forms: list[any] = [];
    raw_forms: any = dom_snapshot.get("forms", []);
    if isinstance(raw_forms, list) {
        count: int = 0;
        for form in raw_forms {
            if count >= 6 {
                break;
            }
            if not isinstance(form, dict) {
                continue;
            }
            forms.append({
                "method": safe_text(form.get("method", ""), 12),
                "action": safe_text(form.get("action", ""), 320),
                "field_count": int(form.get("field_count", 0)) if isinstance(form.get("field_count", 0), int) else 0,
                "submit_text": safe_text(form.get("submit_text", ""), 120),
                "labels": normalize_text_list(form.get("labels", []), 8, 120),
                "path": safe_text(form.get("path", ""), 220)
            });
            count += 1;
        }
    }

    detected_entities: list[any] = [];
    current_domain: str = domain_from_url(current_url);
    if current_domain {
        detected_entities.append({"type": "domain", "value": current_domain});
    }

    page_kind: str = safe_text(semantic.get("page_kind", ""), 80);
    if page_kind {
        detected_entities.append({"type": "page_kind", "value": page_kind});
    }

    workflow_stage: str = safe_text(semantic.get("workflow_stage", ""), 80);
    if workflow_stage {
        detected_entities.append({"type": "workflow_stage", "value": workflow_stage});
    }

    for heading in normalize_text_list(semantic.get("headings", []), 4, 120) {
        detected_entities.append({"type": "heading", "value": heading});
    }

    for form in forms {
        labels: list[str] = [];
        if isinstance(form, dict) and isinstance(form.get("labels", []), list) {
            labels = form.get("labels", []);
        }
        for label in labels {
            detected_entities.append({"type": "form_label", "value": safe_text(label, 120)});
        }
    }

    page_summary_parts: list[str] = [];
    if title {
        page_summary_parts.append("Title: " + title);
    }
    if page_kind {
        page_summary_parts.append("Page kind: " + page_kind);
    }
    if workflow_stage {
        page_summary_parts.append("Stage: " + workflow_stage);
    }
    if len(visible_actions) > 0 and isinstance(visible_actions[0], dict) {
        page_summary_parts.append("Primary action: " + safe_text(visible_actions[0].get("label", ""), 120));
    }
    if len(extracted_text_blocks) > 0 {
        page_summary_parts.append("Content: " + safe_text(extracted_text_blocks[0], 160));
    }

    page_summary: str = "No current browser observations yet.";
    if len(page_summary_parts) > 0 {
        page_summary = ". ".join(page_summary_parts);
    }

    observation_timestamp: str = safe_text(trace_data.get("updated_at", ""), 32) or timestamp_now();
    raw_events: any = trace_data.get("events", []);
    if isinstance(raw_events, list) and len(raw_events) > 0 and isinstance(raw_events[len(raw_events) - 1], dict) {
        last_event: dict[str, any] = raw_events[len(raw_events) - 1];
        last_recorded: str = safe_text(last_event.get("recorded_at", ""), 32);
        if last_recorded {
            observation_timestamp = last_recorded;
        }
    }

    return {
        "source_session_id": safe_text(trace_data.get("session_id", ""), 120),
        "current_url": current_url,
        "title": title,
        "recent_navigation_chain": navigation_chain,
        "visible_actions": visible_actions,
        "extracted_text_blocks": extracted_text_blocks,
        "detected_entities": detected_entities,
        "forms": forms,
        "candidate_links": candidate_links,
        "current_domain": current_domain,
        "page_summary": page_summary,
        "page_kind": page_kind,
        "workflow_stage": workflow_stage,
        "observation_timestamp": observation_timestamp,
        "session_state": session_state,
        "telemetry_counts": sanitize_json_value(trace_data.get("telemetry_counts", {}), 3, 16, 120)
    };
}

"""R: Build a minimal browser-state snapshot when trace-backed telemetry is unavailable.
M: Uses renderer-provided url/title hints only as a safe bootstrap fallback for run-time honesty.
E: This path is intentionally thin and should be treated as partial browser context by callers.
"""
def normalize_browser_state_from_hint(browser_hint: dict[str, any]) -> dict[str, any] {
    current_url: str = safe_text(browser_hint.get("current_url", ""), 320);
    title: str = safe_text(browser_hint.get("title", ""), 180);
    current_domain: str = domain_from_url(current_url);

    page_summary: str = "No telemetry snapshot available yet.";
    if current_url or title {
        page_summary = (
            ("Title: " + title + ". " if title else "") +
            ("Current URL: " + current_url if current_url else "")
        ).strip();
    }

    return {
        "source_session_id": "",
        "current_url": current_url,
        "title": title,
        "recent_navigation_chain": [current_url] if current_url else [],
        "visible_actions": [],
        "extracted_text_blocks": [],
        "detected_entities": [{"type": "domain", "value": current_domain}] if current_domain else [],
        "forms": [],
        "candidate_links": [],
        "current_domain": current_domain,
        "page_summary": page_summary,
        "page_kind": "",
        "workflow_stage": "",
        "observation_timestamp": timestamp_now(),
        "session_state": {},
        "telemetry_counts": {}
    };
}

"""R: Bind helper runtime to the current browser world through normalized state rather than raw telemetry.
M: Prefers a live observation trace when a browser session id is provided, then falls back to a thin browser hint snapshot.
E: Returns both the normalized state and logs so runs can explain whether they used trace-backed or partial context.
"""
def derive_browser_state(browser_session_id: str, browser_hint: dict[str, any]) -> dict[str, any] {
    logs: list[str] = [];
    if browser_session_id {
        trace_data: dict[str, any] = read_trace(browser_session_id);
        if trace_data {
            logs.append("Bound browser session " + browser_session_id + " through normalized observation state.");
            return {
                "browser_state": normalize_browser_state_from_trace(trace_data, browser_hint),
                "logs": logs,
                "state_source": "trace"
            };
        }
        logs.append("Browser session " + browser_session_id + " was requested but no trace was found.");
    }

    logs.append("Using minimal browser hint fallback because no observation trace was available.");
    return {
        "browser_state": normalize_browser_state_from_hint(browser_hint),
        "logs": logs,
        "state_source": "hint"
    };
}

"""R: Choose the next safe read-only runtime step from normalized browser state and helper spec.
M: Uses helper kind plus the presence or absence of browser context to select a single explicit runtime action.
E: Missing current url and extracted content produce a blocked decision instead of speculative browsing.
"""
def choose_read_only_step(agent_spec: dict[str, any], browser_state: dict[str, any]) -> dict[str, any] {
    current_url: str = safe_text(browser_state.get("current_url", ""), 320);
    text_blocks: list[str] = [];
    if isinstance(browser_state.get("extracted_text_blocks", []), list) {
        text_blocks = browser_state.get("extracted_text_blocks", []);
    }

    if not current_url and len(text_blocks) == 0 {
        return {
            "action": "await_browser_observation",
            "status": "blocked",
            "reason": "no_normalized_browser_state"
        };
    }

    kind: str = normalize_helper_kind(agent_spec.get("kind", "browser_read"));
    if kind == "monitor" {
        return {
            "action": "inspect_page_signals",
            "status": "ready",
            "focus": "watch_points"
        };
    }

    if kind == "research" {
        return {
            "action": "extract_research_signals",
            "status": "ready",
            "focus": "candidate_links"
        };
    }

    if kind == "briefing" {
        return {
            "action": "summarize_page_state",
            "status": "ready",
            "focus": "briefing"
        };
    }

    return {
        "action": "summarize_page_state",
        "status": "ready",
        "focus": "browser_read"
    };
}

"""R: Convert normalized browser state into structured findings for the first read-only helper runtime.
M: Reuses summary, headings, actions, links, and forms to produce consistent result sections per helper kind.
E: Sparse browser state still returns a structurally valid result with empty lists rather than failing the run.
"""
def execute_read_only_step(
    helper: dict[str, any],
    agent_spec: dict[str, any],
    browser_state: dict[str, any],
    effective_mission: str,
    decision: dict[str, any]
) -> dict[str, any] {
    kind: str = normalize_helper_kind(agent_spec.get("kind", "browser_read"));
    summary: str = safe_text(browser_state.get("page_summary", ""), 320);
    current_domain: str = safe_text(browser_state.get("current_domain", ""), 180);

    highlights: list[str] = [];
    watch_points: list[str] = [];
    findings: list[any] = [];
    notable_signals: list[str] = [];

    add_unique_text(highlights, browser_state.get("title", ""), 140);
    if isinstance(browser_state.get("extracted_text_blocks", []), list) {
        for block in browser_state.get("extracted_text_blocks", []) {
            add_unique_text(highlights, block, 180);
            if len(highlights) >= 4 {
                break;
            }
        }
    }

    if isinstance(browser_state.get("visible_actions", []), list) {
        for action in browser_state.get("visible_actions", []) {
            if not isinstance(action, dict) {
                continue;
            }
            add_unique_text(notable_signals, action.get("label", ""), 120);
            if len(notable_signals) >= 4 {
                break;
            }
        }
    }

    if isinstance(browser_state.get("candidate_links", []), list) {
        for link in browser_state.get("candidate_links", []) {
            if not isinstance(link, dict) {
                continue;
            }
            findings.append({
                "type": "candidate_link",
                "text": safe_text(link.get("text", ""), 140),
                "href": safe_text(link.get("href", ""), 320),
                "domain": safe_text(link.get("domain", ""), 180)
            });
            if len(findings) >= 4 {
                break;
            }
        }
    }

    if isinstance(browser_state.get("forms", []), list) {
        for form in browser_state.get("forms", []) {
            if not isinstance(form, dict) {
                continue;
            }
            method: str = safe_text(form.get("method", ""), 12);
            submit_text: str = safe_text(form.get("submit_text", ""), 120);
            label_summary: str = ", ".join(normalize_text_list(form.get("labels", []), 4, 60));
            watch_points.append(
                "Form " + (submit_text if submit_text else method or "unknown") +
                (" with fields " + label_summary if label_summary else "")
            );
            if len(watch_points) >= 3 {
                break;
            }
        }
    }

    if not summary {
        summary = "Captured a read-only browser snapshot.";
        if current_domain {
            summary = summary + " Domain: " + current_domain + ".";
        }
    }

    if kind == "briefing" {
        summary = "Briefing ready. " + summary;
    } elif kind == "monitor" {
        summary = "Monitor snapshot ready. " + summary;
    } elif kind == "research" {
        summary = "Research snapshot ready. " + summary;
    } else {
        summary = "Browser read snapshot ready. " + summary;
    }

    return {
        "summary": summary,
        "highlights": highlights,
        "watch_points": watch_points,
        "findings": findings,
        "notable_signals": notable_signals,
        "candidate_links": sanitize_json_value(browser_state.get("candidate_links", []), 4, 8, 220),
        "detected_entities": sanitize_json_value(browser_state.get("detected_entities", []), 4, 10, 180),
        "visible_actions": sanitize_json_value(browser_state.get("visible_actions", []), 4, 10, 180),
        "page_summary": safe_text(browser_state.get("page_summary", ""), 320),
        "mission": safe_text(effective_mission, 2000),
        "decision": sanitize_json_value(decision, 3, 8, 120),
        "runtime_mode": safe_text(agent_spec.get("runtime_mode", "browser_read"), 40),
        "read_only": True
    };
}

def agent_spec_has_plan(agent_spec: dict[str, any]) -> bool {
    raw_plan: any = agent_spec.get("plan", []);
    return isinstance(raw_plan, list) and len(raw_plan) > 0;
}

def plan_requires_browser_binding(agent_spec: dict[str, any]) -> bool {
    requirements: any = agent_spec.get("requirements", {});
    if isinstance(requirements, dict) {
        if bool(requirements.get("needs_current_page_context", False)) or bool(requirements.get("needs_monitoring", False)) {
            return True;
        }
    }

    raw_plan: any = agent_spec.get("plan", []);
    if isinstance(raw_plan, list) {
        for raw_step in raw_plan {
            if not isinstance(raw_step, dict) {
                continue;
            }
            step_type: str = safe_text(raw_step.get("type", ""), 60);
            if step_type in ["observe_browser", "extract_links", "extract_actions", "monitor_condition"] {
                return True;
            }
        }
    }

    return False;
}

def browser_state_has_any_signal(browser_state: dict[str, any]) -> bool {
    if safe_text(browser_state.get("current_url", ""), 320) {
        return True;
    }
    if safe_text(browser_state.get("title", ""), 180) {
        return True;
    }
    if len(normalize_text_list(browser_state.get("extracted_text_blocks", []), 8, 220)) > 0 {
        return True;
    }
    if len(normalize_text_list(browser_state.get("visible_actions", []), 8, 220)) > 0 {
        return True;
    }
    raw_links: any = browser_state.get("candidate_links", []);
    return isinstance(raw_links, list) and len(raw_links) > 0;
}

def browser_state_has_rich_observation(browser_state: dict[str, any]) -> bool {
    if len(normalize_text_list(browser_state.get("extracted_text_blocks", []), 8, 220)) > 0 {
        return True;
    }
    raw_actions: any = browser_state.get("visible_actions", []);
    if isinstance(raw_actions, list) and len(raw_actions) > 0 {
        return True;
    }
    raw_links: any = browser_state.get("candidate_links", []);
    if isinstance(raw_links, list) and len(raw_links) > 0 {
        return True;
    }
    if safe_text(browser_state.get("page_kind", ""), 80) or safe_text(browser_state.get("workflow_stage", ""), 80) {
        return True;
    }
    return False;
}

"""R: Normalize source-like items shared across plan execution and final output shaping.
M: Extracts url/text/domain fields and removes duplicates so step outputs can compose cleanly.
E: Unsupported list items are skipped rather than creating misleading synthetic sources.
"""
def unique_source_items(raw_sources: any, max_items: int = 8) -> list[any] {
    sources: list[any] = [];
    seen_keys: list[str] = [];
    if not isinstance(raw_sources, list) {
        return sources;
    }

    for raw_source in raw_sources {
        if len(sources) >= max_items or not isinstance(raw_source, dict) {
            continue;
        }

        href: str = safe_text(raw_source.get("href", ""), 320) or safe_text(raw_source.get("url", ""), 320);
        text: str = safe_text(raw_source.get("text", ""), 140) or safe_text(raw_source.get("title", ""), 140);
        key: str = href or text;
        if not key or key in seen_keys {
            continue;
        }

        seen_keys.append(key);
        normalized_source: dict[str, any] = {
            "href": href,
            "text": text,
            "domain": safe_text(raw_source.get("domain", ""), 180) or domain_from_url(href)
        };
        snippet: str = safe_text(raw_source.get("snippet", ""), 240);
        provider: str = safe_text(raw_source.get("provider", ""), 40);
        if snippet {
            normalized_source["snippet"] = snippet;
        }
        if provider {
            normalized_source["provider"] = provider;
        }
        if isinstance(raw_source.get("rank", 0), int) {
            normalized_source["rank"] = raw_source.get("rank", 0);
        }

        sources.append(normalized_source);
    }

    return sources;
}

def source_items_from_value(raw_value: any, max_items: int = 8) -> list[any] {
    if isinstance(raw_value, dict) {
        if isinstance(raw_value.get("sources", []), list) {
            return unique_source_items(raw_value.get("sources", []), max_items);
        }
        if isinstance(raw_value.get("opened_pages", []), list) {
            opened_sources: list[any] = [];
            raw_opened_pages: any = raw_value.get("opened_pages", []);
            for page in raw_opened_pages {
                if len(opened_sources) >= max_items or not isinstance(page, dict) {
                    continue;
                }
                page_dict: dict[str, any] = page;
                href: str = safe_text(page_dict.get("url", ""), 320);
                text: str = safe_text(page_dict.get("title", ""), 140);
                if not href and not text {
                    continue;
                }
                opened_sources.append({
                    "href": href,
                    "text": text,
                    "domain": safe_text(page_dict.get("domain", ""), 180) or domain_from_url(href),
                    "snippet": safe_text(page_dict.get("content_excerpt", ""), 240) or safe_text(page_dict.get("source_snippet", ""), 240),
                    "rank": page_dict.get("source_rank", 0) if isinstance(page_dict.get("source_rank", 0), int) else 0
                });
            }
            return unique_source_items(opened_sources, max_items);
        }
        if isinstance(raw_value.get("extracted_pages", []), list) {
            extracted_sources: list[any] = [];
            raw_extracted_pages: any = raw_value.get("extracted_pages", []);
            for page in raw_extracted_pages {
                if len(extracted_sources) >= max_items or not isinstance(page, dict) {
                    continue;
                }
                page_dict: dict[str, any] = page;
                href: str = safe_text(page_dict.get("url", ""), 320);
                text: str = safe_text(page_dict.get("title", ""), 140);
                if not href and not text {
                    continue;
                }
                extracted_sources.append({
                    "href": href,
                    "text": text,
                    "domain": safe_text(page_dict.get("domain", ""), 180) or domain_from_url(href),
                    "snippet": safe_text(page_dict.get("content_excerpt", ""), 240),
                    "rank": page_dict.get("source_rank", 0) if isinstance(page_dict.get("source_rank", 0), int) else 0
                });
            }
            return unique_source_items(extracted_sources, max_items);
        }
        if isinstance(raw_value.get("candidate_links", []), list) {
            return unique_source_items(raw_value.get("candidate_links", []), max_items);
        }
    }
    if isinstance(raw_value, list) {
        return unique_source_items(raw_value, max_items);
    }
    return [];
}

def extend_unique_sources(target: list[any], raw_sources: any, max_items: int = 8) {
    for source in source_items_from_value(raw_sources, max_items) {
        if len(target) >= max_items or not isinstance(source, dict) {
            continue;
        }

        href: str = safe_text(source.get("href", ""), 320);
        text: str = safe_text(source.get("text", ""), 140);
        key: str = href or text;
        duplicate: bool = False;
        for existing in target {
            if not isinstance(existing, dict) {
                continue;
            }
            existing_key: str = safe_text(existing.get("href", ""), 320) or safe_text(existing.get("text", ""), 140);
            if existing_key == key and key {
                duplicate = True;
                break;
            }
        }

        if not duplicate {
            target.append(source);
        }
    }
}

"""R: Trim source provenance into a readable bounded shape for final helper outputs.
M: Reuses normalized source extraction, then keeps compact metadata fields needed for provenance and demos.
E: Empty inputs return an empty list so plan runs never invent sources that were not actually used.
"""
def compact_sources_for_output(raw_sources: any, max_items: int = 5) -> list[any] {
    compacted: list[any] = [];
    for source in source_items_from_value(raw_sources, max_items) {
        if not isinstance(source, dict) or len(compacted) >= max_items {
            continue;
        }

        compact_source: dict[str, any] = {
            "href": safe_text(source.get("href", ""), 320),
            "text": safe_text(source.get("text", ""), 140),
            "domain": safe_text(source.get("domain", ""), 120)
        };
        snippet: str = concise_sentence(source.get("snippet", ""), 140);
        provider: str = safe_text(source.get("provider", ""), 40);
        if snippet {
            compact_source["snippet"] = snippet;
        }
        if provider {
            compact_source["provider"] = provider;
        }
        if isinstance(source.get("rank", 0), int) and int(source.get("rank", 0)) > 0 {
            compact_source["rank"] = source.get("rank", 0);
        }
        compacted.append(compact_source);
    }
    return compacted;
}

"""R: Trim opened-page artifacts into a compact readable form without losing fetch provenance.
M: Keeps URL, title, fetch status, content type, and short excerpts while dropping bulky normalized content.
E: Failed pages still retain their error metadata so partial coverage remains explicit.
"""
def compact_opened_pages_for_output(raw_pages: any, max_items: int = 5) -> list[any] {
    compacted: list[any] = [];
    for raw_page in opened_pages_from_value(raw_pages, max_items) {
        if not isinstance(raw_page, dict) or len(compacted) >= max_items {
            continue;
        }

        compact_page: dict[str, any] = {
            "url": safe_text(raw_page.get("url", ""), 320),
            "title": safe_text(raw_page.get("title", ""), 140),
            "status": safe_text(raw_page.get("status", ""), 24),
            "content_type": safe_text(raw_page.get("content_type", ""), 120),
            "domain": safe_text(raw_page.get("domain", ""), 120)
        };
        if isinstance(raw_page.get("http_status", 0), int) and int(raw_page.get("http_status", 0)) > 0 {
            compact_page["http_status"] = raw_page.get("http_status", 0);
        }
        excerpt: str = concise_sentence(raw_page.get("content_excerpt", ""), 180);
        if excerpt {
            compact_page["content_excerpt"] = excerpt;
        }
        fetch_error: str = safe_text(raw_page.get("fetch_error", ""), 160);
        if fetch_error {
            compact_page["fetch_error"] = fetch_error;
        }
        if isinstance(raw_page.get("source_rank", 0), int) and int(raw_page.get("source_rank", 0)) > 0 {
            compact_page["source_rank"] = raw_page.get("source_rank", 0);
        }
        compacted.append(compact_page);
    }
    return compacted;
}

"""R: Trim extracted-page artifacts into concise synthesis inputs suitable for final run output.
M: Keeps page identity plus one short content excerpt so downstream consumers see coverage without large payloads.
E: Partial extracted pages remain visible with their status rather than being dropped.
"""
def compact_extracted_pages_for_output(raw_pages: any, max_items: int = 5) -> list[any] {
    compacted: list[any] = [];
    for raw_page in extracted_pages_from_value(raw_pages, max_items) {
        if not isinstance(raw_page, dict) or len(compacted) >= max_items {
            continue;
        }

        compact_page: dict[str, any] = {
            "url": safe_text(raw_page.get("url", ""), 320),
            "title": safe_text(raw_page.get("title", ""), 140),
            "domain": safe_text(raw_page.get("domain", ""), 120),
            "status": safe_text(raw_page.get("status", ""), 24)
        };
        excerpt: str = concise_sentence(raw_page.get("content_excerpt", ""), 180);
        if excerpt {
            compact_page["content_excerpt"] = excerpt;
        }
        if isinstance(raw_page.get("source_rank", 0), int) and int(raw_page.get("source_rank", 0)) > 0 {
            compact_page["source_rank"] = raw_page.get("source_rank", 0);
        }
        compacted.append(compact_page);
    }
    return compacted;
}

"""R: Assess one extracted page so synthesis can prefer article-like evidence and detect thin hub content.
M: Combines URL shape, title specificity, and excerpt readability into one compact page-quality record.
E: Sparse pages remain classified as limited rather than being dropped silently from downstream decisions.
"""
def assess_extracted_page(page: dict[str, any]) -> dict[str, any] {
    url_value: str = safe_text(page.get("url", ""), 500);
    title_value: str = safe_text(page.get("title", ""), 180);
    excerpt_value: str = safe_text(page.get("content_excerpt", ""), 900);
    combined_text: str = safe_text(title_value + " " + excerpt_value, 1200);
    error_like: bool = text_looks_error_page(combined_text);
    generic_news_landing: bool = text_looks_generic_news_landing(combined_text);
    marketing_landing: bool = text_looks_marketing_landing(combined_text);
    low_signal_page: bool = error_like or generic_news_landing or marketing_landing;
    hub_like: bool = url_looks_hub_like(url_value) or title_looks_hub_like(title_value) or generic_news_landing;
    article_like: bool = not low_signal_page and (url_looks_article_like(url_value) or (text_has_specificity_signals(title_value) and not title_looks_hub_like(title_value) and not generic_news_landing));
    generic_excerpt: bool = False;

    excerpt_lower: str = excerpt_value.lower();
    if (
        "latest news" in excerpt_lower or
        "latest updates" in excerpt_lower or
        "stay updated" in excerpt_lower or
        "artificial intelligence news" in excerpt_lower
    ) {
        generic_excerpt = True;
    }

    substantive_excerpt: bool = text_is_substantive_content(excerpt_value);
    quality: str = "usable";
    if error_like {
        quality = "error";
    } elif marketing_landing {
        quality = "landing";
    } elif not excerpt_value or line_should_drop_from_content(excerpt_value) or generic_excerpt or generic_news_landing {
        quality = "boilerplate";
    } elif not substantive_excerpt {
        quality = "thin";
    } elif hub_like and not article_like {
        quality = "hub";
    }

    usable: bool = substantive_excerpt and not generic_excerpt and not low_signal_page and (article_like or not hub_like);
    if not usable and substantive_excerpt and not hub_like and not low_signal_page {
        usable = True;
    }

    page_kind: str = "article";
    if error_like {
        page_kind = "error";
    } elif marketing_landing {
        page_kind = "landing";
    } elif hub_like and not article_like {
        page_kind = "hub";
    } elif not article_like and not hub_like {
        page_kind = "mixed";
    }

    return {
        "page_kind": page_kind,
        "content_quality": quality,
        "usable": usable,
        "article_like": article_like,
        "hub_like": hub_like,
        "error_like": error_like,
        "marketing_landing": marketing_landing,
        "generic_news_landing": generic_news_landing
    };
}

"""R: Summarize extracted-page quality so the final helper output stays honest about weak fetches.
M: Scores each page with shared heuristics, tracks usable vs hub-heavy coverage, and returns preferred synthesis inputs.
E: When nothing is usable, the result still explains the limitation instead of inventing article-level synthesis.
"""
def assess_extracted_pages_for_summary(extracted_pages: list[any]) -> dict[str, any] {
    preferred_pages: list[any] = [];
    usable_count: int = 0;
    hub_like_count: int = 0;
    low_quality_count: int = 0;
    unusable_count: int = 0;
    total_pages: int = 0;

    for page in extracted_pages {
        if not isinstance(page, dict) {
            continue;
        }

        total_pages += 1;
        assessment: dict[str, any] = assess_extracted_page(page);
        if bool(assessment.get("hub_like", False)) {
            hub_like_count += 1;
        }
        if str(assessment.get("content_quality", "")) != "usable" {
            low_quality_count += 1;
        }
        if not bool(assessment.get("usable", False)) {
            unusable_count += 1;
        }
        if bool(assessment.get("usable", False)) {
            usable_count += 1;
            preferred_pages.append({
                **page,
                "page_kind": safe_text(assessment.get("page_kind", ""), 24),
                "content_quality": safe_text(assessment.get("content_quality", ""), 24)
            });
        }
    }

    coverage_limited: bool = False;
    limitation_text: str = "";
    if total_pages > 0 and usable_count == 0 {
        coverage_limited = True;
        limitation_text = "Available pages were mostly hub, boilerplate, error, or low-signal content, so no reliable summary could be produced.";
    } elif total_pages > 0 and (hub_like_count * 2 >= total_pages or low_quality_count * 2 >= total_pages) and usable_count < total_pages {
        coverage_limited = True;
        limitation_text = "Some fetched pages were hub, boilerplate, error, or low-signal content, so the briefing reflects only clearer article pages.";
    }

    return {
        "preferred_pages": preferred_pages,
        "usable_count": usable_count,
        "hub_like_count": hub_like_count,
        "low_quality_count": low_quality_count,
        "unusable_count": unusable_count,
        "total_pages": total_pages,
        "coverage_limited": coverage_limited,
        "limitation_text": safe_text(limitation_text, 180)
    };
}

"""R: Score candidate sources so synthesis prefers story-like reporting over hub and landing pages.
M: Combines domain, URL-path, title, and snippet heuristics into one bounded integer used by `rank_sources`.
E: Missing fields simply contribute no score so sparse sources still rank deterministically without raising.
"""
def source_quality_score(source: dict[str, any]) -> int {
    href: str = safe_text(source.get("href", ""), 500).lower();
    text: str = safe_text(source.get("text", ""), 240).lower();
    snippet: str = safe_text(source.get("snippet", ""), 320).lower();
    domain: str = safe_text(source.get("domain", ""), 180).lower();
    combined_text: str = text + " " + snippet;
    path_value: str = url_path_from_value(href);
    segments: list[str] = path_segments(path_value);
    article_like: bool = url_looks_article_like(href);
    hub_like: bool = url_looks_hub_like(href);
    score: int = 0;

    if (
        "/y.js" in href or
        "ad_domain=" in href or
        "ad_provider=" in href or
        "doubleclick" in href or
        "googleadservices" in href or
        "bingv7aa" in href
    ) {
        score -= 120;
    }

    if article_like {
        score += 24;
    }
    if path_has_date_signal(path_value) {
        score += 16;
    }
    if len(segments) >= 3 and not hub_like {
        score += 8;
    }
    if len(path_value) >= 36 and not hub_like {
        score += 5;
    }

    if hub_like {
        score -= 30;
    }
    if path_value == "/" {
        score -= 36;
    }

    for hub_path in [
        "/news",
        "/news/",
        "/category",
        "/category/",
        "/categories",
        "/categories/",
        "/tag",
        "/tag/",
        "/tags",
        "/tags/",
        "/topic",
        "/topic/",
        "/topics",
        "/topics/",
        "/archive",
        "/archive/",
        "/latest",
        "/latest/"
    ] {
        if path_value == hub_path {
            score -= 24;
            break;
        }
    }

    for known_domain in [
        "reuters.com",
        "apnews.com",
        "theverge.com",
        "techcrunch.com",
        "engadget.com",
        "pcmag.com",
        "arstechnica.com",
        "wired.com",
        "cnbc.com",
        "nytimes.com",
        "bloomberg.com"
    ] {
        if domain == known_domain or domain == "www." + known_domain {
            if article_like {
                score += 18;
            } else {
                score -= 4;
            }
            break;
        }
    }

    if text_has_specificity_signals(combined_text) {
        score += 12;
    }

    if len(snippet) > 60 and text_is_substantive_content(snippet) {
        score += 8;
    } elif snippet and len(snippet) < 25 {
        score -= 6;
    }

    if title_looks_hub_like(text) {
        score -= 26;
    }
    if text_looks_error_page(combined_text) {
        score -= 80;
    }
    if text_looks_generic_news_landing(combined_text) {
        score -= 28;
    }
    if text_looks_marketing_landing(combined_text) {
        score -= 34;
    }
    if not article_like and len(text.split()) <= 4 and ("ai" in text or "news" in text) {
        score -= 12;
    }

    if (
        "latest news" in combined_text or
        "latest updates" in combined_text or
        "stay updated" in combined_text or
        "ai news" == text or
        "artificial intelligence news" == text
    ) and not text_has_specificity_signals(text) {
        score -= 14;
    }

    if "/topics/" in href or "/topic/" in href {
        score -= 30;
    }
    if "/category/" in href or "/categories/" in href or "/tag/" in href or "/tags/" in href {
        score -= 24;
    }
    if "/archive/" in href or href.endswith("/archive") {
        score -= 24;
    }

    if (
        "google news - artificial intelligence - latest" in text or
        text == "latest" or
        text == "ai news" or
        text == "artificial intelligence - latest" or
        text == "artificial intelligence latest"
    ) {
        score -= 34;
    }

    if "get the latest" in snippet or "stay updated with the latest" in snippet {
        score -= 10;
    }

    if (
        domain == "news.google.com" or
        domain == "news.yahoo.com" or
        domain == "www.msn.com" or
        domain == "news.msn.com"
    ) {
        score -= 40;
    }

    if isinstance(source.get("rank", 0), int) and int(source.get("rank", 0)) > 0 {
        raw_rank: int = int(source.get("rank", 0));
        if raw_rank <= 3 {
            score += 4 - raw_rank;
        }
    }

    return score;
}

"""R: Filter search or ranked sources into snippet-backed synthesis inputs when page fetches are weak.
M: Rejects ads, error pages, and generic landing snippets, then keeps only sources with substantive or concrete reporting text.
E: Sparse source lists return an empty list so fallback synthesis never invents evidence beyond grounded snippets.
"""
def preferred_sources_for_summary(raw_sources: any, max_items: int = 5) -> list[any] {
    preferred: list[any] = [];
    for source in source_items_from_value(raw_sources, max_items * 2) {
        if len(preferred) >= max_items {
            break;
        }
        if not isinstance(source, dict) {
            continue;
        }

        href: str = safe_text(source.get("href", ""), 500);
        title: str = safe_text(source.get("text", ""), 180);
        snippet: str = safe_text(source.get("snippet", ""), 320);
        combined_text: str = safe_text(title + " " + snippet, 520);
        if not combined_text {
            continue;
        }
        if text_looks_error_page(combined_text) or text_looks_marketing_landing(combined_text) or text_looks_generic_news_landing(combined_text) {
            continue;
        }
        if "/y.js" in href or "ad_domain=" in href or "ad_provider=" in href or "doubleclick" in href or "googleadservices" in href {
            continue;
        }

        snippet_usable: bool = text_is_substantive_content(snippet) or text_has_concrete_reporting_signals(combined_text);
        if not snippet_usable {
            continue;
        }

        preferred.append({
            "href": href,
            "text": title,
            "domain": safe_text(source.get("domain", ""), 180) or domain_from_url(href),
            "snippet": snippet,
            "rank": source.get("rank", 0) if isinstance(source.get("rank", 0), int) else 0
        });
    }

    return preferred;
}

"""R: Build compact non-redundant highlights from extracted source pages for final helper presentation.
M: Prefers concise excerpt sentences over page titles, then removes duplicates and lines already covered in the summary.
E: When excerpts are sparse, titles are used as a fallback so successful synthesis still yields readable highlights.
"""
def build_highlights_from_pages(extracted_pages: list[any], summary_text: str, max_items: int = 5) -> list[str] {
    assessment: dict[str, any] = assess_extracted_pages_for_summary(extracted_pages);
    preferred_pages: list[any] = extracted_pages;
    if isinstance(assessment.get("preferred_pages", []), list) and len(assessment.get("preferred_pages", [])) > 0 {
        preferred_pages = assessment.get("preferred_pages", []);
    } elif bool(assessment.get("coverage_limited", False)) {
        return [];
    }

    candidates: list[str] = [];
    for page in preferred_pages {
        if not isinstance(page, dict) {
            continue;
        }
        candidate: str = concise_sentence(page.get("content_excerpt", ""), 140);
        if not candidate {
            candidate = safe_text(page.get("title", ""), 140);
        }
        if text_looks_error_page(candidate) or text_looks_generic_news_landing(candidate) or text_looks_marketing_landing(candidate) {
            continue;
        }
        add_unique_text(candidates, candidate, 140);
        if len(candidates) >= max_items + 1 {
            break;
        }
    }

    summary_lower: str = safe_text(summary_text, 400).lower();
    highlights: list[str] = [];
    for candidate in candidates {
        normalized_candidate: str = safe_text(candidate, 140);
        if not normalized_candidate {
            continue;
        }
        candidate_lower: str = normalized_candidate.lower();
        if candidate_lower and candidate_lower in summary_lower {
            continue;
        }
        add_unique_text(highlights, normalized_candidate, 140);
        if len(highlights) >= max_items {
            break;
        }
    }

    if len(highlights) == 0 {
        return normalize_text_list(candidates, max_items, 140);
    }
    return highlights;
}

"""R: Build a substantive multi-sentence summary preview from extracted pages for the generic summarize capability.
M: Pulls the leading sentence from each of the top preferred article pages (up to 3) and joins them into a synthesized briefing.
E: If inputs are all hubs or low-quality, returns an honest limitation message rather than fabricating article-level content.
"""
def build_summary_preview_from_pages(extracted_pages: list[any], max_chars: int = 220) -> str {
    if len(extracted_pages) == 0 {
        return "";
    }

    assessment: dict[str, any] = assess_extracted_pages_for_summary(extracted_pages);
    preferred_pages: list[any] = assessment.get("preferred_pages", []) if isinstance(assessment.get("preferred_pages", []), list) else [];
    if len(preferred_pages) == 0 {
        return safe_text(assessment.get("limitation_text", ""), max_chars);
    }

    sentences: list[str] = [];
    seen_prefixes: list[str] = [];
    for page in preferred_pages {
        if not isinstance(page, dict) {
            continue;
        }
        sentence: str = concise_sentence(page.get("content_excerpt", ""), 130);
        if not sentence {
            sentence = safe_text(page.get("title", ""), 110);
        }
        if not sentence {
            continue;
        }
        if text_looks_error_page(sentence) or text_looks_generic_news_landing(sentence) or text_looks_marketing_landing(sentence) {
            continue;
        }
        prefix: str = sentence.lower()[:48];
        already_seen: bool = False;
        for seen in seen_prefixes {
            if seen == prefix {
                already_seen = True;
                break;
            }
        }
        if already_seen {
            continue;
        }
        seen_prefixes.append(prefix);
        sentences.append(sentence);
        if len(sentences) >= 3 {
            break;
        }
    }

    if len(sentences) == 0 {
        return safe_text(assessment.get("limitation_text", ""), max_chars);
    }

    combined: str = " ".join(sentences);
    return safe_text(combined, max_chars);
}

"""R: Build a bounded fallback preview from grounded source snippets when fetched pages are missing or too weak.
M: Pulls concise sentences from preferred sources and joins up to three distinct items into a limited but evidence-backed preview.
E: Returns the empty string when only junk or generic snippets remain so callers can keep the honest limitation wording.
"""
def build_summary_preview_from_sources(raw_sources: any, max_chars: int = 220) -> str {
    preferred_sources: list[any] = preferred_sources_for_summary(raw_sources, 3);
    if len(preferred_sources) == 0 {
        return "";
    }

    sentences: list[str] = [];
    seen_prefixes: list[str] = [];
    for source in preferred_sources {
        if not isinstance(source, dict) {
            continue;
        }
        sentence: str = concise_sentence(source.get("snippet", ""), 130);
        if not sentence {
            sentence = safe_text(source.get("text", ""), 110);
        }
        if not sentence {
            continue;
        }

        prefix: str = sentence.lower()[:48];
        duplicate: bool = False;
        for seen in seen_prefixes {
            if seen == prefix {
                duplicate = True;
                break;
            }
        }
        if duplicate {
            continue;
        }

        seen_prefixes.append(prefix);
        sentences.append(sentence);
        if len(sentences) >= 3 {
            break;
        }
    }

    if len(sentences) == 0 {
        return "";
    }
    return safe_text(" ".join(sentences), max_chars);
}

"""R: Build compact highlights from grounded source snippets when extracted pages cannot support them.
M: Reuses preferred source snippets, removes lines already covered by the summary, and caps the result list predictably.
E: Empty or repetitive snippets return an empty list rather than filler text.
"""
def build_highlights_from_sources(raw_sources: any, summary_text: str, max_items: int = 5) -> list[str] {
    preferred_sources: list[any] = preferred_sources_for_summary(raw_sources, max_items + 1);
    if len(preferred_sources) == 0 {
        return [];
    }

    summary_lower: str = safe_text(summary_text, 400).lower();
    highlights: list[str] = [];
    for source in preferred_sources {
        if not isinstance(source, dict) {
            continue;
        }
        candidate: str = concise_sentence(source.get("snippet", ""), 140);
        if not candidate {
            candidate = safe_text(source.get("text", ""), 140);
        }
        if not candidate {
            continue;
        }
        if candidate.lower() and candidate.lower() in summary_lower {
            continue;
        }
        add_unique_text(highlights, candidate, 140);
        if len(highlights) >= max_items {
            break;
        }
    }
    return highlights;
}

"""R: Build compact source-backed findings that complement the summary instead of repeating it verbatim.
M: Prefers source snippets with provenance metadata and filters lines already represented in summary or highlights.
E: If snippets are missing, source titles remain as the fallback so findings still show what evidence was used.
"""
def build_findings_from_sources(
    sources: list[any],
    summary_text: str,
    highlights: list[str],
    max_items: int = 3
) -> list[any] {
    findings: list[any] = [];
    seen_text: list[str] = [];
    blocked_text: str = safe_text(summary_text, 400).lower();
    for highlight in highlights {
        add_unique_text(seen_text, str(highlight).lower(), 180);
    }

    for source in sources {
        if len(findings) >= max_items or not isinstance(source, dict) {
            continue;
        }
        if source_quality_score(source) < 0 {
            continue;
        }

        finding_text: str = concise_sentence(source.get("snippet", ""), 150);
        if not finding_text {
            finding_text = safe_text(source.get("text", ""), 150);
        }
        lowered_text: str = finding_text.lower();
        if not finding_text or lowered_text in seen_text or (lowered_text and lowered_text in blocked_text) {
            continue;
        }

        seen_text.append(lowered_text);
        findings.append({
            "type": "source_page",
            "text": finding_text,
            "href": safe_text(source.get("href", ""), 320),
            "domain": safe_text(source.get("domain", ""), 120)
        });
    }

    return findings;
}

"""R: Build a short honest limitations list for plan-driven outputs without bloating the summary itself.
M: Derives freshness, fetch-coverage, and blocked-step notes from actual step outcomes and saved requirements.
E: Empty notes are skipped so fully successful helpers stay compact.
"""
def build_plan_limitations(
    requirements: dict[str, any],
    search_step: dict[str, any],
    opened_pages: list[any],
    extracted_pages: list[any],
    blocked_step: dict[str, any],
    partial_step: dict[str, any]
) -> list[str] {
    limitations: list[str] = [];
    search_output: dict[str, any] = {};
    if isinstance(search_step.get("output", {}), dict) {
        search_output = search_step.get("output", {});
    }

    if bool(requirements.get("freshness_required", False)) and not bool(search_output.get("freshness_filter_applied", False)) {
        add_unique_text(limitations, "Freshness was requested, but search freshness filtering is not enforced yet.", 180);
    }

    if len(opened_pages) > 0 and len(extracted_pages) < len(opened_pages) {
        add_unique_text(
            limitations,
            "The summary reflects only the pages that were opened and extracted successfully.",
            180
        );
    }

    if blocked_step {
        add_unique_text(
            limitations,
            "Full synthesis stopped at `" + safe_text(blocked_step.get("type", ""), 60) + "`.",
            180
        );
    } elif partial_step {
        add_unique_text(
            limitations,
            "Coverage is partial because `" + safe_text(partial_step.get("type", ""), 60) + "` completed only partially.",
            180
        );
    }

    return normalize_text_list(limitations, 3, 180);
}

def plan_summary_prefix(kind: str, status: str) -> str {
    if status == "partial" {
        if kind == "briefing" {
            return "Partial briefing.";
        }
        if kind == "monitor" {
            return "Partial monitor snapshot.";
        }
        if kind == "research" {
            return "Partial research snapshot.";
        }
        return "Partial briefing.";
    }

    if status == "blocked" {
        if kind == "briefing" {
            return "Briefing blocked.";
        }
        if kind == "monitor" {
            return "Monitor snapshot blocked.";
        }
        if kind == "research" {
            return "Research snapshot blocked.";
        }
        return "Briefing blocked.";
    }

    if kind == "briefing" {
        return "Briefing ready.";
    }
    if kind == "monitor" {
        return "Monitor snapshot ready.";
    }
    if kind == "research" {
        return "Research snapshot ready.";
    }
    return "Briefing ready.";
}

def first_step_result_with_type(step_results: list[any], step_type: str) -> dict[str, any] {
    for step_result in step_results {
        if not isinstance(step_result, dict) {
            continue;
        }
        if safe_text(step_result.get("type", ""), 60) == step_type {
            return step_result;
        }
    }
    return {};
}

def first_blocked_step_result(step_results: list[any]) -> dict[str, any] {
    for step_result in step_results {
        if not isinstance(step_result, dict) {
            continue;
        }
        status: str = safe_text(step_result.get("status", ""), 24);
        if status == "blocked" or status == "failed" {
            return step_result;
        }
    }
    return {};
}

def first_partial_step_result(step_results: list[any]) -> dict[str, any] {
    for step_result in step_results {
        if not isinstance(step_result, dict) {
            continue;
        }
        if safe_text(step_result.get("status", ""), 24) == "partial" {
            return step_result;
        }
    }
    return {};
}

def extracted_pages_from_step_results(step_results: list[any], max_items: int = 8) -> list[any] {
    for step_result in step_results {
        if not isinstance(step_result, dict) {
            continue;
        }
        pages: list[any] = extracted_pages_from_value(step_result.get("output", {}), max_items);
        if len(pages) > 0 {
            return pages;
        }
    }
    return [];
}

def opened_pages_from_step_results(step_results: list[any], max_items: int = 8) -> list[any] {
    for step_result in step_results {
        if not isinstance(step_result, dict) {
            continue;
        }
        pages: list[any] = opened_pages_from_value(step_result.get("output", {}), max_items);
        if len(pages) > 0 {
            return pages;
        }
    }
    return [];
}

"""R: Execute one explicit agent-plan step through currently supported generic capabilities only.
M: Reuses normalized browser state where available and returns structured blocked or partial results for unsupported capabilities.
E: Search and remote-page actions remain honest stubs until real capability wiring exists in this repo.
"""
def execute_plan_step(
    helper: dict[str, any],
    agent_spec: dict[str, any],
    browser_state: dict[str, any],
    effective_mission: str,
    state_source: str,
    plan_step: dict[str, any],
    step_input: any
) -> dict[str, any] {
    step_id: str = safe_text(plan_step.get("step_id", ""), 80) or "step";
    step_type: str = safe_text(plan_step.get("type", ""), 60);
    params: dict[str, any] = {};
    if isinstance(plan_step.get("params", {}), dict) {
        params = plan_step.get("params", {});
    }

    if step_type == "search_web" {
        search_result: dict[str, any] = perform_web_search(
            safe_text(plan_step.get("query", ""), 320),
            params
        );
        return {
            "step_id": step_id,
            "type": step_type,
            "status": safe_text(search_result.get("status", ""), 24) or "blocked",
            "reason": safe_text(search_result.get("reason", ""), 80),
            "summary": safe_text(search_result.get("summary", ""), 240),
            "output": sanitize_json_value(search_result.get("output", {}), 4, 16, 240)
        };
    }

    if step_type == "open_page" {
        open_result: dict[str, any] = perform_open_page(step_input, params);
        return {
            "step_id": step_id,
            "type": step_type,
            "status": safe_text(open_result.get("status", ""), 24) or "blocked",
            "reason": safe_text(open_result.get("reason", ""), 80),
            "summary": safe_text(open_result.get("summary", ""), 240),
            "output": sanitize_json_value(open_result.get("output", {}), 4, 16, 240)
        };
    }

    if step_type == "compare" {
        return {
            "step_id": step_id,
            "type": step_type,
            "status": "blocked",
            "reason": "capability_not_implemented",
            "summary": "Required capability `compare` is not implemented in the Jac helper runtime yet.",
            "output": {"implementation_state": "not_implemented"}
        };
    }

    if step_type == "observe_browser" {
        if not browser_state_has_any_signal(browser_state) {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "blocked",
                "reason": "no_browser_observation",
                "summary": "Current-page observation was required, but no browser observation was available.",
                "output": {}
            };
        }

        status: str = "success";
        summary: str = "Observed the current browser state through normalized telemetry.";
        if state_source == "hint" and not browser_state_has_rich_observation(browser_state) {
            status = "partial";
            summary = "Observed only thin browser hint context because no telemetry-backed browser snapshot was available.";
        }

        return {
            "step_id": step_id,
            "type": step_type,
            "status": status,
            "reason": "",
            "summary": summary,
            "output": {
                "current_url": safe_text(browser_state.get("current_url", ""), 320),
                "title": safe_text(browser_state.get("title", ""), 180),
                "page_summary": safe_text(browser_state.get("page_summary", ""), 320),
                "state_source": state_source
            }
        };
    }

    if step_type == "extract_page_content" {
        opened_pages: list[any] = opened_pages_from_value(step_input, 8);
        if len(opened_pages) > 0 {
            extracted_pages: list[any] = [];
            success_count: int = 0;
            partial_count: int = 0;
            failure_count: int = 0;
            usable_count: int = 0;
            hub_like_count: int = 0;

            for page in opened_pages {
                if not isinstance(page, dict) {
                    continue;
                }
                page_status: str = safe_text(page.get("status", ""), 24);
                content_excerpt: str = safe_text(page.get("content_excerpt", ""), 900);
                normalized_content: str = safe_text(page.get("normalized_content", ""), 2200);
                if page_status == "failed" {
                    failure_count += 1;
                    continue;
                }

                if not content_excerpt and normalized_content {
                    content_excerpt = safe_text(normalized_content, 900);
                }

                extracted_page: dict[str, any] = {
                    "url": safe_text(page.get("url", ""), 500),
                    "title": safe_text(page.get("title", ""), 180),
                    "domain": safe_text(page.get("domain", ""), 180),
                    "status": "success",
                    "content_type": safe_text(page.get("content_type", ""), 120),
                    "content_excerpt": content_excerpt,
                    "source_snippet": safe_text(page.get("source_snippet", ""), 240),
                    "source_rank": page.get("source_rank", 0) if isinstance(page.get("source_rank", 0), int) else 0
                };

                page_assessment: dict[str, any] = assess_extracted_page(extracted_page);
                extracted_page["page_kind"] = safe_text(page_assessment.get("page_kind", ""), 24);
                extracted_page["content_quality"] = safe_text(page_assessment.get("content_quality", ""), 24);
                if bool(page_assessment.get("hub_like", False)) {
                    hub_like_count += 1;
                }
                if bool(page_assessment.get("usable", False)) {
                    usable_count += 1;
                }

                if not content_excerpt {
                    extracted_page["status"] = "partial";
                    partial_count += 1;
                } else {
                    success_count += 1;
                }
                extracted_pages.append(extracted_page);
            }

            if len(extracted_pages) == 0 {
                fallback_sources: list[any] = preferred_sources_for_summary({"opened_pages": opened_pages}, 5);
                if len(fallback_sources) > 0 {
                    return {
                        "step_id": step_id,
                        "type": step_type,
                        "status": "partial",
                        "reason": "snippet_only_extraction",
                        "summary": "Opened pages were available, but only source snippets were usable for synthesis.",
                        "output": {
                            "extracted_pages": [],
                            "page_count": 0,
                            "success_count": 0,
                            "partial_count": partial_count,
                            "failed_count": failure_count,
                            "usable_count": 0,
                            "hub_like_count": hub_like_count,
                            "sources": fallback_sources
                        }
                    };
                }
                return {
                    "step_id": step_id,
                    "type": step_type,
                    "status": "blocked",
                    "reason": "no_opened_pages_with_content",
                    "summary": "Opened pages were available, but none produced extractable page content.",
                    "output": {"extracted_pages": []}
                };
            }

            extract_status: str = "success";
            extract_summary: str = "Extracted bounded content from " + str(success_count) + " opened page" + ("s" if success_count != 1 else "") + ".";
            if partial_count > 0 or failure_count > 0 or success_count == 0 {
                extract_status = "partial";
                extract_summary = (
                    "Extracted content from opened pages with " +
                    str(partial_count + failure_count) + " extraction gap" +
                    ("s" if (partial_count + failure_count) != 1 else "") + "."
                );
            }

            return {
                "step_id": step_id,
                "type": step_type,
                "status": extract_status,
                "reason": "",
                "summary": extract_summary,
                "output": {
                    "extracted_pages": extracted_pages,
                    "page_count": len(extracted_pages),
                    "success_count": success_count,
                    "partial_count": partial_count,
                    "failed_count": failure_count,
                    "usable_count": usable_count,
                    "hub_like_count": hub_like_count,
                    "sources": source_items_from_value({"opened_pages": extracted_pages}, 8)
                }
            };
        }

        if not browser_state_has_any_signal(browser_state) {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "blocked",
                "reason": "no_extractable_content",
                "summary": "No browser-backed content was available to extract for this plan step.",
                "output": {}
            };
        }

        excerpts: list[str] = normalize_text_list(browser_state.get("extracted_text_blocks", []), 6, 220);
        status: str = "success";
        summary: str = "Extracted current-page content from the normalized browser state.";
        if len(excerpts) == 0 and state_source == "hint" {
            status = "partial";
            summary = "Only thin browser hint context was available, so detailed page extraction remained partial.";
        }

        return {
            "step_id": step_id,
            "type": step_type,
            "status": status,
            "reason": "",
            "summary": summary,
            "output": {
                "title": safe_text(browser_state.get("title", ""), 180),
                "current_url": safe_text(browser_state.get("current_url", ""), 320),
                "page_summary": safe_text(browser_state.get("page_summary", ""), 320),
                "extracted_text_blocks": excerpts,
                "state_source": state_source
            }
        };
    }

    if step_type == "extract_links" {
        sources: list[any] = unique_source_items(browser_state.get("candidate_links", []), 8);
        if len(sources) == 0 {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "partial",
                "reason": "no_links_found",
                "summary": "No candidate links were available in the current browser observation.",
                "output": {"sources": []}
            };
        }

        return {
            "step_id": step_id,
            "type": step_type,
            "status": "success",
            "reason": "",
            "summary": "Extracted candidate links from the current browser observation.",
            "output": {"sources": sources}
        };
    }

    if step_type == "extract_actions" {
        actions: any = sanitize_json_value(browser_state.get("visible_actions", []), 4, 8, 180);
        if not isinstance(actions, list) or len(actions) == 0 {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "partial",
                "reason": "no_actions_found",
                "summary": "No visible actions were available in the current browser observation.",
                "output": {"visible_actions": []}
            };
        }

        return {
            "step_id": step_id,
            "type": step_type,
            "status": "success",
            "reason": "",
            "summary": "Extracted visible actions from the current browser observation.",
            "output": {"visible_actions": actions}
        };
    }

    if step_type == "rank_sources" {
        top_k: int = 5;
        if isinstance(params.get("top_k", 5), int) {
            top_k = params.get("top_k", 5);
        }
        candidate_sources: list[any] = source_items_from_value(step_input, 12);
        if len(candidate_sources) == 0 {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "blocked",
                "reason": "missing_sources",
                "summary": "This plan step expected sources to rank, but no source list was available.",
                "output": {"sources": []}
            };
        }

        ranked_sources: list[any] = [];
        used_keys: list[str] = [];
        while len(ranked_sources) < top_k {
            best_source: dict[str, any] = {};
            best_score: int = -100000;
            best_key: str = "";
            found_source: bool = False;

            for source in candidate_sources {
                if not isinstance(source, dict) {
                    continue;
                }

                source_dict: dict[str, any] = source;
                href: str = safe_text(source_dict.get("href", ""), 320);
                text: str = safe_text(source_dict.get("text", ""), 140);
                source_key: str = href or text;
                if source_key and source_key in used_keys {
                    continue;
                }

                score: int = source_quality_score(source_dict);
                if not found_source or score > best_score {
                    best_source = source_dict;
                    best_score = score;
                    best_key = source_key;
                    found_source = True;
                }
            }

            if not found_source {
                break;
            }

            ranked_sources.append(best_source);
            if best_key {
                used_keys.append(best_key);
            }
        }

        if len(ranked_sources) == 0 {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "blocked",
                "reason": "missing_sources",
                "summary": "This plan step expected sources to rank, but no source list was available.",
                "output": {"sources": []}
            };
        }

        return {
            "step_id": step_id,
            "type": step_type,
            "status": "success",
            "reason": "",
            "summary": "Ranked the available sources using source-quality heuristics.",
            "output": {"sources": ranked_sources}
        };
    }

    if step_type == "dedupe" {
        extracted_pages: list[any] = extracted_pages_from_value(step_input, 8);
        if len(extracted_pages) > 0 {
            deduped_pages: list[any] = [];
            seen_urls: list[str] = [];
            for page in extracted_pages {
                if not isinstance(page, dict) {
                    continue;
                }
                page_url: str = safe_text(page.get("url", ""), 500);
                page_key: str = page_url or safe_text(page.get("title", ""), 180);
                if not page_key or page_key in seen_urls {
                    continue;
                }
                seen_urls.append(page_key);
                deduped_pages.append(page);
            }

            return {
                "step_id": step_id,
                "type": step_type,
                "status": "success",
                "reason": "",
                "summary": "Deduped extracted page content.",
                "output": {
                    "extracted_pages": deduped_pages,
                    "sources": source_items_from_value({"extracted_pages": deduped_pages}, 8)
                }
            };
        }

        deduped_sources: list[any] = source_items_from_value(step_input, 8);
        return {
            "step_id": step_id,
            "type": step_type,
            "status": "success",
            "reason": "",
            "summary": "Deduped the available source list.",
            "output": {"sources": deduped_sources}
        };
    }

    if step_type == "monitor_condition" {
        if not browser_state_has_any_signal(browser_state) {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "blocked",
                "reason": "no_browser_observation",
                "summary": "Monitoring requires current browser observations, but none were available.",
                "output": {}
            };
        }

        watch_points: list[str] = [];
        for action in sanitize_json_value(browser_state.get("visible_actions", []), 4, 6, 160) {
            if isinstance(action, dict) {
                add_unique_text(watch_points, action.get("label", ""), 140);
            }
        }
        for form in sanitize_json_value(browser_state.get("forms", []), 4, 4, 160) {
            if isinstance(form, dict) {
                add_unique_text(watch_points, form.get("submit_text", ""), 140);
            }
        }

        return {
            "step_id": step_id,
            "type": step_type,
            "status": "partial",
            "reason": "monitoring_baseline_not_implemented",
            "summary": "Captured current monitor signals, but baseline-aware change detection is not implemented yet.",
            "output": {
                "watch_points": watch_points,
                "implementation_state": "baseline_not_implemented"
            }
        };
    }

    if step_type == "summarize" {
        max_items: int = clamp_int_limit(params.get("max_items", 5), 5, 1, 8);
        max_chars: int = clamp_int_limit(params.get("max_chars", 1200), 1200, 160, 1600);
        preview_chars: int = 220;
        if max_chars < preview_chars {
            preview_chars = max_chars;
        }
        extracted_pages: list[any] = extracted_pages_from_value(step_input, max_items);
        fallback_sources: list[any] = preferred_sources_for_summary(step_input, max_items);
        if len(extracted_pages) > 0 {
            page_assessment: dict[str, any] = assess_extracted_pages_for_summary(extracted_pages);
            preview: str = build_summary_preview_from_pages(extracted_pages, preview_chars);
            highlights: list[str] = build_highlights_from_pages(extracted_pages, preview, max_items);
            summarize_status: str = "success";
            summarize_reason: str = "";
            summarize_summary: str = "Prepared the final result from extracted source pages.";
            used_source_fallback: bool = False;
            if not preview or bool(page_assessment.get("coverage_limited", False)) {
                source_preview: str = build_summary_preview_from_sources(step_input, preview_chars);
                if source_preview {
                    preview = source_preview;
                    used_source_fallback = True;
                }
                if len(highlights) == 0 {
                    highlights = build_highlights_from_sources(step_input, preview, max_items);
                }
            }
            if bool(page_assessment.get("coverage_limited", False)) {
                summarize_status = "partial";
                summarize_reason = "limited_article_coverage";
                summarize_summary = "Prepared a limited result because fetched pages were mostly hub or boilerplate content.";
                if used_source_fallback {
                    summarize_summary = "Prepared a limited result from grounded source snippets because fetched page content was weak or noisy.";
                }
            }

            return {
                "step_id": step_id,
                "type": step_type,
                "status": summarize_status,
                "reason": summarize_reason,
                "summary": summarize_summary,
                "output": {
                    "summary_preview": preview,
                    "highlights": highlights,
                    "source_count": len(extracted_pages),
                    "usable_source_count": page_assessment.get("usable_count", 0) if isinstance(page_assessment.get("usable_count", 0), int) else 0,
                    "coverage_limited": bool(page_assessment.get("coverage_limited", False)),
                    "used_source_snippets_fallback": used_source_fallback,
                    "mission": safe_text(effective_mission, 2200)
                }
            };
        }

        if len(fallback_sources) > 0 {
            fallback_preview: str = build_summary_preview_from_sources(fallback_sources, preview_chars);
            fallback_highlights: list[str] = build_highlights_from_sources(fallback_sources, fallback_preview, max_items);
            if fallback_preview {
                return {
                    "step_id": step_id,
                    "type": step_type,
                    "status": "partial",
                    "reason": "snippet_only_coverage",
                    "summary": "Prepared a limited result from grounded source snippets because fetched page content was unavailable.",
                    "output": {
                        "summary_preview": fallback_preview,
                        "highlights": fallback_highlights,
                        "source_count": len(fallback_sources),
                        "usable_source_count": len(fallback_sources),
                        "coverage_limited": True,
                        "used_source_snippets_fallback": True,
                        "mission": safe_text(effective_mission, 2200)
                    }
                };
            }
        }

        if not browser_state_has_any_signal(browser_state) and len(source_items_from_value(step_input, 8)) == 0 {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "blocked",
                "reason": "nothing_to_summarize",
                "summary": "The plan reached summarization without any extracted browser content or source material.",
                "output": {}
            };
        }

        preview: str = safe_text(browser_state.get("page_summary", ""), preview_chars);
        if not preview {
            preview = safe_text(agent_spec.get("objective", {}).get("primary_goal", ""), preview_chars);
        }

        return {
            "step_id": step_id,
            "type": step_type,
            "status": "success",
            "reason": "",
            "summary": "Prepared the final result from the plan inputs.",
            "output": {
                "summary_preview": preview,
                "mission": safe_text(effective_mission, 2200)
            }
        };
    }

    return {
        "step_id": step_id,
        "type": step_type,
        "status": "blocked",
        "reason": "unknown_step_type",
        "summary": "Encountered an unknown plan step type `" + step_type + "`.",
        "output": {}
    };
}

"""R: Execute the saved agent plan and shape a truthful helper result from explicit step outcomes.
M: Runs each step in order, records blocked or partial capability gaps, and only falls back when the spec has no plan.
E: Unsupported capabilities stay blocked or partial instead of silently degrading into a misleading browser-title summary.
"""
def execute_agent_plan(
    helper: dict[str, any],
    agent_spec: dict[str, any],
    browser_state: dict[str, any],
    effective_mission: str,
    state_source: str
) -> dict[str, any] {
    plan: list[any] = normalize_agent_plan(agent_spec.get("plan", []));
    constraints: dict[str, any] = {};
    if isinstance(agent_spec.get("constraints", {}), dict) {
        constraints = agent_spec.get("constraints", {});
    }
    output_contract: dict[str, any] = {};
    if isinstance(agent_spec.get("output_contract", {}), dict) {
        output_contract = agent_spec.get("output_contract", {});
    }

    max_sources: int = clamp_int_limit(constraints.get("max_sources", 5), 5, 0, 8);
    max_output_items: int = clamp_int_limit(constraints.get("max_output_items", 5), 5, 1, 8);
    max_output_chars: int = clamp_int_limit(constraints.get("max_output_chars", 1200), 1200, 160, 1600);
    summary_char_limit: int = 240;
    if max_output_chars < summary_char_limit {
        summary_char_limit = max_output_chars;
    }
    page_summary_char_limit: int = 320;
    if max_output_chars < page_summary_char_limit {
        page_summary_char_limit = max_output_chars;
    }
    source_output_limit: int = max_output_items;
    if max_sources > 0 and max_sources < source_output_limit {
        source_output_limit = max_sources;
    }
    if source_output_limit < 1 {
        source_output_limit = 1;
    }

    step_results: list[any] = [];
    artifacts: dict[str, any] = {};
    logs: list[str] = ["Executing saved agent plan."];
    errors: list[str] = [];
    final_status: str = "success";
    blocked_reason: str = "";

    if isinstance(browser_state, dict) and len(browser_state) > 0 {
        artifacts["browser_state"] = browser_state;
    }

    for raw_step in plan {
        if not isinstance(raw_step, dict) {
            continue;
        }

        step_id: str = safe_text(raw_step.get("step_id", ""), 80) or "step";
        input_from: str = safe_text(raw_step.get("input_from", ""), 80);
        step_input: any = {};
        if input_from and input_from in artifacts {
            step_input = artifacts[input_from];
        }

        step_result: dict[str, any] = execute_plan_step(
            helper,
            agent_spec,
            browser_state,
            effective_mission,
            state_source,
            raw_step,
            step_input
        );
        step_results.append({
            "step_id": step_id,
            "type": safe_text(step_result.get("type", ""), 60),
            "status": safe_text(step_result.get("status", ""), 24),
            "reason": safe_text(step_result.get("reason", ""), 80),
            "summary": safe_text(step_result.get("summary", ""), 260),
            "output": sanitize_json_value(step_result.get("output", {}), 4, 12, 220)
        });

        if "output" in step_result {
            artifacts[step_id] = step_result.get("output", {});
        }

        step_status: str = safe_text(step_result.get("status", ""), 24);
        logs.append("Plan step " + step_id + " (" + safe_text(step_result.get("type", ""), 60) + ") -> " + step_status + ".");
        if step_status == "partial" and final_status == "success" {
            final_status = "partial";
        }
        if step_status == "blocked" or step_status == "failed" {
            prior_progress: bool = len(step_results) > 1;
            if prior_progress {
                final_status = "partial";
            } else {
                final_status = step_status;
            }
            blocked_reason = safe_text(step_result.get("reason", ""), 80);
            errors.append(safe_text(step_result.get("summary", ""), 240));
            break;
        }
    }

    sources: list[any] = [];
    for preferred_type in ["rank_sources", "extract_page_content", "open_page", "search_web"] {
        for step_result in step_results {
            if not isinstance(step_result, dict) {
                continue;
            }
            if safe_text(step_result.get("type", ""), 60) != preferred_type {
                continue;
            }
            extend_unique_sources(sources, step_result.get("output", {}), max_sources);
        }
    }
    if len(sources) == 0 {
        extend_unique_sources(sources, browser_state.get("candidate_links", []), max_sources);
    }

    kind: str = normalize_helper_kind(agent_spec.get("kind", "browser_read"));
    search_step: dict[str, any] = first_step_result_with_type(step_results, "search_web");
    blocked_step: dict[str, any] = first_blocked_step_result(step_results);
    partial_step: dict[str, any] = first_partial_step_result(step_results);
    first_blocked_step: dict[str, any] = {};
    if blocked_step {
        first_blocked_step = {
            "step_id": safe_text(blocked_step.get("step_id", ""), 80),
            "type": safe_text(blocked_step.get("type", ""), 60),
            "status": safe_text(blocked_step.get("status", ""), 24),
            "reason": safe_text(blocked_step.get("reason", ""), 80)
        };
    }
    search_sources: list[any] = [];
    if isinstance(search_step.get("output", {}), dict) {
        search_sources = source_items_from_value(search_step.get("output", {}), source_output_limit);
    }
    opened_pages: list[any] = opened_pages_from_step_results(step_results, source_output_limit);
    extracted_pages: list[any] = extracted_pages_from_step_results(step_results, source_output_limit);
    summarize_step: dict[str, any] = first_step_result_with_type(step_results, "summarize");
    summarize_output: dict[str, any] = {};
    if isinstance(summarize_step.get("output", {}), dict) {
        summarize_output = summarize_step.get("output", {});
    }
    compact_sources: list[any] = compact_sources_for_output(sources, source_output_limit);
    compact_search_sources: list[any] = compact_sources_for_output(search_sources, source_output_limit);
    compact_opened_pages: list[any] = compact_opened_pages_for_output({"opened_pages": opened_pages}, source_output_limit);
    compact_extracted_pages: list[any] = compact_extracted_pages_for_output({"extracted_pages": extracted_pages}, source_output_limit);
    plan_limitations: list[str] = build_plan_limitations(
        sanitize_json_value(agent_spec.get("requirements", {}), 3, 10, 180),
        search_step,
        compact_opened_pages,
        compact_extracted_pages,
        blocked_step,
        partial_step
    );
    summary: str = "";
    structured_output: dict[str, any] = {};
    if final_status == "success" or final_status == "partial" {
        base_result: dict[str, any] = {};
        if len(compact_extracted_pages) > 0 or len(compact_opened_pages) > 0 {
            preview: str = safe_text(summarize_output.get("summary_preview", ""), summary_char_limit);
            if not preview and len(compact_extracted_pages) > 0 {
                preview = build_summary_preview_from_pages(compact_extracted_pages, summary_char_limit);
            }
            if not preview and len(compact_opened_pages) > 0 {
                preview = "Opened " + str(len(compact_opened_pages)) + " fetched source page" + ("s" if len(compact_opened_pages) != 1 else "") + ".";
            }

            summary = plan_summary_prefix(kind, "success");
            if preview {
                summary = safe_text(summary + " " + preview, summary_char_limit);
            } else {
                summary = safe_text(summary, summary_char_limit);
            }

            synthesized_highlights: list[str] = normalize_text_list(summarize_output.get("highlights", []), max_output_items, 140);
            if len(synthesized_highlights) == 0 {
                synthesized_highlights = build_highlights_from_pages(compact_extracted_pages, summary, max_output_items);
            } else {
                highlight_pages: list[any] = [];
                for item in synthesized_highlights {
                    highlight_pages.append({
                        "content_excerpt": item,
                        "title": item
                    });
                }
                synthesized_highlights = normalize_text_list(
                    build_highlights_from_pages(
                        highlight_pages,
                        summary,
                        max_output_items
                    ),
                    max_output_items,
                    140
                );
            }

            findings: list[any] = build_findings_from_sources(
                compact_sources,
                summary,
                synthesized_highlights,
                3 if max_output_items > 3 else max_output_items
            );

            base_result = {
                "summary": summary,
                "highlights": synthesized_highlights,
                "watch_points": [],
                "findings": findings,
                "notable_signals": [],
                "candidate_links": [],
                "detected_entities": [],
                "visible_actions": [],
                "page_summary": safe_text(preview or summary, page_summary_char_limit),
                "mission": safe_text(effective_mission, 2000),
                "decision": {"action": "execute_agent_plan", "status": final_status, "focus": "agent_plan"},
                "runtime_mode": safe_text(agent_spec.get("runtime_mode", "browser_read"), 40),
                "read_only": True
            };
        } else {
            base_result = execute_read_only_step(
                helper,
                agent_spec,
                browser_state,
                effective_mission,
                {"action": "execute_agent_plan", "status": final_status, "focus": "agent_plan"}
            );
            summary = safe_text(base_result.get("summary", ""), 320);
        }
        if final_status == "partial" {
            detail: str = safe_text(base_result.get("page_summary", ""), summary_char_limit);
            summarize_limited: bool = bool(summarize_output.get("coverage_limited", False));
            limited_preview: str = safe_text(summarize_output.get("summary_preview", ""), summary_char_limit);
            if summarize_limited and limited_preview {
                detail = limited_preview;
            } elif blocked_step {
                if detail {
                    detail = safe_text(
                        detail + " `" + safe_text(blocked_step.get("type", ""), 60) + "` blocked full synthesis.",
                        summary_char_limit
                    );
                } else {
                    detail = safe_text(
                        "`" + safe_text(blocked_step.get("type", ""), 60) + "` blocked full synthesis.",
                        summary_char_limit
                    );
                }
            } elif partial_step {
                if detail {
                    detail = safe_text(
                        detail + " Coverage is partial because `" + safe_text(partial_step.get("type", ""), 60) + "` was incomplete.",
                        summary_char_limit
                    );
                } else {
                    detail = safe_text(
                        "Coverage is partial because `" + safe_text(partial_step.get("type", ""), 60) + "` was incomplete.",
                        summary_char_limit
                    );
                }
            }
            if not detail and len(step_results) > 0 and isinstance(step_results[len(step_results) - 1], dict) {
                detail = safe_text(step_results[len(step_results) - 1].get("summary", ""), summary_char_limit);
            }
            summary = safe_text(plan_summary_prefix(kind, "partial") + " " + detail, summary_char_limit);
            base_result["summary"] = summary;
            if str(base_result.get("page_summary", "")) == "" or summarize_limited {
                base_result["page_summary"] = detail;
            }
        }

        structured_output = {
            **base_result,
            "summary": summary,
            "sources": compact_sources,
            "search_results": compact_search_sources,
            "opened_pages": compact_opened_pages,
            "extracted_pages": compact_extracted_pages,
            "limitations": plan_limitations
        };
    } else {
        detail: str = "A required planned capability could not be completed.";
        if blocked_step {
            detail = safe_text(blocked_step.get("summary", ""), 240) or detail;
        }

        summary = plan_summary_prefix(kind, "blocked") + " " + detail;
        structured_output = {
            "summary": summary,
            "highlights": [],
            "watch_points": [],
            "findings": [],
            "notable_signals": [],
            "candidate_links": [],
            "sources": compact_sources,
            "search_results": compact_search_sources,
            "opened_pages": compact_opened_pages,
            "extracted_pages": compact_extracted_pages,
            "limitations": plan_limitations,
            "detected_entities": sanitize_json_value(browser_state.get("detected_entities", []), 4, 10, 180),
            "visible_actions": sanitize_json_value(browser_state.get("visible_actions", []), 4, 10, 180),
            "page_summary": safe_text(browser_state.get("page_summary", ""), 320),
            "mission": safe_text(effective_mission, 2200),
            "decision": {
                "action": "execute_agent_plan",
                "status": final_status,
                "reason": blocked_reason or "plan_blocked"
            },
            "runtime_mode": safe_text(agent_spec.get("runtime_mode", "browser_read"), 40),
            "read_only": True
        };
    }

    structured_output["execution_status"] = final_status;
    structured_output["objective"] = sanitize_json_value(agent_spec.get("objective", {}), 4, 10, 220);
    structured_output["requirements"] = sanitize_json_value(agent_spec.get("requirements", {}), 4, 10, 180);
    structured_output["constraints"] = sanitize_json_value(agent_spec.get("constraints", {}), 4, 10, 180);
    structured_output["capabilities"] = sanitize_json_value(agent_spec.get("capabilities", []), 2, 20, 80);
    structured_output["plan"] = sanitize_json_value(plan, 4, 16, 180);
    structured_output["output_contract"] = sanitize_json_value(output_contract, 4, 12, 180);
    structured_output["plan_execution"] = {
        "strategy": "agent_plan",
        "status": final_status,
        "planned_steps": len(plan),
        "completed_steps": len(step_results),
        "blocked_reason": blocked_reason,
        "first_blocked_step": first_blocked_step,
        "step_results": step_results
    };

    return {
        "status": final_status,
        "summary": summary,
        "structured_output": structured_output,
        "logs": logs,
        "errors": errors
    };
}

"""R: Run one helper once through the first read-only browser-backed runtime loop.
M: Loads helper/spec, binds browser state from telemetry, decides one safe read step, persists a run record, and returns the result.
E: Missing browser observations produce a blocked run instead of fabricated action execution, and run-only overrides never mutate the saved helper.
"""
def run_helper_once_v1(payload: dict[str, any]) -> dict[str, any] {
    helper_id: str = safe_text(payload.get("helper_id", ""), 80);
    if not helper_id {
        return {"ok": False, "error": "helper_id is required"};
    }

    helper: dict[str, any] = load_helper_definition(helper_id);
    if not helper {
        return {"ok": False, "error": "helper not found", "helper_id": helper_id};
    }

    agent_spec: dict[str, any] = load_agent_spec(str(helper.get("agent_spec_id", "")));
    if not agent_spec {
        return {"ok": False, "error": "agent spec not found", "helper_id": helper_id};
    }

    started_at: str = timestamp_now();
    trigger_type: str = safe_text(payload.get("trigger_type", ""), 40) or "manual";
    browser_session_id: str = safe_text(payload.get("browser_session_id", ""), 120);

    browser_hint: dict[str, any] = {};
    raw_browser_hint: any = payload.get("browser_state_hint", {});
    if isinstance(raw_browser_hint, dict) {
        browser_hint = sanitize_json_value(raw_browser_hint, 4, 12, 220);
    }

    logs: list[str] = [
        "Loaded helper " + safe_text(helper.get("name", ""), 120) + ".",
        "Runtime mode: " + safe_text(agent_spec.get("runtime_mode", "browser_read"), 40) + "."
    ];
    errors: list[str] = [];

    mission_override: str = safe_text(payload.get("run_goal_override", ""), 800);
    effective_mission: str = safe_text(agent_spec.get("mission", ""), 2200);
    if mission_override {
        effective_mission = effective_mission + " Temporary run guidance: " + mission_override;
        logs.append("Applied temporary run-only guidance.");
    }

    use_agent_plan: bool = agent_spec_has_plan(agent_spec);
    if use_agent_plan {
        logs.append("Execution strategy: agent_plan.");
    } else {
        logs.append("Execution strategy: legacy_read_only_fallback.");
    }

    browser_state: dict[str, any] = {};
    binding: dict[str, any] = {};
    if use_agent_plan and not plan_requires_browser_binding(agent_spec) {
        logs.append("Saved plan does not require current-page browser binding for its first step.");
    } else {
        binding = derive_browser_state(browser_session_id, browser_hint);
        if isinstance(binding.get("browser_state", {}), dict) {
            browser_state = binding.get("browser_state", {});
        }
        for log_line in normalize_text_list(binding.get("logs", []), 8, 220) {
            logs.append(log_line);
        }
    }

    run_status: str = "success";
    summary: str = "";
    structured_output: dict[str, any] = {};
    decision: dict[str, any] = {};

    if use_agent_plan {
        plan_result: dict[str, any] = execute_agent_plan(
            helper,
            agent_spec,
            browser_state,
            effective_mission,
            safe_text(binding.get("state_source", ""), 24)
        );
        run_status = safe_text(plan_result.get("status", ""), 24) or "failed";
        summary = safe_text(plan_result.get("summary", ""), 320);
        if isinstance(plan_result.get("structured_output", {}), dict) {
            structured_output = {
                **plan_result.get("structured_output", {}),
                "browser_state": sanitize_json_value(browser_state, 5, 24, 220),
                "helper_kind": safe_text(agent_spec.get("kind", "browser_read"), 32),
                "state_source": safe_text(binding.get("state_source", ""), 24)
            };
        }
        decision = {
            "action": "execute_agent_plan",
            "status": run_status,
            "focus": "agent_plan"
        };
        for log_line in normalize_text_list(plan_result.get("logs", []), 16, 220) {
            logs.append(log_line);
        }
        for error_line in normalize_text_list(plan_result.get("errors", []), 12, 240) {
            errors.append(error_line);
        }
    } else {
        decision = choose_read_only_step(agent_spec, browser_state);
        logs.append("Decision: " + safe_text(decision.get("action", ""), 120) + ".");

        if safe_text(decision.get("status", ""), 24) == "blocked" {
            run_status = "blocked";
            summary = (
                "Helper is waiting for browser observations. " +
                "A normalized browser snapshot was not available yet."
            );
            structured_output = {
                "summary": summary,
                "decision": sanitize_json_value(decision, 3, 8, 140),
                "browser_state": sanitize_json_value(browser_state, 5, 24, 220),
                "mission": safe_text(effective_mission, 2200),
                "read_only": True
            };
            logs.append("Run blocked because no normalized browser state was available.");
        } else {
            execution_result: dict[str, any] = execute_read_only_step(helper, agent_spec, browser_state, effective_mission, decision);
            structured_output = {
                **execution_result,
                "browser_state": sanitize_json_value(browser_state, 5, 24, 220),
                "helper_kind": safe_text(agent_spec.get("kind", "browser_read"), 32),
                "output_contract": sanitize_json_value(agent_spec.get("output_contract", {}), 4, 12, 180),
                "state_source": safe_text(binding.get("state_source", ""), 24)
            };
            summary = safe_text(execution_result.get("summary", ""), 320);
            logs.append("Run completed with a read-only browser snapshot.");
        }
    }

    finished_at: str = timestamp_now();
    run_record: dict[str, any] = normalize_helper_run({
        "run_id": new_run_id(),
        "helper_id": helper_id,
        "agent_spec_id": safe_text(agent_spec.get("agent_spec_id", ""), 80),
        "started_at": started_at,
        "finished_at": finished_at,
        "status": run_status,
        "trigger_type": trigger_type,
        "browser_session_id": browser_session_id,
        "summary": summary,
        "structured_output": structured_output,
        "runtime_state": {
            "mission": safe_text(effective_mission, 2200),
            "decision": sanitize_json_value(decision, 3, 8, 140),
            "browser_state": sanitize_json_value(browser_state, 5, 24, 220),
            "state_source": safe_text(binding.get("state_source", ""), 24),
            "execution_strategy": "agent_plan" if use_agent_plan else "legacy_read_only_fallback",
            "plan_execution": sanitize_json_value(structured_output.get("plan_execution", {}), 4, 16, 220)
        },
        "logs": logs,
        "errors": errors
    });

    if not run_record {
        return {"ok": False, "error": "run normalization failed"};
    }

    write_json_file(helper_run_file(str(run_record.get("run_id", ""))), run_record);

    return {
        "ok": True,
        "run": run_record,
        "helper_bundle": helper_bundle(helper, agent_spec, run_record)
    };
}

"""R: Execute one helper through the bounded v2 runtime while preserving the existing helper run record contract.
M: Translates helper/spec/payload inputs into the v2 objective-first adapter, then reshapes the result back into persisted helper-run fields.
E: The adapter is used only after explicit version dispatch, so unsupported helper slices should never arrive here.
"""
def run_helper_once_v2(payload: dict[str, any], helper: dict[str, any], agent_spec: dict[str, any]) -> dict[str, any] {
    started_at: str = timestamp_now();
    trigger_type: str = safe_text(payload.get("trigger_type", ""), 40) or "manual";
    browser_session_id: str = safe_text(payload.get("browser_session_id", ""), 120);
    mission_override: str = safe_text(payload.get("run_goal_override", ""), 800);
    objective: str = safe_text(agent_spec.get("goal_text", ""), 1600) or safe_text(helper.get("goal", ""), 1600) or safe_text(agent_spec.get("mission", ""), 1600);
    if mission_override {
        objective = safe_text(objective + " Temporary run guidance: " + mission_override, 1600);
    }

    browser_hint: dict[str, any] = {};
    raw_browser_hint: any = payload.get("browser_state_hint", {});
    if isinstance(raw_browser_hint, dict) {
        browser_hint = sanitize_json_value(raw_browser_hint, 4, 12, 220);
    }

    v2_result: dict[str, any] = run_helper_v2({
        "objective": objective,
        "browser_session_id": browser_session_id,
        "browser_state_hint": browser_hint
    });
    if not bool(v2_result.get("ok", False)) {
        return {
            "ok": False,
            "error": safe_text(v2_result.get("error", ""), 160) or "v2 runtime failed",
            "helper_id": safe_text(helper.get("helper_id", ""), 80)
        };
    }

    final_output: dict[str, any] = v2_result.get("final_output", {}) if isinstance(v2_result.get("final_output", {}), dict) else {};
    plan_execution: dict[str, any] = v2_result.get("plan_execution", {}) if isinstance(v2_result.get("plan_execution", {}), dict) else {};
    summary: str = safe_text(final_output.get("summary", ""), 320);
    run_status: str = normalize_run_status(final_output.get("status", "failed"));
    structured_output: dict[str, any] = {
        "summary": summary,
        "reason": safe_text(final_output.get("reason", ""), 80),
        "helper_kind": normalize_helper_kind(agent_spec.get("kind", "browser_read")),
        "runtime_version": "v2",
        "task_blueprint": sanitize_json_value(v2_result.get("task_blueprint", {}), 5, 16, 220),
        "observation": sanitize_json_value(v2_result.get("observation", {}), 5, 16, 220),
        "source_candidates": sanitize_json_value(v2_result.get("source_candidates", []), 4, 8, 180),
        "page_artifacts": sanitize_json_value(v2_result.get("page_artifacts", []), 5, 8, 220),
        "synthesis_input": sanitize_json_value(v2_result.get("synthesis_input", {}), 5, 12, 220),
        "plan_execution": sanitize_json_value(plan_execution, 5, 16, 220),
        "objective": safe_text(final_output.get("objective", objective), 320),
        "status": run_status,
        "highlights": sanitize_json_value(final_output.get("highlights", []), 3, 8, 140),
        "sources": sanitize_json_value(final_output.get("sources", []), 4, 8, 180),
        "limitations": sanitize_json_value(final_output.get("limitations", []), 3, 8, 180),
        "confidence": safe_text(final_output.get("confidence", "low"), 24),
        "honest_notes": sanitize_json_value(final_output.get("honest_notes", []), 3, 6, 180)
    };

    finished_at: str = timestamp_now();
    run_record: dict[str, any] = normalize_helper_run({
        "run_id": new_run_id(),
        "helper_id": safe_text(helper.get("helper_id", ""), 80),
        "agent_spec_id": safe_text(agent_spec.get("agent_spec_id", ""), 80),
        "started_at": started_at,
        "finished_at": finished_at,
        "status": run_status,
        "trigger_type": trigger_type,
        "browser_session_id": browser_session_id,
        "summary": summary,
        "structured_output": structured_output,
        "runtime_state": {
            "mission": objective,
            "runtime_version": "v2",
            "execution_strategy": safe_text(plan_execution.get("strategy", "telemetry_first_read_only_v2"), 60),
            "task_blueprint": sanitize_json_value(v2_result.get("task_blueprint", {}), 5, 16, 220),
            "plan_execution": sanitize_json_value(plan_execution, 5, 16, 220)
        },
        "logs": [
            "Loaded helper " + safe_text(helper.get("name", ""), 120) + ".",
            "Runtime version: v2.",
            "Execution strategy: " + safe_text(plan_execution.get("strategy", "telemetry_first_read_only_v2"), 60) + "."
        ],
        "errors": []
    });
    if not run_record {
        return {"ok": False, "error": "run normalization failed"};
    }

    write_json_file(helper_run_file(str(run_record.get("run_id", ""))), run_record);
    return {
        "ok": True,
        "run": run_record,
        "helper_bundle": helper_bundle(helper, agent_spec, run_record)
    };
}

"""R: Dispatch one helper run to the persisted runtime version without widening the migration surface.
M: Loads helper/spec once, defaults old records to v1, and forwards only the approved read-only briefing slice to v2.
E: Unknown or missing runtime selections collapse to v1 so existing helpers keep their previous behavior.
"""
def run_helper_once(payload: dict[str, any]) -> dict[str, any] {
    helper_id: str = safe_text(payload.get("helper_id", ""), 80);
    if not helper_id {
        return {"ok": False, "error": "helper_id is required"};
    }

    helper: dict[str, any] = load_helper_definition(helper_id);
    if not helper {
        return {"ok": False, "error": "helper not found", "helper_id": helper_id};
    }

    agent_spec: dict[str, any] = load_agent_spec(str(helper.get("agent_spec_id", "")));
    if not agent_spec {
        return {"ok": False, "error": "agent spec not found", "helper_id": helper_id};
    }

    runtime_version: str = normalize_runtime_version(helper.get("runtime_version", "v1"));
    if runtime_version == "v2" and helper_is_v2_eligible(agent_spec) {
        return run_helper_once_v2(payload, helper, agent_spec);
    }
    return run_helper_once_v1(payload);
}

"""R: List persisted runs for one helper so the Helpers workspace can inspect history.
M: Validates helper existence, loads matching run files, optionally applies a limit, and returns newest-first runs.
E: Unknown helper ids return a direct error so callers do not mistake empty history for a missing helper.
"""
def list_helper_runs(payload: dict[str, any]) -> dict[str, any] {
    helper_id: str = safe_text(payload.get("helper_id", ""), 80);
    if not helper_id {
        return {"ok": False, "error": "helper_id is required"};
    }

    helper: dict[str, any] = load_helper_definition(helper_id);
    if not helper {
        return {"ok": False, "error": "helper not found", "helper_id": helper_id};
    }

    limit: int = 12;
    raw_limit: any = payload.get("limit", 12);
    if isinstance(raw_limit, int) and not isinstance(raw_limit, bool) and raw_limit > 0 {
        limit = raw_limit;
    }

    runs: list[any] = load_runs_for_helper(helper_id);
    if len(runs) > limit {
        runs = runs[:limit];
    }

    return {"ok": True, "helper_id": helper_id, "runs": runs, "count": len(runs)};
}

"""R: Fetch one persisted helper run by id for later renderer drill-downs or backend debugging.
M: Loads the run file and returns the normalized record when it exists.
E: Missing run ids or unknown records return explicit errors instead of empty success payloads.
"""
def get_helper_run(payload: dict[str, any]) -> dict[str, any] {
    run_id: str = safe_text(payload.get("run_id", ""), 80);
    if not run_id {
        return {"ok": False, "error": "run_id is required"};
    }

    run_record: dict[str, any] = load_helper_run(run_id);
    if not run_record {
        return {"ok": False, "error": "run not found", "run_id": run_id};
    }

    return {"ok": True, "run": run_record};
}

"""R: Parse one JSON payload for helper layer CLI commands.
M: Joins CLI args from index 2 onward and decodes a single dict payload.
E: Invalid JSON returns the empty dict so dispatch can emit stable usage errors.
"""
def parse_payload() -> dict[str, any] {
    raw_payload: str = "{}";
    if len(sys.argv) > 2 {
        raw_payload = " ".join(sys.argv[2:]);
    }

    try {
        parsed: any = json.loads(raw_payload);
        if isinstance(parsed, dict) {
            return parsed;
        }
    } except json.JSONDecodeError {
        return {};
    }

    return {};
}

"""R: Route one helper-layer CLI command into the correct backend operation.
M: Maps stable command names to helper creation, lookup, listing, and run handlers.
E: Unknown commands return a usage payload instead of raising.
"""
def dispatch(command: str, payload: dict[str, any]) -> dict[str, any] {
    if command == "create_helper" {
        return create_helper(payload);
    }
    if command == "list_helpers" {
        return list_helpers(payload);
    }
    if command == "get_helper" {
        return get_helper(payload);
    }
    if command == "run_helper_once" {
        return run_helper_once(payload);
    }
    if command == "list_helper_runs" {
        return list_helper_runs(payload);
    }
    if command == "get_helper_run" {
        return get_helper_run(payload);
    }

    return {
        "ok": False,
        "error": "unknown command",
        "valid_commands": [
            "create_helper",
            "list_helpers",
            "get_helper",
            "run_helper_once",
            "list_helper_runs",
            "get_helper_run"
        ]
    };
}

"""R: Decide whether the helper layer should execute its CLI entrypoint.
M: Treats non-empty non-path-like argv values as commands and ignores import-time script paths.
E: Unknown commands still dispatch so the caller receives the normal usage payload.
"""
def should_dispatch_cli(command: str) -> bool {
    if not command {
        return False;
    }

    return ("/" not in command) and ("\\" not in command) and not command.endswith(".jac");
}

with entry {
    command: str = "";
    if len(sys.argv) > 1 {
        command = str(sys.argv[1]);
    }

    if should_dispatch_cli(command) {
        payload: dict[str, any] = parse_payload();
        result: dict[str, any] = dispatch(command, payload);
        print(json.dumps(result));
    }
}
