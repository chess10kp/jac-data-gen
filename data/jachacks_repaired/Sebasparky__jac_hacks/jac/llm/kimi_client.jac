"""
Jac-native compile-time enrichment client.

Purpose:
- Resolve local or hosted LLM configuration from `.env` and process environment.
- Call either a Moonshot-hosted Kimi model or a truly local Ollama model.
- Return a small enrichment object that the compilation layer can merge safely.
"""

import os;
import json;
import time;
import subprocess;
import from shutil { which }
import from urllib.request { Request, urlopen }
import from urllib.error { HTTPError, URLError }

glob DEFAULT_KIMI_BASE_URL: str = "https://api.moonshot.ai/v1";
glob DEFAULT_KIMI_MODEL: str = "kimi-k2.5";
glob DEFAULT_OLLAMA_BASE_URL: str = "http://127.0.0.1:11434";
glob DEFAULT_OLLAMA_MODEL: str = "qwen2.5:3b-instruct-q4_0";
glob OLLAMA_LOG_DIR: str = "./jac/layer_data/llm";
glob OLLAMA_LOG_FILE: str = OLLAMA_LOG_DIR + "/ollama-serve.log";
glob KIMI_CLI_CONFIG_PATH: str = os.path.expanduser("~/.kimi/config.toml");
glob KIMI_CLI_AGENT_FILE: str = os.path.abspath("./jac/llm/kimi_compile_agent.yaml");
glob KIMI_CLI_READY_PROMPT: str = "Reply with exactly READY and nothing else.";

"""R: Normalize quoted config values reused across dotenv and TOML parsing.
M: Trims whitespace and removes one matching pair of wrapping quotes.
E: Unbalanced or unquoted strings are returned unchanged.
"""
def strip_wrapping_quotes(raw_value: str) -> str {
    value: str = str(raw_value or "").strip();
    if len(value) >= 2 {
        if (value.startswith("\"") and value.endswith("\"")) or
           (value.startswith("'") and value.endswith("'")) {
            return value[1:-1];
        }
    }

    return value;
}

"""R: Parse one local `.env` file into a small key/value map.
M: Reads non-comment `KEY=VALUE` lines and trims optional wrapping quotes.
E: Missing files and malformed lines are ignored so runtime config stays fail-soft.
"""
def parse_dotenv(path: str = ".env") -> dict[str, str] {
    values: dict[str, str] = {};
    if not os.path.exists(path) {
        return values;
    }

    try {
        with open(path, "r") as file {
            for raw_line in file {
                line: str = str(raw_line).strip();
                if not line or line.startswith("#") or "=" not in line {
                    continue;
                }

                split_at: int = line.find("=");
                key: str = str(line[:split_at]).strip();
                value: str = strip_wrapping_quotes(str(line[split_at + 1:]).strip());
                if not key {
                    continue;
                }

                values[key] = value;
            }
        }
    } except OSError {
        return {};
    }

    return values;
}

"""R: Read one config value from process env first, then `.env`, then fallback.
M: Checks `os.environ`, falls back to parsed dotenv values, and trims whitespace.
E: Empty values collapse to the provided fallback.
"""
def env_value(name: str, dotenv: dict[str, str], fallback: str = "") -> str {
    process_value: str = str(os.environ.get(name, "") or "").strip();
    if process_value {
        return process_value;
    }

    file_value: str = str(dotenv.get(name, "") or "").strip();
    if file_value {
        return file_value;
    }

    return fallback;
}

"""R: Detect placeholder secrets so the compiler does not attempt fake API calls.
M: Rejects empty values and common sample-token markers like `your-...` and `replace-me`.
E: Conservative heuristic may classify custom sample values as placeholders.
"""
def is_placeholder_secret(raw_value: str) -> bool {
    value: str = str(raw_value or "").strip();
    if not value {
        return True;
    }

    lowered: str = value.lower();
    if lowered.startswith("your-") or lowered.startswith("sk-your-") {
        return True;
    }
    if "replace" in lowered or "placeholder" in lowered or "api-key" in lowered {
        return True;
    }

    return False;
}

"""R: Convert loose env strings into booleans.
M: Accepts common truthy tokens used in `.env` files.
E: Unknown values resolve to false.
"""
def env_bool(raw_value: str) -> bool {
    lowered: str = str(raw_value or "").strip().lower();
    return lowered in ["1", "true", "yes", "on", "enabled"];
}

