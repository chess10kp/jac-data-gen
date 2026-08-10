"""Returns the cloud with the hightes priority."""
def filter_priority(clouds: list[dict[str, int | str]]) -> dict[str, int | str] {
    priority = int(clouds[0]['priority']);
    qualified_cloud = clouds[0];
    for cloud in clouds {
        if int(cloud['priority']) < priority {
            priority = int(cloud['priority']);
            qualified_cloud = cloud;
        }
    }
    return qualified_cloud;
}