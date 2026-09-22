"""
    Creates an html link to a dataset page in Easy.

    :param sid: a dataset id

    :return: link to the page for that dataset
    """
def link_easy(sid: Any) -> object {
    prefix = 'https://easy.dans.knaw.nl/ui/datasets/id/';
    return '<a target="_blank" href="{}{}">{}</a>'.format(prefix, sid, sid);
}