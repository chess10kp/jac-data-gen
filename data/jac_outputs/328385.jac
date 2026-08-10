"""
    Get all top level figshare projects.

    Parameters
    ----------
    initial_data: list
        List of all top level projects
    headers: dict
        The authorization header that Figshare expects
    resources: list
        A list of resources to append to

    Returns
    -------
    A list of resources.
    """
def get_figshare_project_data(
    initial_data: Any, headers: Any, resources: Any
) -> object {
    for project in initial_data {
        resources.append(
            {
                "kind": "container",
                "kind_name": "project",
                "container": None,
                "id": project['id'],
                "title": project['title']
            }
        );
    }
    return resources;
}