"""Remove string after 'comchr' in 'string'."""
def RemoveCommentInString(string: str, comchr: str) -> str {
    if len(comchr) <= 0 {
        comchr = '#';
    }
    result = string.strip();
    cm = result.find(comchr);
    if cm > 0 {
        result = result[:cm];
        result = result.strip();
    }
    return result;
}