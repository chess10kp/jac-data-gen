"""Update the draft HEAD reference to an new git commit id (hexsha)."""
def cache_clear_mutation(dataset_id: str) -> dict[str, str | dict[str, str]] {
    return {
        'query': 'mutation ($datasetId: ID!) { cacheClear(datasetId: $datasetId) }',
        'variables': {'datasetId': dataset_id}
    };
}