"""Return an SQL string to query for popular articles.

    Args:
        limit (int): The maximum number of results to query for.  If
                     ommited, query for all matching results.

    Returns:
        str: An SQL string.  When used in a query, the result will contain
             two columns:
                 - str: The article's name.
                 - str: The number of page visits (e.g. "1337 views").
    """
def popular_articles_query(limit: Any = None) -> object {
    return """
        SELECT title, format('%s views', count(*)) AS views
            FROM log
                JOIN articles ON log.path = ('/article/' || articles.slug)
            GROUP BY articles.title
            ORDER BY count(*) DESC
            LIMIT {number};
    """.format(
        number=(limit or 'ALL')
    );
}