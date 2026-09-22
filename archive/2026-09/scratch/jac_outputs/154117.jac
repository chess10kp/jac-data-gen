"""Get Provenance record."""
def get_provenance_record(
    ancestor_files: list[str],
    caption: str,
    statistics: dict[str, str | int | float],
    domains: list[str],
    plot_type: str = 'geo'
) -> dict[str, str | list[str] | dict[str, str | int | float]] {
    return {
        'caption': caption,
        'statistics': statistics,
        'domains': domains,
        'plot_type': plot_type,
        'themes': ['atmDyn', 'monsoon', 'EC'],
        'authors': ['weigel_katja'],
        'references': ['li17natcc'],
        'ancestors': ancestor_files
    };
}