"""R: Resolve the usable local Ollama binary path without requiring a system install.
M: Checks PATH first, then falls back to the user-local install path used by this project.
E: Missing binaries resolve to the empty string.
"""
def find_ollama_binary() -> str {
    path: str = str(which("ollama") or "").strip();
    if path {
        return path;
    }

    fallback: str = os.path.expanduser("~/.local/bin/ollama");
    if os.path.exists(fallback) {
        return fallback;
    }
    return "";
}

"""R: Normalize a local Ollama base URL whether config uses the root or `/v1`.
M: Trims a trailing slash and strips one `/v1` suffix so health checks hit the native API.
E: Empty values fall back to the default localhost Ollama URL.
"""
def ollama_root_base_url(raw_base_url: str) -> str {
    base_url: str = str(raw_base_url or DEFAULT_OLLAMA_BASE_URL).strip().rstrip("/");
    if not base_url {
        return DEFAULT_OLLAMA_BASE_URL;
    }
    if base_url.endswith("/v1") {
        return str(base_url[:-3]).rstrip("/");
    }
    return base_url;
}

"""R: Read one small JSON document over HTTP.
M: Uses stdlib URL loading and returns a decoded object when the response is a dict.
E: Network failures and malformed JSON degrade to the provided fallback dict.
"""
def read_json_url(url: str, fallback: dict[str, any] = {}, timeout: int = 5) -> dict[str, any] {
    try {
        response: any = urlopen(url, timeout=timeout);
        raw_bytes: any = response.read();
        response.close();
        parsed: any = json.loads(str(raw_bytes.decode("utf-8")));
        if isinstance(parsed, dict) {
            return parsed;
        }
    } except OSError {
        return fallback;
    } except json.JSONDecodeError {
        return fallback;
    }
    return fallback;
}

"""R: Return the set of models currently available from the local Ollama daemon.
M: Calls the native `/api/tags` endpoint and extracts each advertised model name.
E: Missing or offline daemons return an empty list.
"""
def local_ollama_model_names(base_url: str) -> list[str] {
    tags: dict[str, any] = read_json_url(ollama_root_base_url(base_url) + "/api/tags", {}, 5);
    models: any = tags.get("models", []);
    names: list[str] = [];
    if not isinstance(models, list) {
        return names;
    }

    for model_info in models {
        if not isinstance(model_info, dict) {
            continue;
        }
        name: str = str(model_info.get("name", "")).strip();
        if name {
            names.append(name);
        }
    }
    return names;
}

"""R: Check whether the local Ollama HTTP API is responding.
M: Reads `/api/version` and treats a non-empty version field as ready.
E: Offline daemons return false without raising.
"""
def local_ollama_ready(base_url: str) -> bool {
    version_info: dict[str, any] = read_json_url(ollama_root_base_url(base_url) + "/api/version", {}, 3);
    return str(version_info.get("version", "")).strip() != "";
}

"""R: Start the local Ollama daemon in the background when local compile mode is selected.
M: Launches `ollama serve` detached with localhost binding, no cloud remotes, and a small log file.
E: If the daemon is already up or the binary is missing, this safely returns false.
"""
def start_local_ollama_server(base_url: str) -> bool {
    if local_ollama_ready(base_url) {
        return True;
    }

    cli_path: str = find_ollama_binary();
    if not cli_path {
        return False;
    }

    os.makedirs(OLLAMA_LOG_DIR, exist_ok=True);
    log_file: any = None;
    try {
        log_file = open(OLLAMA_LOG_FILE, "a");
        subprocess.Popen(
            [cli_path, "serve"],
            stdout=log_file,
            stderr=log_file,
            start_new_session=True,
            env={
                **os.environ,
                "OLLAMA_HOST": ollama_root_base_url(base_url),
                "OLLAMA_NO_CLOUD": "1"
            }
        );
    } except OSError {
        if log_file is not None {
            log_file.close();
        }
        return False;
    }

    for _ in range(12) {
        time.sleep(0.5);
        if local_ollama_ready(base_url) {
            return True;
        }
    }
    return False;
}

"""R: Resolve whether the requested truly local Ollama model is available for compile enrichment.
M: Checks the binary, auto-starts the daemon when needed, then verifies the target model is installed.
E: Missing installs or models return explicit reasons so setup issues are easy to fix.
"""
def resolve_local_ollama_status(model: str, base_url: str) -> dict[str, any] {
    cli_path: str = find_ollama_binary();
    status: dict[str, any] = {
        "available": cli_path != "",
        "ready": False,
        "path": cli_path,
        "reason": ""
    };

    if not cli_path {
        status["reason"] = "Local Ollama is not installed.";
        return status;
    }

    if not local_ollama_ready(base_url) and not start_local_ollama_server(base_url) {
        status["reason"] = "Local Ollama could not be reached on " + ollama_root_base_url(base_url) + ".";
        return status;
    }

    model_names: list[str] = local_ollama_model_names(base_url);
    if model not in model_names {
        status["reason"] = "Local Ollama is running, but model `" + model + "` is not installed. Run `ollama pull " + model + "`.";
        return status;
    }

    status["ready"] = True;
    status["reason"] = "Local compile enrichment enabled via Ollama.";
    return status;
}

