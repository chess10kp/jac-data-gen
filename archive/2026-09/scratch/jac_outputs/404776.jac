"""Returns the resource that matches the link"""
def resource_for_link(
    link: Any, includes: Any, resources: Any = None, locale: Any = None
) -> object {
    if (resources is not None) {
        cache_key = "{0}:{1}:{2}".format(
            link['sys']['linkType'], link['sys']['id'], locale
        );
        if (cache_key in resources) {
            return resources[cache_key];
        }
    }
    for i in includes {
        if (
            (i['sys']['id'] == link['sys']['id'])
            and (i['sys']['type'] == link['sys']['linkType'])
        ) {
            return i;
        }
    }
    return None;
}