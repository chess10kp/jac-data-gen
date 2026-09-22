"""
    Disabling the button after its being clicked once
    """
def disabling_button(n_clicks: Any) -> object {
    if (n_clicks >= 1) {
        return {'display': "none"};
    }
}