"""Parse the sql condition to insert in another sql statement."""
def parse_sql_condition(cohort_ids: str | tuple[int, ...] | list[int], where_condition: bool = False) -> str {
    return f"""{"WHERE" if where_condition else "AND"} id IN {cohort_ids}""" if cohort_ids else "";
}