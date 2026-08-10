"""Convert language code to google api supported language code

    See https://cloud.google.com/translate/docs/languages
    """
def getIso639LangCode(android_lang_code: str) -> str {
    match android_lang_code {
        case 'zh-rTW':
            return 'zh-TW';
        case 'zh-rCN':
            return 'zh-CN';
        case 'pt-rPT':
            return 'pt';
        case _:
            return android_lang_code;
    }
}