import json;
import from os { environ, getenv }
import from pathlib { Path }
import from shutil { which }
import from subprocess { run }

def _provider_config_dir() -> any {
    return Path(".traceforge");
}

def _provider_config_path() -> any {
    return _provider_config_dir().joinpath("provider_settings.json");
}

def _default_provider_config() -> dict[str, any] {
    return {
        "preferred_provider": "auto",
        "openai": {
            "api_key": "",
            "model": "gpt-5.4",
        },
        "anthropic": {
            "api_key": "",
            "model": "claude-sonnet-4-20250514",
        },
        "codex": {
            "model": "gpt-5.4",
            "cli_path": "",
        },
    };
}

def _normalize_provider_name(name: str) -> str {
    lowered = str(name or "auto").lower();
    return lowered if lowered in {"auto", "openai", "anthropic", "codex"} else "auto";
}

def _load_provider_config() -> dict[str, any] {
    payload = _default_provider_config();
    path = _provider_config_path();
    if not path.exists() {
        return payload;
    }
    try {
        loaded = json.loads(path.read_text(encoding="utf-8"));
    } except Exception {
        return payload;
    }
    if not isinstance(loaded, dict) {
        return payload;
    }

    payload["preferred_provider"] = _normalize_provider_name(str(loaded.get("preferred_provider") or "auto"));
    for provider in ["openai", "anthropic", "codex"] {
        provider_payload = loaded.get(provider);
        if not isinstance(provider_payload, dict) {
            continue;
        }
        for field in payload[provider].keys() {
            if field in provider_payload and provider_payload[field] is not None {
                payload[provider][field] = str(provider_payload[field] or "");
            }
        }
    }
    return payload;
}

def _write_provider_config(payload: dict[str, any]) -> None {
    config_dir = _provider_config_dir();
    config_dir.mkdir(parents=True, exist_ok=True);
    _provider_config_path().write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8");
}

def _masked_secret(secret: str) -> str {
    if not secret {
        return "";
    }
    if len(secret) <= 8 {
        return "*" * len(secret);
    }
    return secret[:4] + "..." + secret[-4:];
}

def configured_provider_key(provider: str) -> str {
    provider_name = _normalize_provider_name(provider);
    if provider_name not in {"openai", "anthropic"} {
        return "";
    }
    config = _load_provider_config();
    saved = str(config[provider_name].get("api_key") or "");
    if saved {
        return saved;
    }
    if provider_name == "openai" {
        return str(getenv("OPENAI_API_KEY") or "");
    }
    return str(getenv("ANTHROPIC_API_KEY") or "");
}

def configured_provider_model(provider: str, requested_model: str = "") -> str {
    if requested_model {
        return str(requested_model);
    }
    provider_name = _normalize_provider_name(provider);
    if provider_name not in {"openai", "anthropic", "codex"} {
        return "";
    }
    config = _load_provider_config();
    saved = str(config[provider_name].get("model") or "");
    if saved {
        return saved;
    }
    if provider_name == "openai" {
        return str(getenv("TRACEFORGE_OPENAI_MODEL") or getenv("OPENAI_MODEL") or "gpt-5.4");
    }
    if provider_name == "anthropic" {
        return str(getenv("TRACEFORGE_ANTHROPIC_MODEL") or getenv("ANTHROPIC_MODEL") or "claude-sonnet-4-20250514");
    }
    return str(getenv("TRACEFORGE_CODEX_MODEL") or getenv("CODEX_MODEL") or "gpt-5.4");
}

def configured_codex_cli_path() -> str {
    config = _load_provider_config();
    saved = str(config["codex"].get("cli_path") or "");
    if saved and Path(saved).exists() {
        return saved;
    }
    discovered = which("codex");
    return str(discovered or "");
}

def _key_source(provider: str) -> str {
    provider_name = _normalize_provider_name(provider);
    config = _load_provider_config();
    saved = str(config.get(provider_name, {}).get("api_key") or "");
    if saved {
        return "saved";
    }
    if provider_name == "openai" and getenv("OPENAI_API_KEY") {
        return "env";
    }
    if provider_name == "anthropic" and getenv("ANTHROPIC_API_KEY") {
        return "env";
    }
    return "none";
}

def _sync_runtime_environment() -> None {
    config = _load_provider_config();
    openai_key = str(config["openai"].get("api_key") or "");
    anthropic_key = str(config["anthropic"].get("api_key") or "");
    openai_model = str(config["openai"].get("model") or "");
    anthropic_model = str(config["anthropic"].get("model") or "");
    codex_model = str(config["codex"].get("model") or "");

    if openai_key {
        environ["OPENAI_API_KEY"] = openai_key;
    }
    if anthropic_key {
        environ["ANTHROPIC_API_KEY"] = anthropic_key;
    }
    if openai_model {
        environ["TRACEFORGE_OPENAI_MODEL"] = openai_model;
    }
    if anthropic_model {
        environ["TRACEFORGE_ANTHROPIC_MODEL"] = anthropic_model;
    }
    if codex_model {
        environ["TRACEFORGE_CODEX_MODEL"] = codex_model;
    }
}

