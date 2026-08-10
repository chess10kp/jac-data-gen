"""Returns the package of API."""
def API_package(API: str) -> str {
    return API.split('->')[0];
}