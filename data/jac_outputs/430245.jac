"""Example handler to filter entities in a handler chain."""
def filter_entity(
    org_name: str,
    app_name: str,
    collection_name: str,
    entity_data: dict[str, str | int | float | bool | None],
    source_client: UsergridClient,
    target_client: UsergridClient,
    attempts: int = 0
) -> dict[str, str | int | float | bool | None] | None {
    if 'blah' in entity_data {
        return None;
    }
    return entity_data;
}