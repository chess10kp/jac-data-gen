""" Returns query for eventsource (service) / actions performed by user. """
def services_by_user(
    account: str, days_back: int, user_arn: str, user_name: str
) -> tuple[str, str] {
    query_string = f"""SELECT DISTINCT eventsource, eventname FROM behold
        WHERE account = '{account}'
        AND (useridentity.arn = '{user_arn}')
        AND from_iso8601_timestamp(eventtime) > date_add('day', -{days_back}, now())
        ORDER BY eventsource, eventname;""";
    return (
        query_string,
        f"athena_results/services_by_user/{account}/{user_name}",
    );
}