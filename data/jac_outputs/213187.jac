"""Return decoded API response, printing exceptions when encountered."""
def handle_response(response: Exception | str | dict[str, str]) -> Exception | str | dict[str, str] {
    if isinstance(response, Exception) {
        print(response);
        return response;
    }
    return response;
}