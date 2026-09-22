"""
    modules is dict of otus, metadata is a dictionary of dictionaries where outer dict keys
    are features, inner dict keys are metadata names and values are metadata values
    """
def add_modules_to_metadata(modules: dict[str, list], metadata: dict[str, dict[str, str]]) -> dict[str, dict[str, str]] {
    for (module_, otus) in modules.items() {
        for otu in otus {
            if str(otu) in metadata {
                metadata[str(otu)]['module'] = module_;
            } else {
                metadata[str(otu)] = dict();
                metadata[str(otu)]['module'] = module_;
            }
        }
    }
    return metadata;
}