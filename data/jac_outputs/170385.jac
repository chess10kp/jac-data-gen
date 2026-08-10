"""Build extend result set."""
def build_suggest_result(prefix: str, wd_search_results: list[dict[str, str]] | None) -> dict[str, list[dict[str, str]]] {
    suggest_result_data = {"result": []};
    if "wikitext" in prefix.lower() or prefix.lower() in "wikitext" {
        result_item = {
            "id": "wikitext",
            "name": "Wikitext",
            "description": "Text associated with the file, in wiki markup"
        };
        suggest_result_data["result"].append(result_item);
    }
    if wd_search_results is not None {
        for result in wd_search_results {
            result_item = {
                "id": result["id"],
                "name": result["label"],
                "description": result["description"]
            };
            suggest_result_data["result"].append(result_item);
        }
    }
    return suggest_result_data;
}