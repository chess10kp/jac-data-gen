"""
Returns namespace part from types like 'video.movie'

:param opengraph_type: opengraph type
:return: namespace
"""
def get_namespace_from_type(opengraph_type: str) -> str {
    return opengraph_type.split('.')[0];
}