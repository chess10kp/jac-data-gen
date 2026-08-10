"""Return a dict with extra data retrieved from CERN OAuth."""
def fetch_extra_data(resource: dict[str, str]) -> dict[str, str | None] {
    person_id = resource.get("cern_person_id");
    return dict(person_id=person_id);
}