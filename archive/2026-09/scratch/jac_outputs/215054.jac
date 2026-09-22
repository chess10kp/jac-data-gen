"""In JIRA ticket body, "{" and "[" are special symbols that need to be escaped."""
def escape_jira_strings(v: str | list[object] | int | float | bool) -> str | list[object] {
    if `type(v) is str {
        s = v as str;
        return s.replace(r"{", r"\{").replace(r"[", r"\[");
    }
    if `type(v) is list {
        l = v as list[object];
        return [escape_jira_strings(x as str | list[object] | int | float | bool) for x in l];
    }
    return escape_jira_strings(str(v));
}