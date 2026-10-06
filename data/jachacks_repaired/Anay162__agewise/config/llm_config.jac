"""LLM configuration — model selection and inference parameters."""

import from os { environ }

# Primary model for all LLM tasks
glob LLM_MODEL: str = "claude-sonnet-4-20250514";
glob LLM_MAX_TOKENS: int = 4096;
glob LLM_TEMPERATURE: float = 0.1;

# Task-specific model overrides
glob LLM_CONFIG: dict = {
    "document_classify": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 256,
        "temperature": 0.0
    },
    "document_extract": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 2048,
        "temperature": 0.0
    },
    "eob_parse": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 2048,
        "temperature": 0.0
    },
    "appeal_letter": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 4096,
        "temperature": 0.2
    },
    "legal_amendment": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 4096,
        "temperature": 0.1
    },
    "plain_english": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "temperature": 0.3
    },
    "digest": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 2048,
        "temperature": 0.4
    },
    "icd10_validate": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 512,
        "temperature": 0.0
    },
    "scam_detect": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 512,
        "temperature": 0.0
    }
};
"""Return LLM config for a specific task, with defaults as fallback."""
def get_llm_config(task: str) -> dict {
    return LLM_CONFIG.get(task, {
        "model": LLM_MODEL,
        "max_tokens": LLM_MAX_TOKENS,
        "temperature": LLM_TEMPERATURE
    });
}