"""R: Read the default model from the local `kimi` CLI config when present.
M: Scans the top-level `default_model = ...` line in `~/.kimi/config.toml`.
E: Missing files, unreadable config, or empty values resolve to the empty string.
"""
def read_kimi_cli_default_model(config_path: str = KIMI_CLI_CONFIG_PATH) -> str {
    path: str = os.path.expanduser(str(config_path or KIMI_CLI_CONFIG_PATH));
    if not os.path.exists(path) {
        return "";
    }

    try {
        with open(path, "r") as file {
            for raw_line in file {
                line: str = str(raw_line).strip();
                if not line or line.startswith("#") or line.startswith("[") or "=" not in line {
                    continue;
                }

                if not line.startswith("default_model") {
                    continue;
                }

                split_at: int = line.find("=");
                if split_at < 0 {
                    continue;
                }

                return strip_wrapping_quotes(str(line[split_at + 1:]).strip());
            }
        }
    } except OSError {
        return "";
    }

    return "";
}

"""R: Return the first non-empty line from tool output for concise status messages.
M: Scans line-by-line and stops at the first trimmed value.
E: Empty multi-line strings return the empty string.
"""
def first_non_empty_line(raw_text: str) -> str {
    for raw_line in str(raw_text or "").splitlines() {
        line: str = str(raw_line).strip();
        if line {
            return line;
        }
    }
    return "";
}

"""R: Build the exact local `kimi` CLI command used for probes and compile calls.
M: Uses print mode plus a no-tools agent file so the CLI only returns text.
E: Missing agent files are skipped so the command still works in degraded environments.
"""
def build_kimi_cli_command(prompt: str, config: dict[str, any]) -> list[str] {
    command: list[str] = [
        str(config.get("cli_path", "") or "kimi"),
        "--quiet",
        "--print",
        "--output-format",
        "text",
        "--final-message-only"
    ];

    if os.path.exists(KIMI_CLI_AGENT_FILE) {
        command.append("--agent-file");
        command.append(KIMI_CLI_AGENT_FILE);
    }

    thinking_flag: str = "--thinking" if str(config.get("thinking_mode", "disabled")) == "enabled" else "--no-thinking";
    command.append(thinking_flag);

    model: str = str(config.get("model", "") or "").strip();
    if model {
        command.append("-m");
        command.append(model);
    }

    command.append("-p");
    command.append(prompt);
    return command;
}

"""R: Determine whether the local `kimi` CLI is installed and ready for non-interactive use.
M: Checks the binary, reads its default model, then runs one tiny readiness prompt.
E: Missing installs, missing login, timeouts, and auth failures return a descriptive inactive state.
"""
def resolve_kimi_cli_status(thinking_mode: str = "disabled") -> dict[str, any] {
    cli_path: str = str(which("kimi") or "").strip();
    default_model: str = read_kimi_cli_default_model();
    status: dict[str, any] = {
        "available": cli_path != "",
        "configured": False,
        "ready": False,
        "path": cli_path,
        "model": default_model,
        "reason": ""
    };

    if not cli_path {
        status["reason"] = "Local `kimi` CLI is not installed.";
        return status;
    }

    if not default_model {
        status["reason"] = "Kimi CLI is installed but not logged in. Run `kimi login` once to authorize it.";
        return status;
    }

    status["configured"] = True;

    try {
        probe_result: any = subprocess.run(
            build_kimi_cli_command(
                KIMI_CLI_READY_PROMPT,
                {
                    "cli_path": cli_path,
                    "model": default_model,
                    "thinking_mode": thinking_mode
                }
            ),
            capture_output=True,
            text=True,
            timeout=20
        );
    } except subprocess.TimeoutExpired {
        status["reason"] = "Kimi CLI probe timed out.";
        return status;
    } except OSError as err {
        status["reason"] = "Kimi CLI could not be started: " + str(err);
        return status;
    }

    stdout: str = str(probe_result.stdout or "").strip();
    stderr: str = str(probe_result.stderr or "").strip();
    combined: str = "\n".join([stdout, stderr]).strip();
    first_line: str = first_non_empty_line(combined);
    lowered: str = first_line.lower();

    if probe_result.returncode == 0 and stdout == "READY" {
        status["ready"] = True;
        status["reason"] = "Kimi compile enrichment enabled via local `kimi` CLI.";
        return status;
    }

    if "llm not set" in lowered or "login" in lowered {
        status["configured"] = False;
        status["reason"] = "Kimi CLI is installed but not logged in. Run `kimi login` once to authorize it.";
        return status;
    }

    status["reason"] = "Kimi CLI is installed but not ready" + (": " + first_line if first_line else ".");
    return status;
}

