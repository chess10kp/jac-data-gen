"""Retrieves the uuid of a uuid appended id

    Parameters
    ----------
    uuid_appended_id : str
        A uuid appended id of the form uuid|base_id.

    Returns
    -------
    str
        The uuid portion of the appended id.
    """
def retrieve_uuid(uuid_appended_id: Any) -> object {
    if (uuid_appended_id.find('|') < 0) {
        return None;
    }
    id_split = uuid_appended_id.split('|');
    if (len(id_split) != 2) {
        raise ValueError(
            'A uuid appended protocol id should be of the form uuid|base_id'
        );
    }
    return_uuid = id_split[0];
    return return_uuid;
}