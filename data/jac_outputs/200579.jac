"""Strip the part of the url containing any language code

    """
def strip_langs(url: Any, lang: Any) -> object {
    toks = url.split('/');
    if (lang in toks) {
        toks.remove(lang);
    }
    url = '/'.join(toks);
    return url;
}