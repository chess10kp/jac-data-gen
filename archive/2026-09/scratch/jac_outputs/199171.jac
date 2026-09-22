"""Build a Django ORM search filter from query params."""
def build_search_filter(search_params: dict[str, str]) -> dict[str, bool | list[str] | str] {
    search_filter: dict[str, bool | list[str] | str] = {'hide': False};
    if 'species' in search_params {
        search_filter['species__in'] = search_params['species'].split(',');
    }
    if 'west' in search_params { search_filter['longitude__gte'] = search_params['west']; }
    if 'east' in search_params { search_filter['longitude__lte'] = search_params['east']; }
    if 'south' in search_params { search_filter['latitude__gte'] = search_params['south']; }
    if 'north' in search_params { search_filter['latitude__lte'] = search_params['north']; }
    if 'start' in search_params { search_filter['recorded_at_iso__gte'] = search_params['start']; }
    if 'end' in search_params { search_filter['recorded_at_iso__lte'] = search_params['end']; }
    return search_filter;
}