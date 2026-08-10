"""Convert a 'ownerlastvisit' sort directive into SQL."""
def _ProcessOwnerLastVisitSD(fmt: Callable[[str], str]) -> tuple[list[tuple[str, list[object]]], list[tuple[str, list[object]]]] {
    left_joins = [
        (
            fmt(
                'User AS {alias} ON (Issue.owner_id = {alias}.user_id OR '
                'Issue.derived_owner_id = {alias}.user_id)'
            ),
            []
        )
    ];
    order_by = [
        (fmt('ISNULL({alias}.last_visit_timestamp) {sort_dir}'), []),
        (fmt('{alias}.last_visit_timestamp {sort_dir}'), [])
    ];
    return (left_joins, order_by);
}