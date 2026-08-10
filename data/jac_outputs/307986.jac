"""
    :param cep: number of the CEP.
    :param re_format: CEP return format (json|xml|PIPED)
    :info: https://viacep.com.br/
    """
def find_cep(cep: Any, re_format: Any) -> object {
    path = f"{cep}/{re_format}";
    return path;
}