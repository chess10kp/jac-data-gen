"""Return a set of langs with no scripts in lang_script_data."""
def _langs_with_no_scripts(lang_script_data: dict[str, tuple[str, str]]) -> set[str] {
    return set([
        k
        for k in lang_script_data
        if not (lang_script_data[k][0] or lang_script_data[k][1])
    ]);
}