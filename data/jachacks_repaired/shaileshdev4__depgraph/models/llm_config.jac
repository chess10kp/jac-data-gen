"""Featherless model routing for DepGraph walkers.

LiteLLM requires the featherless_ai/ provider prefix (see featherless-cookbook/litellm).
Set FEATHERLESS_API_KEY in .env and api_base in jac.toml [plugins.byllm.model].
"""

import from byllm.lib { Model }

glob code_llm = Model(
    model_name="featherless_ai/Qwen/Qwen2.5-Coder-32B-Instruct",
    config={
        "api_base": "https://api.featherless.ai/v1",
        "http_client": True
    }
);

glob routing_llm = Model(
    model_name="featherless_ai/deepseek-ai/DeepSeek-V3-0324",
    config={
        "api_base": "https://api.featherless.ai/v1",
        "http_client": True
    },
    call_params={"temperature": 0, "max_tokens": 48}
);

"""Spawn root selection — reliable JSON on long package lists (not reasoning)."""
glob spawn_llm = Model(
    model_name="featherless_ai/Qwen/Qwen2.5-7B-Instruct",
    config={
        "api_base": "https://api.featherless.ai/v1",
        "http_client": True
    },
    call_params={"temperature": 0, "max_tokens": 256}
);
