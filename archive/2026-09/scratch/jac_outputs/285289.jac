"""Gets the package download url."""
def get_dl_url(
    project: str,
    user: str,
    version: str,
    base: str = 'https://github.com',
    ext: str = 'tar.gz'
) -> str {
    return f'{base}/{user}/{project}/archive/v{version}.{ext}';
}