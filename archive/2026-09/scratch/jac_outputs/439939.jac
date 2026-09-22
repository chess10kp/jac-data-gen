"""
    Compate asset name with GOOS and GOARCH.
    Return True if matched.
    """
def match_asset(asset_name: str, goos: str, goarch: str) -> bool {
    asset_name = asset_name.lower();
    arch_words = {"386": ["386"], "amd64": ["amd64", "x86_64"]}[goarch];
    match_goos = goos in asset_name;
    match_goarch = any(word in asset_name for word in arch_words);
    return match_goos and match_goarch;
}