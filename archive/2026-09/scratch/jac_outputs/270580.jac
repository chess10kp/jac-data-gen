"""Builds a template string for requirement lines in the YAML format."""
def req_yaml_template(
    pip: bool = False, version: bool = True, build: bool = False
) -> str {
    template_str = '{name}';
    if version {
        template_str += '=={version}' if pip else '={version}';
    }
    if build and not pip {
        if not version {
            template_str += '=*';
        }
        template_str += '={build_string}';
    }
    return template_str;
}