"""
Finds queries where duckling predicts multiple entities for the SAME span
"""
def find_duckling_conflict_queries(duckling_outputs: list[dict[str, dict[tuple[int, int], str]]]) -> dict[int, dict[str, dict[tuple[int, int], str]]] {
    conflict_responses = {};
    for (i, response) in enumerate(duckling_outputs) {
        response_spans = [span for rv in response.values() for span in rv.keys()];
        if len(response_spans) != len(set(response_spans)) {
            conflict_responses[i] = response;
        }
    }
    return conflict_responses;
}