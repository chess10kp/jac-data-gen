"""Returns wether the given dataset is spotlight specific (FALSE) or non-spotlight specific (TRUE)."""
def _is_global_dataset(dataset: dict[str, dict[str, list[dict[str, str]]]]) -> bool {
    return not any([
        i in dataset["source"]["tiles"][0]
        for i in ["{spotlightId}", "greatlakes", "togo"]
    ]);
}