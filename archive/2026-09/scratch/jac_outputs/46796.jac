"""Try to parse out global parameters from the places it could be"""
def getGlobalParams(config: dict[str, object]) -> object | None {
    global_params = None;
    try {
        global_params = config["GlobalParameters"];
    } except (TypeError, LookupError) {
        ;
    }
    return global_params;
}