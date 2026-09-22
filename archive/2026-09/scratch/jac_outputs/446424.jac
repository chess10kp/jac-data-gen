"""
    Returns a list of vertex names from a given list of face indices
    :param mesh: str
    :param indices: list(int)
    :return: list(str)
    """
def get_vertex_names_from_indices(mesh: Any, indices: Any) -> object {
    found_vertex_names = list();
    for index in indices {
        vertex_name = '{}.vtx[{}]'.format(mesh, index);
        found_vertex_names.append(vertex_name);
    }
    return found_vertex_names;
}