"""R: Build the effective compile configuration from local settings.
M: Supports a truly local Ollama model plus the existing hosted Moonshot Kimi path.
E: Returns `enabled: false` with a concrete reason when the selected provider is unavailable.
"""
def resolve_kimi_compile_config() -> dict[str, any] {
    dotenv: dict[str, str] = parse_dotenv();

    provider: str = env_value("LLM_PROVIDER", dotenv, "").lower();
    local_requested: bool = provider in ["ollama", "local"];
    model_fallback: str = DEFAULT_OLLAMA_MODEL if local_requested else DEFAULT_KIMI_MODEL;
    base_url_fallback: str = DEFAULT_OLLAMA_BASE_URL if local_requested else DEFAULT_KIMI_BASE_URL;
    model: str = env_value("LLM_MODEL", dotenv, env_value("MOONSHOT_MODEL", dotenv, env_value("MODEL", dotenv, model_fallback)));
    base_url: str = env_value("LLM_BASE_URL", dotenv, env_value("MOONSHOT_BASE_URL", dotenv, base_url_fallback)).rstrip("/");
    api_key: str = env_value(
        "LLM_API_KEY",
        dotenv,
        env_value("MOONSHOT_API_KEY", dotenv, "")
    );
    thinking_mode: str = env_value("KIMI_THINKING", dotenv, "disabled").lower();
    allow_compile_raw: str = env_value("LLM_ALLOW_COMPILE", dotenv, "true");
    normalized_thinking_mode: str = thinking_mode if thinking_mode in ["enabled", "disabled"] else "disabled";

    provider_requested: bool = provider in ["kimi", "moonshot"];
    local_selected: bool = local_requested or base_url.startswith("http://127.0.0.1:11434") or base_url.startswith("http://localhost:11434");
    model_requested: bool = str(model or "").lower().startswith("kimi-");
    allow_compile: bool = env_bool(allow_compile_raw);
    api_key_present: bool = str(api_key or "").strip() != "";
    api_key_placeholder: bool = is_placeholder_secret(api_key);
    api_key_ready: bool = api_key_present and not api_key_placeholder;
    ollama_status: dict[str, any] = {};
    cli_status: dict[str, any] = resolve_kimi_cli_status(normalized_thinking_mode);
    cli_ready: bool = bool(cli_status.get("ready", False));

    enabled: bool = False;
    resolved_provider: str = "kimi";
    reason: str = "Compile enrichment enabled";
    transport: str = "";
    resolved_model: str = model if model else DEFAULT_KIMI_MODEL;

    if local_selected {
        resolved_provider = "ollama";
        resolved_model = model if model else DEFAULT_OLLAMA_MODEL;
        base_url = ollama_root_base_url(base_url if base_url else DEFAULT_OLLAMA_BASE_URL);
        if not allow_compile {
            reason = "LLM_ALLOW_COMPILE is disabled.";
        } else {
            ollama_status = resolve_local_ollama_status(resolved_model, base_url);
            if bool(ollama_status.get("ready", False)) {
                enabled = True;
                transport = "local";
                reason = str(ollama_status.get("reason", "Local compile enrichment enabled via Ollama."));
            } else {
                reason = str(ollama_status.get("reason", "Local Ollama compile enrichment is not configured."));
            }
        }
    } elif not (provider_requested or model_requested) {
        reason = "No compile provider is selected. Set LLM_PROVIDER=ollama for a truly local model or LLM_PROVIDER=kimi for Moonshot.";
    } elif not allow_compile {
        reason = "LLM_ALLOW_COMPILE is disabled.";
    } elif api_key_ready {
        enabled = True;
        transport = "api";
        reason = "Kimi compile enrichment enabled via Moonshot API.";
    } elif cli_ready {
        enabled = True;
        transport = "cli";
        resolved_model = str(cli_status.get("model", "") or resolved_model);
        reason = str(cli_status.get("reason", "Kimi compile enrichment enabled via local `kimi` CLI."));
    } else {
        api_reason: str = "";
        cli_reason: str = str(cli_status.get("reason", "") or "");

        if not api_key_present {
            api_reason = "LLM_API_KEY is missing.";
        } elif api_key_placeholder {
            api_reason = "LLM_API_KEY is still set to the placeholder value in .env.";
        }

        if api_reason and cli_reason {
            if not bool(cli_status.get("available", False)) {
                reason = api_reason + " Install the local `kimi` CLI and run `kimi login`, or add a real LLM_API_KEY.";
            } elif api_key_placeholder {
                reason = cli_reason + " The current LLM_API_KEY in .env is still a placeholder, so the hosted API path is also inactive.";
            } else {
                reason = cli_reason + " " + api_reason + " Add a real LLM_API_KEY if you want the hosted API path instead.";
            }
        } elif cli_reason {
            reason = cli_reason;
        } elif api_reason {
            reason = api_reason;
        } else {
            reason = "Kimi compile enrichment is not configured.";
        }
    }

    return {
        "enabled": enabled,
        "provider": resolved_provider,
        "transport": transport,
        "model": resolved_model if resolved_model else (DEFAULT_OLLAMA_MODEL if resolved_provider == "ollama" else DEFAULT_KIMI_MODEL),
        "base_url": base_url if base_url else (DEFAULT_OLLAMA_BASE_URL if resolved_provider == "ollama" else DEFAULT_KIMI_BASE_URL),
        "api_key": api_key if api_key_ready else "",
        "ollama_path": str(ollama_status.get("path", "") or find_ollama_binary()),
        "cli_path": str(cli_status.get("path", "") or ""),
        "thinking_mode": normalized_thinking_mode,
        "allow_compile": allow_compile,
        "reason": reason
    };
}

