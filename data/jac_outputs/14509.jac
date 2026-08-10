"""function to convert user information returned by google auth service in expected format:

    returns this format:
    e.g.:{'name':'John Smith','id': '12345', 'email': 'js@example.com','provider','google',...}
    """
def convertgoogle(ui: Any) -> object {
    myui = {
        'name': ui['name'],
        'given_name': ui['given_name'],
        'family_name': ui['family_name'],
        'provider': ui['iss'],
        'email': ui['email'],
        'id': ui['sub']
    };
    return myui;
}