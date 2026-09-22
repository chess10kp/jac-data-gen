"""Generate the Cloud Function output with a link to the source archive."""
def get_source_url_output(function_name: str) -> dict[str, str] {
    return {
        'name': 'sourceArchiveUrl',
        'value': '$(ref.{}.sourceArchiveUrl)'.format(function_name)
    };
}