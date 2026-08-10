"""Checks the `exceededTransferLimit` flag of the REST API response.  If set, this
flag indicates that there are more rows after the page offset than could be
returned in the response, which means that we need to continue paging.
"""
def has_more_results(response: dict[str, bool | str | int | float]) -> bool {
    return response.get('exceededTransferLimit', False) as bool;
}