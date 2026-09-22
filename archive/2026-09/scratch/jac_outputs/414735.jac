"""
    :param name: The "name" of this Block
    :param text: The "text" of this Block
    """
def Block_f(name: str, text: str) -> str {
    return '\\begin{block}{' + name + '}\n' + text + '\n\\end{block}\n';
}