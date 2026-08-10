"""Creates URL of Dataset.

    Example: https://data.aussda.at/dataset.xhtml?persistentId=doi:10.11587/CCESLK

    Parameters
    ----------
    base_url : str
        Base URL of Dataverse instance
    identifier : str
        Identifier of the dataset. Can be dataset id or persistent
        identifier of the dataset (e. g. doi).
    is_pid : bool
        ``True`` to use persistent identifier. ``False``, if not.

    Returns
    -------
    str
        URL of the dataset

    """
def create_dataset_url(base_url: str, identifier: str, is_pid: bool) -> str {
    assert isinstance(base_url, str);
    assert isinstance(identifier, str);
    assert isinstance(is_pid, bool);
    base_url = base_url.rstrip("/");
    if is_pid {
        url = "{0}/dataset.xhtml?persistentId={1}".format(base_url, identifier);
    } else {
        url = "{0}/dataset.xhtml?id{1}".format(base_url, identifier);
    }
    assert isinstance(url, str);
    return url;
}