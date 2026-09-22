"""Returns an alternative short lang code."""
def _get_short_lang_code(lang: str) -> str {
    return lang if "zh" in lang else lang.split("-")[0];
}