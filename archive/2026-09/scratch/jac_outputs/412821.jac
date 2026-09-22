"""
Pro process request database.
"""
def pre_process_request_data(request_data: dict[str, str] | None) -> dict[str, str] {
    if request_data is None {
        request_data = dict();
    }
    return request_data;
}