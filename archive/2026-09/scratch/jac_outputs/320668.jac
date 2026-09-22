"""
    This function builds the html string for a component.
    :param html_string: html_string of the component
    :param title: Title of the html component
    :return: html_string
    """
def build_html_component_with_html(html_string: Any) -> object {
    html = """

    <div class="row">
        <div class="col-md-12">
            {0}
        </div>
    </div>

    """.format(
        html_string
    );
    return html;
}