"""R: Build a compact event summary suitable for model-side workflow enrichment.
M: Keeps only event type, URL, labels, and masked values from the first few cleaned events.
E: Non-dict events are skipped; long values stay bounded by upstream normalization.
"""
def compact_event_summary(cleaned: dict[str, any], limit: int = 10) -> list[any] {
    items: list[any] = [];
    events: any = cleaned.get("events", []);
    if not isinstance(events, list) {
        return items;
    }

    count: int = 0;
    for event in events {
        if count >= limit or not isinstance(event, dict) {
            continue;
        }

        element: any = event.get("element", {});
        target_label: str = "";
        if isinstance(element, dict) {
            target_label = str(
                element.get("label", "") or
                element.get("name", "") or
                element.get("placeholder", "") or
                element.get("innerText", "")
            );
        }

        items.append({
            "type": str(event.get("type", "")),
            "url": str(event.get("url", "")),
            "label": target_label,
            "value": "__redacted__" if bool(event.get("masked", False)) else str(event.get("value", ""))
        });
        count += 1;
    }

    return items;
}

"""R: Extract the highest-value semantic clues from raw observation events.
M: Scans recent events for `semantic` payloads and returns the newest non-empty fields.
E: Missing semantic telemetry yields an empty dict.
"""
def latest_semantic_summary(raw_session: dict[str, any]) -> dict[str, any] {
    summary: dict[str, any] = {};
    events: any = raw_session.get("events", []);
    if not isinstance(events, list) {
        return summary;
    }

    for raw_event in events {
        if not isinstance(raw_event, dict) {
            continue;
        }
        semantic: any = raw_event.get("semantic", {});
        if not isinstance(semantic, dict) or not semantic {
            continue;
        }

        summary = {
            "title": str(semantic.get("title", "")),
            "page_kind": str(semantic.get("page_kind", "")),
            "workflow_stage": str(semantic.get("workflow_stage", "")),
            "primary_actions": semantic.get("primary_actions", []) if isinstance(semantic.get("primary_actions", []), list) else [],
            "headings": semantic.get("headings", []) if isinstance(semantic.get("headings", []), list) else []
        };
    }

    return summary;
}

"""R: Build the shared instructions sent to the selected model for compile enrichment.
M: Provides the heuristic workflow plus a strict JSON output contract.
E: Keeps the contract intentionally compact to reduce latency and parsing risk.
"""
def build_kimi_compile_instructions() -> str {
    return """
You are enriching a heuristic browser workflow compilation for Jac Browser.
Return exactly one JSON object.

Required output shape:
{
  "context": {
    "summary": "short paragraph",
    "successCriteria": ["criterion 1", "criterion 2"]
  },
  "steps": [
    {
      "type": "same as input step type",
      "name": "short human-readable step name",
      "confidence": 0.0
    }
  ],
  "model": {
    "provider": "provider name",
    "model": "model name",
    "thinking_mode": "disabled"
  }
}

Rules:
- Keep the exact same number of steps as the heuristic workflow.
- Keep each step type identical to the corresponding heuristic step.
- Only enrich summary, success criteria, step names, and confidence.
- Use the user's explanation when present to clarify intent and success criteria.
- Use confidence from 0.0 to 1.0.
- Be concise and practical.
""".strip();
}

