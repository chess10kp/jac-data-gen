"""Add filter to the modifiers.

    :param dict modifiers: modifiers
    :param sqlalchemy.sql.expression.BinaryExpression new_filter: filter
    :return dict modifiers: new modifiers
    """
def add_filter(modifiers: Any, new_filter: Any) -> object {
    if (modifiers is None) {
        modifiers = {};
    }
    if ('filter' not in modifiers) {
        modifiers['filter'] = [];
    }
    modifiers['filter'].append(new_filter);
    return modifiers;
}