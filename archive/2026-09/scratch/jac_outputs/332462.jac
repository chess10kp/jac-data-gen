"""Copy ``template`` and interpolate a repository ID into its ``_href``."""
def _customize_template(template: dict[str, str], repository_id: str | int) -> dict[str, str] {
    template = template.copy();
    template['_href'] = template['_href'].format(repository_id);
    return template;
}