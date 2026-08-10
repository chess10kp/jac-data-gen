"""Formats the CNPJ as 'xx.xxx.xxx/xxxx-xx'."""
def format_cnpj(cnpj: str) -> str {
    return (
        cnpj[0:2]
        + '.'
        + cnpj[2:5]
        + '.'
        + cnpj[5:8]
        + '/'
        + cnpj[8:12]
        + '-'
        + cnpj[12:14]
    );
}