"""R: Build the compact trace context shared by all compile enrichment transports.
M: Packages the cleaned event summary plus the heuristic workflow into one JSON object.
E: Missing optional fields degrade to empty strings, arrays, or objects.
"""
def build_kimi_compile_context(
    raw_session: dict[str, any],
    normalized_session: dict[str, any],
    cleaned: dict[str, any],
    partial: dict[str, any]
) -> dict[str, any] {
    return {
        "goal": str(normalized_session.get("goalContext", "")),
        "user_explanation": str(normalized_session.get("userExplanation", "")),
        "start_url": str(normalized_session.get("startUrl", "")),
        "status": str(normalized_session.get("status", "")),
        "semantic_summary": latest_semantic_summary(raw_session),
        "event_summary": compact_event_summary(cleaned, 12),
        "heuristic_workflow": {
            "name": str(partial.get("name", "")),
            "context": partial.get("context", {}),
            "inputs": partial.get("inputs", []),
            "steps": partial.get("steps", [])
        }
    };
}

def build_kimi_compile_request(
    raw_session: dict[str, any],
    normalized_session: dict[str, any],
    cleaned: dict[str, any],
    partial: dict[str, any],
    config: dict[str, any]
) -> dict[str, any] {
    system_prompt: str = build_kimi_compile_instructions();
    request_context: dict[str, any] = build_kimi_compile_context(
        raw_session,
        normalized_session,
        cleaned,
        partial
    );

    payload: dict[str, any] = {
        "model": str(config.get("model", DEFAULT_KIMI_MODEL)),
        "messages": [
            {
                "role": "system",
                "content": "You are a careful workflow compiler assistant."
            },
            {
                "role": "system",
                "content": system_prompt
            },
            {
                "role": "user",
                "content": json.dumps(request_context)
            }
        ],
        "response_format": {"type": "json_object"},
        "max_tokens": 1800
    };

    if str(config.get("thinking_mode", "disabled")) == "disabled" {
        payload["thinking"] = {"type": "disabled"};
    }

    return payload;
}

"""R: Build the native Ollama chat payload for truly local compile enrichment.
M: Reuses the shared prompt contract and asks Ollama for one non-streamed JSON reply.
E: Uses deterministic options so small local models stay predictable.
"""
def build_ollama_chat_request(
    raw_session: dict[str, any],
    normalized_session: dict[str, any],
    cleaned: dict[str, any],
    partial: dict[str, any],
    config: dict[str, any]
) -> dict[str, any] {
    system_prompt: str = build_kimi_compile_instructions();
    request_context: dict[str, any] = build_kimi_compile_context(
        raw_session,
        normalized_session,
        cleaned,
        partial
    );

    return {
        "model": str(config.get("model", DEFAULT_OLLAMA_MODEL)),
        "messages": [
            {
                "role": "system",
                "content": "You are a careful workflow compiler assistant."
            },
            {
                "role": "system",
                "content": system_prompt
            },
            {
                "role": "user",
                "content": json.dumps(request_context)
            }
        ],
        "stream": False,
        "format": "json",
        "options": {
            "temperature": 0
        }
    };
}

"""R: Build the single text prompt sent through the local `kimi` CLI fallback.
M: Reuses the same instructions and JSON context as the API path, but in one plain-text prompt.
E: Prompt stays deterministic and self-contained so the CLI does not need workspace access.
"""
def build_kimi_cli_prompt(
    raw_session: dict[str, any],
    normalized_session: dict[str, any],
    cleaned: dict[str, any],
    partial: dict[str, any]
) -> str {
    request_context: dict[str, any] = build_kimi_compile_context(
        raw_session,
        normalized_session,
        cleaned,
        partial
    );
    return (
        "You are a careful workflow compiler assistant.\n\n" +
        build_kimi_compile_instructions() +
        "\n\nInput JSON:\n" +
        json.dumps(request_context)
    );
}

