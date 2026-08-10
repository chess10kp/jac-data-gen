"""Specify an elasticsearch aggregation from schema facet configuration.
    """
def build_aggregation(
    facet_name: str,
    facet_options: dict[str, str],
    min_doc_count: int = 0
) -> tuple[str, dict[str, dict[str, str | int | list[str]]] | dict[str, dict[str, dict[str, dict[str, dict[str, str]]]]]] {
    exclude: list[str] = [];
    if facet_name == 'type' {
        field = 'embedded.@type.raw';
        exclude = ['Item'];
    } elif facet_name.startswith('audit') {
        field = facet_name;
    } else {
        field = 'embedded.' + facet_name + '.raw';
    }
    agg_name = facet_name.replace('.', '-');
    facet_type = facet_options.get('type', 'terms');
    if facet_type == 'terms' {
        agg: dict[str, dict[str, str | int | list[str]]] = {
            'terms': {'field': field, 'min_doc_count': min_doc_count, 'size': 100}
        };
        if exclude {
            agg['terms']['exclude'] = exclude;
        }
    } elif facet_type == 'exists' {
        agg = {
            'filters': {
                'filters': {
                    'yes': {'exists': {'field': field}},
                    'no': {'missing': {'field': field}}
                }
            }
        };
    } else {
        raise ValueError(
            'Unrecognized facet type {} for {} facet'.format(facet_type, field)
        );
    }
    return (agg_name, agg);
}