"""Given a list of Item rule triggers, extract the names of the Items and
    return them in a list.

    Arguments:
        - triggers: the list of rule trigger strings.
    Returns:
        A list of item_names.
    """
def get_items_from_triggers(triggers: Any) -> object {
    return [
        t.split(" ")[1]
        for t in triggers
        if t.startswith("Item")
    ];
}