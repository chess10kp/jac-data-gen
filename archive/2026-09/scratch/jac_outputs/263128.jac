"""Esconder as Configuracoes Painel de Controle, Impressoras e Conexoes de Rede."""
def no_set_folders(on: int = 0) -> str {
    if on {
        return '''[HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\\
CurrentVersion\\Policies\\Explorer]
"NoSetFolders"=dword:00000001''';
    } else {
        return '''[HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\\
CurrentVersion\\Policies\\Explorer]
"NoSetFolders"=dword:00000000''';
    }
}