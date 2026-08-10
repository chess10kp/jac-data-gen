"""
:param geo_list: list of (geo, geo_id) pair (smallest first)
                 e.g. [(block%20group, *), (state, 01), (county, 02), (track, *), ]
:return: url for geo query
"""
def get_geo_url(geo_list: list[tuple[str, str]]) -> str {
    url = "";
    for (i, (level, val)) in enumerate(geo_list) {
        if i == 0 {
            url += "&for=%s:%s" % (level, val);
        } else {
            url += "&in=%s:%s" % (level, val);
        }
    }
    return url;
}