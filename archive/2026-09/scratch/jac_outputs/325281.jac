"""Generate the name of a place, neatly formatted."""
def get_formatted_place(city: str, country: str) -> str {
    return f"{city} {country}".title();
}