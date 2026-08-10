"""
    Reconhecedor do TAD palavra_potencial
    Verifica se o arg e palavra_potencial e devolve valor booleano

    Argumentos:
    arg -- argumento a verificar
    """
def e_palavra_potencial(arg: Any) -> object {
    return (isinstance(arg, str) and all(l.isupper() for l in arg));
}