def _codex_status() -> dict[str, any] {
    cli_path = configured_codex_cli_path();
    if not cli_path {
        return {
            "available": False,
            "logged_in": False,
            "cli_path": "",
            "version": "",
            "login_status": "Codex CLI not found on PATH.",
            "model": configured_provider_model("codex"),
        };
    }

    version = "";
    login_status = "";
    logged_in = False;
    try {
        version_run = run([cli_path, "--version"], capture_output=True, text=True, check=False, timeout=15);
        version = str(version_run.stdout or version_run.stderr or "").strip();
    } except Exception as err {
        version = "Version check failed: " + str(err);
    }

    try {
        login_run = run([cli_path, "login", "status"], capture_output=True, text=True, check=False, timeout=15);
        login_status = str(login_run.stdout or login_run.stderr or "").strip();
        lowered = login_status.lower();
        logged_in = int(login_run.returncode) == 0 and "logged in" in lowered and "not logged in" not in lowered;
    } except Exception as err {
        login_status = "Login status failed: " + str(err);
    }

    return {
        "available": True,
        "logged_in": logged_in,
        "cli_path": cli_path,
        "version": version,
        "login_status": login_status or "No login status available.",
        "model": configured_provider_model("codex"),
    };
}

def provider_resolution_summary(provider: str = "auto", model: str = "") -> dict[str, any] {
    preferred = _normalize_provider_name(provider);
    if preferred in {"openai", "anthropic", "codex"} {
        if preferred == "codex" {
            codex = _codex_status();
            return {
                "provider": "codex",
                "model": configured_provider_model("codex", model),
                "available": bool(codex["available"] and codex["logged_in"]),
                "source": "explicit",
            };
        }
        resolved_model = configured_provider_model(preferred, model);
        return {
            "provider": preferred,
            "model": resolved_model,
            "available": bool(configured_provider_key(preferred) and resolved_model),
            "source": "explicit",
        };
    }

    config = _load_provider_config();
    preferred_saved = _normalize_provider_name(str(config.get("preferred_provider") or "auto"));
    candidates: list[str] = [];
    if preferred_saved in {"openai", "anthropic", "codex"} {
        candidates.append(preferred_saved);
    } elif preferred_saved == "auto" {
        candidates.append("codex");
    }
    for candidate in ["codex", "openai", "anthropic"] {
        if candidate not in candidates {
            candidates.append(candidate);
        }
    }

    for candidate in candidates {
        if candidate == "codex" {
            codex = _codex_status();
            if codex["available"] and codex["logged_in"] {
                return {
                    "provider": "codex",
                    "model": configured_provider_model("codex", model),
                    "available": True,
                    "source": "auto",
                };
            }
            continue;
        }
        resolved_model = configured_provider_model(candidate, model);
        if configured_provider_key(candidate) and resolved_model {
            return {
                "provider": candidate,
                "model": resolved_model,
                "available": True,
                "source": "auto",
            };
        }
    }

    return {
        "provider": "",
        "model": "",
        "available": False,
        "source": "auto",
    };
}

def provider_status_summary() -> dict[str, any] {
    _sync_runtime_environment();
    config = _load_provider_config();
    openai_key = configured_provider_key("openai");
    anthropic_key = configured_provider_key("anthropic");
    resolved = provider_resolution_summary();
    codex = _codex_status();
    return {
        "status": "ready",
        "config_path": str(_provider_config_path()),
        "preferred_provider": _normalize_provider_name(str(config.get("preferred_provider") or "auto")),
        "resolved_provider": str(resolved.get("provider") or ""),
        "resolved_model": str(resolved.get("model") or ""),
        "resolved_available": bool(resolved.get("available")),
        "providers": {
            "openai": {
                "label": "OpenAI",
                "available": bool(openai_key and configured_provider_model("openai")),
                "key_present": bool(openai_key),
                "key_source": _key_source("openai"),
                "key_preview": _masked_secret(openai_key),
                "model": configured_provider_model("openai"),
            },
            "anthropic": {
                "label": "Anthropic / Claude",
                "available": bool(anthropic_key and configured_provider_model("anthropic")),
                "key_present": bool(anthropic_key),
                "key_source": _key_source("anthropic"),
                "key_preview": _masked_secret(anthropic_key),
                "model": configured_provider_model("anthropic"),
            },
            "codex": {
                "label": "Codex CLI",
                "available": bool(codex["available"]),
                "logged_in": bool(codex["logged_in"]),
                "cli_path": str(codex["cli_path"]),
                "version": str(codex["version"]),
                "login_status": str(codex["login_status"]),
                "model": str(codex["model"]),
            },
        },
    };
}

def save_provider_config_summary(
    preferred_provider: str = "auto",
    openai_api_key: str = "",
    openai_model: str = "",
    anthropic_api_key: str = "",
    anthropic_model: str = "",
    codex_model: str = "",
    codex_cli_path: str = "",
    clear_openai_key: bool = False,
    clear_anthropic_key: bool = False,
) -> dict[str, any] {
    config = _load_provider_config();
    config["preferred_provider"] = _normalize_provider_name(preferred_provider);

    if clear_openai_key {
        config["openai"]["api_key"] = "";
    } elif openai_api_key {
        config["openai"]["api_key"] = str(openai_api_key);
    }
    if openai_model {
        config["openai"]["model"] = str(openai_model);
    }

    if clear_anthropic_key {
        config["anthropic"]["api_key"] = "";
    } elif anthropic_api_key {
        config["anthropic"]["api_key"] = str(anthropic_api_key);
    }
    if anthropic_model {
        config["anthropic"]["model"] = str(anthropic_model);
    }

    if codex_model {
        config["codex"]["model"] = str(codex_model);
    }
    if codex_cli_path {
        config["codex"]["cli_path"] = str(codex_cli_path);
    }

    _write_provider_config(config);
    _sync_runtime_environment();
    summary = provider_status_summary();
    summary["status"] = "saved";
    summary["message"] = "Provider settings saved locally.";
    return summary;
}
