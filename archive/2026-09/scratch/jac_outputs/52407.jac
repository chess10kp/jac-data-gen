"""
    Setting up project URL
    :param project: from pytest_addoption
    :return: project URL
    """
def setup_path(project: str, test_data: list[dict[str, str]]) -> str {
    url = project;
    if project in ('market', 'bank', 'intranet') {
        url = test_data[0]['url'];
    }
    return url;
}