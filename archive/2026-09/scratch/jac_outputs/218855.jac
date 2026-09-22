"""Static location for Returns template."""
def template_directory_path(instance: object, filename: str) -> str {
    return 'wildlifecompliance/returns/template/{0}'.format(filename);
}