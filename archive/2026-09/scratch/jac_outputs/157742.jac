"""Negar Acesso as Configuracoes de Video

    DESCRIPTION
        Esta opcao desabilita o icone no do Painel de Controle de Configuracao
    de Video, negando aos usuarios acesso a quaisquer configuracoes de video.

    COMPATIBILITY
        Todos.

    MODIFIED VALUES
        NoDispCPL : dword : 00000000 = Desabilitado; 00000001 = Habilitado.

    """
def no_disp_cpl(on: int = 0) -> str {
    if on {
        return '''[HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\\
CurrentVersion\\Policies\\System]
"NoDispCPL"=dword:00000001''';
    }
    return '''[HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\\
CurrentVersion\\Policies\\System]
"NoDispCPL"=dword:00000000''';
}