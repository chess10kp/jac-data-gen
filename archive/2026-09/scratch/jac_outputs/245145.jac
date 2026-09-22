"""Filter providers by list of states to reduce the quantity of data we're processing."""
def filter_by_states(providers: Any, states: Any) -> object {
    return [
        provider
        for provider in providers
        if (provider['state'] in states)
    ];
}