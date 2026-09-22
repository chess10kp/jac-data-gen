"""Determine whether the request is a POSTed html form"""
def is_form_post(environ: dict[str, str]) -> bool {
    content_type = environ.get('CONTENT_TYPE', '').lower();
    if ';' in content_type {
        content_type = content_type.split(';', 1)[0];
    }
    return content_type in ('application/x-www-form-urlencoded', 'multipart/form-data');
}