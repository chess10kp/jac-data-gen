"""Get API request URL for company details."""
def get_details_format(s: str, lang: str = 'zh-cn') -> str {
    return "http://www.solvusoft.com/%s/file-extensions/software/%s/" % (lang, s);
}