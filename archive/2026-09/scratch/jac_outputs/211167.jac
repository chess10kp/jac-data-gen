""" map the language codes to the right ISO 639 3 letter codes.
    """
def mapToRightLanguageCode(
    languageField: str, languageIsoCodesDictionary: dict[str, str]
) -> str {
    if languageField in languageIsoCodesDictionary {
        langIso = languageIsoCodesDictionary[languageField];
    } else {
        langIso = languageField;
        langIso = langIso.rstrip();
    }
    return langIso;
}