"""R: POST one JSON payload to the Kimi chat completions endpoint.
M: Uses Python stdlib HTTP utilities so the integration stays Jac-native.
E: Raises descriptive exceptions for HTTP/network/parse failures.
"""
def post_kimi_json(config: dict[str, any], payload: dict[str, any]) -> dict[str, any] {
    endpoint: str = str(config.get("base_url", DEFAULT_KIMI_BASE_URL)).rstrip("/") + "/chat/completions";
    api_key: str = str(config.get("api_key", ""));
    request_body: bytes = json.dumps(payload).encode("utf-8");
    headers: dict[str, str] = {"Content-Type": "application/json"};
    if api_key {
        headers["Authorization"] = "Bearer " + api_key;
    }

    request: any = Request(
        endpoint,
        data=request_body,
        headers=headers,
        method="POST"
    );

    try {
        response: any = urlopen(request, timeout=30);
        raw_bytes: any = response.read();
        response.close();
        raw_body: str = str(raw_bytes.decode("utf-8"));
        return json.loads(raw_body);
    } except HTTPError as err {
        details: str = "";
        try {
            details = err.read().decode("utf-8");
        } except Exception {
            details = "";
        }
        raise Exception("Kimi HTTP " + str(err.code) + (": " + details if details else ""));
    } except URLError as err {
        raise Exception("Kimi network error: " + str(err.reason or err));
    }
}

"""R: POST one native chat payload to a local Ollama daemon.
M: Uses the non-streaming `/api/chat` endpoint and decodes the returned JSON object.
E: Raises descriptive exceptions for offline daemons, model issues, and malformed responses.
"""
def post_ollama_chat(config: dict[str, any], payload: dict[str, any]) -> dict[str, any] {
    endpoint: str = ollama_root_base_url(str(config.get("base_url", DEFAULT_OLLAMA_BASE_URL))) + "/api/chat";
    request_body: bytes = json.dumps(payload).encode("utf-8");

    request: any = Request(
        endpoint,
        data=request_body,
        headers={"Content-Type": "application/json"},
        method="POST"
    );

    try {
        response: any = urlopen(request, timeout=90);
        raw_bytes: any = response.read();
        response.close();
        raw_body: str = str(raw_bytes.decode("utf-8"));
        parsed: any = json.loads(raw_body);
        if isinstance(parsed, dict) {
            return parsed;
        }
    } except HTTPError as err {
        details: str = "";
        try {
            details = err.read().decode("utf-8");
        } except Exception {
            details = "";
        }
        raise Exception("Local Ollama HTTP " + str(err.code) + (": " + details if details else ""));
    } except URLError as err {
        raise Exception("Local Ollama network error: " + str(err.reason or err));
    }

    raise Exception("Local Ollama returned an invalid response");
}

"""R: Parse one JSON object even when the model wraps it in fences or extra prose.
M: Tries the raw text first, then a fenced-body variant, then the first outer JSON object slice.
E: Raises when no candidate parses into a JSON object.
"""
def parse_json_object_text(raw_text: str, source_label: str = "Kimi") -> dict[str, any] {
    trimmed: str = str(raw_text or "").strip();
    if not trimmed {
        raise Exception(source_label + " response content is empty");
    }

    candidates: list[str] = [trimmed];
    if trimmed.startswith("```") and trimmed.endswith("```") {
        lines: list[str] = trimmed.splitlines();
        if len(lines) >= 3 {
            fenced_body: str = "\n".join(lines[1:-1]).strip();
            if fenced_body and fenced_body not in candidates {
                candidates.append(fenced_body);
            }
        }
    }

    first_brace: int = trimmed.find("{");
    last_brace: int = trimmed.rfind("}");
    if first_brace >= 0 and last_brace > first_brace {
        json_slice: str = str(trimmed[first_brace:last_brace + 1]).strip();
        if json_slice and json_slice not in candidates {
            candidates.append(json_slice);
        }
    }

    for candidate in candidates {
        try {
            parsed: any = json.loads(candidate);
            if isinstance(parsed, dict) {
                return parsed;
            }
        } except json.JSONDecodeError {
            continue;
        }
    }

    raise Exception(source_label + " JSON response was malformed");
}

"""R: Extract the JSON-mode object returned by Kimi chat completions.
M: Reads `choices[0].message.content`, parses it as JSON, and returns the dict.
E: Raises when the response is incomplete, malformed, or missing a usable choice.
"""
def parse_kimi_json_mode_response(response: dict[str, any]) -> dict[str, any] {
    choices: any = response.get("choices", []);
    if not isinstance(choices, list) or not choices {
        raise Exception("Kimi response missing choices");
    }

    first_choice: any = choices[0];
    if not isinstance(first_choice, dict) {
        raise Exception("Kimi response choice is invalid");
    }

    message: any = first_choice.get("message", {});
    if not isinstance(message, dict) {
        raise Exception("Kimi response message is invalid");
    }

    content: any = message.get("content", "");
    if not isinstance(content, str) or not content.strip() {
        raise Exception("Kimi response content is empty");
    }

    parsed: dict[str, any] = parse_json_object_text(content, "Kimi");

    finish_reason: str = str(first_choice.get("finish_reason", ""));
    if finish_reason == "length" {
        parsed["_warning"] = "Kimi response was truncated";
    }

    return parsed;
}

