"""
    Track the number of times the action field has been rendered on the page,
    so we know which value to use.
    """
def admin_actions(context: dict[str, int | str]) -> dict[str, int | str] {
    context['action_index'] = context.get('action_index', -1) + 1;
    return context;
}