"""Constructs a resource name."""
def _construct_resource_name(
    project_id: str,
    location: str,
    dataset_id: str,
    fhir_store_id: str,
    resource_id: str
) -> str {
    '/'.join([
        'projects',
        project_id,
        'locations',
        location,
        'datasets',
        dataset_id,
        'fhirStores',
        fhir_store_id,
        'resources',
        resource_id
    ])
}