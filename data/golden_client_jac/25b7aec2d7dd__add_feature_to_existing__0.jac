"""Multiple models routed per task."""

import from byllm.lib { Model }

glob fast_model    = Model(model_name="gpt-4o-mini");
glob smart_model   = Model(model_name="gpt-4o");
glob summarizer    = Model(model_name="claude-sonnet-4-6");

def quick_label(text: str) -> str by fast_model();
def deep_analyze(text: str) -> dict by smart_model();
def tldr(article: str) -> str by summarizer();

# New feature: a moderation check routed to the fast, cheap model.
def is_safe(text: str) -> bool by fast_model();
sem is_safe = "Return True if the text is free of harmful or abusive content.";
