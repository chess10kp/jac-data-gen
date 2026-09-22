"""
    Formats a list (['bla',0,'bla']) into an ODS path format ('bla.0.bla')
    """
def l2o(path: list[str | int]) -> str {
    return '.'.join(filter(None, map(str, path)));
}