"""R: Extract one JSON object from a non-streamed local Ollama chat response.
M: Reads `message.content`, then reuses the tolerant JSON-text parser shared by other transports.
E: Raises when Ollama returns an unexpected response shape or empty content.
"""
def parse_ollama_chat_response(response: dict[str, any]) -> dict[str, any] {
    message: any = response.get("message", {});
    if not isinstance(message, dict) {
        raise Exception("Local Ollama response message is invalid");
    }

    content: any = message.get("content", "");
    if not isinstance(content, str) or not content.strip() {
        raise Exception("Local Ollama response content is empty");
    }

    return parse_json_object_text(content, "Local Ollama");
}

"""R: Run compile enrichment through the local `kimi` CLI and parse its JSON reply.
M: Executes print mode with a no-tools agent and converts the final message into a dict.
E: Login issues, timeouts, and malformed output raise descriptive exceptions.
"""
def run_kimi_cli_json(config: dict[str, any], prompt: str) -> dict[str, any] {
    try {
        result: any = subprocess.run(
            build_kimi_cli_command(prompt, config),
            capture_output=True,
            text=True,
            timeout=90
        );
    } except subprocess.TimeoutExpired {
        raise Exception("Kimi CLI request timed out");
    } except OSError as err {
        raise Exception("Kimi CLI could not be started: " + str(err));
    }

    stdout: str = str(result.stdout or "").strip();
    stderr: str = str(result.stderr or "").strip();
    combined: str = "\n".join([stdout, stderr]).strip();
    first_line: str = first_non_empty_line(combined);
    lowered: str = first_line.lower();

    if result.returncode != 0 {
        if "llm not set" in lowered or "login" in lowered {
            raise Exception("Kimi CLI is installed but not logged in. Run `kimi login` once to authorize it.");
        }
        raise Exception("Kimi CLI failed" + (": " + first_line if first_line else ""));
    }

    response_text: str = stdout if stdout else combined;
    return parse_json_object_text(response_text, "Kimi CLI");
}

"""R: Run compile-time workflow enrichment through the selected provider.
M: Chooses the truly local Ollama path, Moonshot API path, or legacy Kimi CLI path.
E: Raises on config or transport failures so the compiler can fall back to heuristics with warnings.
"""
def kimi_compile_enrichment(
    raw_session: dict[str, any],
    normalized_session: dict[str, any],
    cleaned: dict[str, any],
    partial: dict[str, any],
    options: dict[str, any]
) -> dict[str, any] {
    config: dict[str, any] = resolve_kimi_compile_config();
    if not bool(config.get("enabled", False)) {
        raise Exception(str(config.get("reason", "Kimi compile enrichment is not enabled")));
    }

    parsed: dict[str, any] = {};
    provider: str = str(config.get("provider", "kimi") or "kimi");
    transport: str = str(config.get("transport", "") or "");

    if provider == "ollama" and transport == "local" {
        response: dict[str, any] = post_ollama_chat(
            config,
            build_ollama_chat_request(
                raw_session,
                normalized_session,
                cleaned,
                partial,
                config
            )
        );
        parsed = parse_ollama_chat_response(response);
    } elif transport == "cli" {
        parsed = run_kimi_cli_json(
            config,
            build_kimi_cli_prompt(
                raw_session,
                normalized_session,
                cleaned,
                partial
            )
        );
    } else {
        request_payload: dict[str, any] = build_kimi_compile_request(
            raw_session,
            normalized_session,
            cleaned,
            partial,
            config
        );

        response: dict[str, any] = post_kimi_json(config, request_payload);
        parsed = parse_kimi_json_mode_response(response);
    }

    parsed["model"] = {
        "provider": provider,
        "model": str(config.get("model", DEFAULT_OLLAMA_MODEL if provider == "ollama" else DEFAULT_KIMI_MODEL)),
        "thinking_mode": str(config.get("thinking_mode", "disabled")),
        "transport": transport if transport else ("local" if provider == "ollama" else "api")
    };
    return parsed;
}
