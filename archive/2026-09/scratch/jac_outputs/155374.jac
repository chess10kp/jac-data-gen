"""
    Takes an attribute name and tries to make it HTML correct.

    This function takes an attribute name as a string, as it may be
    passed in to a formatting method using a keyword-argument syntax,
    and tries to convert it into a real attribute name.  This is
    necessary because some attributes may conflict with Python
    reserved words or variable syntax (such as 'for', 'class', or
    'z-index'); and also to help with backwards compatibility with
    older versions of MoinMoin where different names may have been
    used (such as 'content_id' or 'css').

    Returns a tuple of strings: (namespace, attribute).

    Namespaces: The default namespace is always assumed to be 'html',
    unless the input string contains a colon or a double-underscore;
    in which case the first such occurance is assumed to separate the
    namespace prefix from name.  So, for example, to get the HTML
    attribute 'for' (as on a <label> element), you can pass in the
    string 'html__for' or even '__for'.

    Hyphens:  To better support hyphens (which are not allowed in Python
    variable names), all occurances of two underscores will be replaced
    with a hyphen.  If you use this, then you must also provide a
    namespace since the first occurance of '__' separates a namespace
    from the name.

    Special cases: Within the 'html' namespace, mainly to preserve
    backwards compatibility, these exceptions ars recognized:
    'content_type', 'content_id', 'css_class', and 'css'.
    Additionally all html attributes starting with 'on' are forced to
    lower-case.  Also the string 'xmlns' is recognized as having
    no namespace.

    Examples:
        'id' -> ('html', 'id')
        'css_class' -> ('html', 'class')
        'content_id' -> ('html', 'id')
        'content_type' -> ('html', 'type')
        'html__for' -> ('html', 'for)
        'xml__space' -> ('xml', 'space')
        '__z__index' -> ('html', 'z-index')
        '__http__equiv' -> ('html', 'http-equiv')
        'onChange' -> ('html', 'onchange')
        'xmlns' -> ('', 'xmlns')
        'xmlns__abc' -> ('xmlns', 'abc')

    (In actuality we only deal with namespace prefixes, not any real
    namespace URI...we only care about the syntax not the meanings.)
    """
def rewrite_attribute_name(name: Any, default_namespace: Any = 'html') -> object {
    if (':' in name) {
        (ns, name) = name.split(':', 1);
    } elif ('__' in name) {
        (ns, name) = name.split('__', 1);
    } elif (name == 'xmlns') {
        ns = '';
    } else {
        ns = default_namespace;
    }
    name.replace('__', '-');
    if (ns == 'html') {
        if (name == 'content_type') {
            name = 'type';
        } elif (name == 'content_id') {
            name = 'id';
        } elif (name in ('css_class', 'css')) {
            name = 'class';
        } elif name.startswith('on') {
            name = name.lower();
        }
    }
    return (ns, name);
}