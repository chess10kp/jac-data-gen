"""
    Fix up electricity for how much the Grids consume
  """
def electric_source(data: dict[str, object], meta: dict[str, object]) -> tuple[dict[str, object], dict[str, object]] {
    E = -1.0 * (meta['HERON']['activity']['electricity'] as float);
    data = {'driver': E};
    return (data, meta);
}