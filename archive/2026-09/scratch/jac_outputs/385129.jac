"""Build a Slack notification about a new database connection."""
def new_database_connection_message(payload: dict[str, dict[str, str]]) -> list[dict[str, str | list[dict[str, str]]]] {
    connection_url = payload['connection']['url'];
    connection_name = payload['connection']['name'];
    connection_vendor = payload['connection']['vendor'];
    connection_provider = payload['connection']['provider'];
    message = 'The <{}|{}> data source was just connected.';
    message = message.format(connection_url, connection_name);
    attachments = [
        {
            'fallback': message,
            'color': 'good',
            'author_name': 'Mode',
            'author_link': 'https://modeanalytics.com/',
            'title': 'New Data Source :plus1:',
            'text': message,
            'fields': [
                {'title': 'Vendor', 'value': connection_vendor},
                {'title': 'Provider', 'value': connection_provider}
            ]
        }
    ];
    return attachments;
}