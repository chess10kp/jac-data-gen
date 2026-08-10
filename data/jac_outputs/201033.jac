"""Returns processed HTML to fit into the slide template format."""
def postprocess_html(html: str, metadata: dict[str, str]) -> str {
    if metadata.get('build_lists') and metadata['build_lists'] == 'true' {
        html = html.replace('<ul>', '<ul class="build">');
        html = html.replace('<ol>', '<ol class="build">');
    }
    return html;
}