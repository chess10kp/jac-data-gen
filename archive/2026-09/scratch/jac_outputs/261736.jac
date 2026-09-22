"""
    Shows pagination links::

        {% pagination current_page paginator %}

    The argument ``where`` can be used inside the pagination template to
    discern between pagination at the top and at the bottom of an object
    list (if you wish). The default object list template passes
    ``"top"`` or ``"bottom"`` to the pagination template. The default
    pagination template does nothing with this value though.
    """
def pagination(context: Any, page: Any, paginator: Any, where: Any = None) -> object {
    return {'context': context, 'page': page, 'paginator': paginator, 'where': where};
}