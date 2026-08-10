"""
    make text.

        reference
        - https://developers.worksmobile.com/jp/document/100500801?lang=en

    :return: text content.
    """
def make_text(text: str, i18n_texts: dict | None = None) -> dict {
    if i18n_texts is not None {
        return {"type": "text", "text": text, "i18nTexts": i18n_texts};
    }
    return {"type": "text", "text": text};
}