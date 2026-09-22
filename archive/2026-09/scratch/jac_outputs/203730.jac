""" Method to build the response if the API user
        chose to return only the first credential
    """
def _build_response_credential_filter_one_credential(
    credential_items: Any, status_code: Any
) -> object {
    return {
        "status": status_code,
        "data": {"id": credential_items[0]["id"], "name": credential_items[0]["name"]}
    };
}