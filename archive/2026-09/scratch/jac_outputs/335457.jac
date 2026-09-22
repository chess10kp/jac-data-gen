"""This method deduplicates data object results within a query, so that ls displays data objects
one time, instead of once for every replica."""
def _replica_results_dedup(queries: list[dict[str, str | list[dict[str, str]]]]) -> list[dict[str, str | list[dict[str, str]]]] {
    deduplicated_queries: list[dict[str, str | list[dict[str, str]]]] = [];
    for query in queries {
        new_query = query.copy();
        if "results" in query {
            objects_seen: dict[str, int] = {};
            dedup_results: list[dict[str, str]] = [];
            results = query["results"] as list[dict[str, str]];
            for result in results {
                if result["type"] == "dataobject" {
                    full_name = result["full_name"];
                    if full_name not in objects_seen {
                        objects_seen[full_name] = 1;
                        dedup_results.append(result);
                    }
                } else {
                    dedup_results.append(result);
                }
            }
            new_query["results"] = dedup_results;
        }
        deduplicated_queries.append(new_query);
    }
    return deduplicated_queries;
}