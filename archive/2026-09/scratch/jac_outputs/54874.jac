"""
    Loading items into the game.

    Parameters:
        data(dict): Nested dictionaries containing
            all information of the game.

    Returns:
        items_name(list): Returns list of item names.
    """
def load_items(data: Any) -> object {
    items_name = list(data['Items'].keys());
    return items_name;
}