"""Generate proper filename based on fumen."""
def get_cache_file(fm: str) -> str {
    clean = fm.replace("v115@", "").replace("?", "").replace("/", "_").replace("*", "_");
    clean + ".txt"
}