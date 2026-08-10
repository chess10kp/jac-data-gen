"""Adds an index key for each dict entry in the request array."""
def index_requests(reqs: list[dict[str, object]]) -> list[dict[str, object]] {
    for (idx, req) in enumerate(reqs) {
        req['index'] = idx;
    }
    return reqs;
}