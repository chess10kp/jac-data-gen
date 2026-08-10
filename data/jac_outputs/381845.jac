"""Returns the names of the providers, separated by commas."""
def provider_names(providers: list[object]) -> str {
    return ", ".join([getattr(p, "provider_name") for p in providers]);
}