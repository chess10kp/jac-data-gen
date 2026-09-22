""" Thx Prism for rendering Latex
    """
def _build_code_script(langs: list[str]) -> str {
    lang_prefix = '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism\
/1.9.0/prism.min.js"></script>';
    lang_temp = '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism\
/1.9.0/components/prism-{}.min.js"></script>';
    return '\n'.join([lang_prefix] + [lang_temp.format(lang) for lang in langs]);
}