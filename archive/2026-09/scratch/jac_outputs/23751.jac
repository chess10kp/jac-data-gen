"""Prepare name:URL dicts for a given pair of names and URLs."""
def url_gen_dicter(inlist: list[str], filelist: list[str]) -> dict[str, str] {
    return {title: url for (title, url) in zip(inlist, filelist)};
}