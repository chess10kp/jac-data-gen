import os;
import from os { path }
import from byllm.lib { Model }
import from byllm.config_loader { get_byllm_config }

glob DEFAULT_LLM_MODEL: str = "gpt-4o-mini";
glob SUPPORTED_LLM_MODELS: list[str] = ["gpt-4o-mini", "gpt-4.1-mini", "gpt-4o", "gpt-4.1"];
glob _byllm_config = get_byllm_config();
glob _model_config: dict = _byllm_config.get_model_config();
glob _call_params_config: dict = _byllm_config.get_call_params_config();

def project_root_dir() -> str {
    current: str = os.getcwd();
    previous: str = "";
    while current and current != previous {
        if path.exists(path.join(current, "jac.toml")) {
            return current;
        }
        previous = current;
        current = path.dirname(current);
    }
    return os.getcwd();
}

def trim_text(text: str) -> str {
    return text.strip();
}

def split_once(text: str, token: str) -> list[str] {
    return text.split(token, 1);
}

def read_env_local() -> dict[str, str] {
    values: dict[str, str] = {};
    env_path: str = path.join(project_root_dir(), ".env.local");
    if not path.exists(env_path) {
        return values;
    }
    try {
        with open(env_path, "r", encoding="utf-8") as handle {
            for raw_line in handle.readlines() {
                line: str = trim_text(raw_line);
                if not line or line.startswith("#") or "=" not in line {
                    continue;
                }
                parts: list[str] = split_once(line, "=");
                if len(parts) < 2 {
                    continue;
                }
                key: str = trim_text(parts[0]);
                value: str = trim_text(parts[1]);
                if key and key not in values {
                    values[key] = value;
                }
            }
        }
    } except OSError {
        return {};
    } except UnicodeError {
        return {};
    }
    return values;
}

def env_value(name: str) -> str {
    shell_value: str = str(os.environ.get(name, ""));
    if shell_value {
        return shell_value;
    }
    local_env: dict[str, str] = read_env_local();
    if name in local_env {
        return local_env[name];
    }
    return "";
}

def normalize_model_name(model_name: str = "") -> str {
    configured: str = trim_text(model_name);
    if not configured {
        configured = env_value("REPOGHOST_OPENAI_MODEL");
    }
    if not configured {
        configured = str(_model_config.get("default_model", DEFAULT_LLM_MODEL));
    }
    if configured.startswith("openai/") {
        return configured;
    }
    return "openai/" + configured;
}

def display_model_name(model_name: str) -> str {
    parts: list[str] = model_name.split("/");
    if len(parts) > 1 {
        return parts[len(parts) - 1];
    }
    return model_name;
}

glob _resolved_api_key: str = env_value("OPENAI_API_KEY");
glob _resolved_model: str = normalize_model_name();
glob _active_llm_state: dict[str, str] = {
    "api_key": _resolved_api_key,
    "model": _resolved_model
};

def active_api_key() -> str {
    return str(_active_llm_state.get("api_key", ""));
}

def active_model() -> str {
    return str(_active_llm_state.get("model", _resolved_model));
}

glob llm = Model(
    model_name=active_model(),
    api_key=active_api_key(),
    config=_model_config,
    call_params=_call_params_config
);

def:pub supported_llm_models() -> list[str] {
    return SUPPORTED_LLM_MODELS;
}

def:pub default_llm_model() -> str {
    return display_model_name(_resolved_model);
}

def:pub configure_request_llm(user_api_key: str = "", user_model: str = "") -> dict[str, str] {
    previous: dict[str, str] = {
        "api_key": active_api_key(),
        "model": active_model()
    };
    next_api_key: str = trim_text(user_api_key);
    if not next_api_key {
        next_api_key = _resolved_api_key;
    }
    next_model: str = normalize_model_name(user_model);
    _active_llm_state["api_key"] = next_api_key;
    _active_llm_state["model"] = next_model;
    llm.api_key = next_api_key;
    llm.model_name = next_model;
    return previous;
}

def:pub restore_request_llm(previous_api_key: str = "", previous_model: str = "") -> None {
    restored_api_key: str = previous_api_key;
    restored_model: str = previous_model;
    if not restored_model {
        restored_model = _resolved_model;
    }
    _active_llm_state["api_key"] = restored_api_key;
    _active_llm_state["model"] = restored_model;
    llm.api_key = restored_api_key;
    llm.model_name = restored_model;
}

def:pub llm_available() -> bool {
    return bool(active_api_key());
}

def:pub llm_model_name() -> str {
    return display_model_name(active_model());
}

def:pub llm_model_id() -> str {
    return active_model();
}

def:pub llm_unavailable_reason() -> str {
    if llm_available() {
        return "";
    }
    return "No personal or environment OPENAI_API_KEY is configured.";
}
