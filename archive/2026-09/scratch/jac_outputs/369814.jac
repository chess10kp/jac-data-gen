"""
    Pull out the country name from a country id.
    If there's no "name" property in the object, returns null
    """
def pullCountryName(countryObj: Any) -> object {
    try {
        return countryObj['name'];
    } except Exception as e {
        ;
    }
}