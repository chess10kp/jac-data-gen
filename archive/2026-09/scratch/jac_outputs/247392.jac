"""Customizar a Janela de Logon e o Titulo do Dialogo de Seguranca

    DESCRIPTION
        Este ajuste permite adicionar textos no titulo da janela de logon
    padrao e na caixa de dialogo de seguranca do Windows.

    COMPATIBILITY
        Windows NT/2000/XP

    MODIFIED VALUES
        Welcome : string : Texto a ser adicionado.

    """
def welcome_text(title: str = "WRF") -> str {
    return '''[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\\
CurrentVersion\\Winlogon]
"Welcome"="%s"''' % title;
}