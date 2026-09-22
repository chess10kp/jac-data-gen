"""Prepare response output with a message and optional data payload."""
def _prepare_response_data(message: str, data: object | None = None) -> dict[str, object] {
    output: dict[str, object] = {"message": message};
    if data is not None {
        output["data"] = data;
    }
    return output;
}