"""Returns mapping function from extensions to corresponding strings."""
def generate_extension_to_string_mapping(extensions: list[str]) -> str {
    function = 'const char* ExtensionToString(Extension extension) {\n';
    function += '  switch (extension) {\n';
    template = '    case Extension::k{extension}:\n' '      return "{extension}";\n';
    function += ''.join(
        [template.format(extension=extension) for extension in extensions]
    );
    function += '  };\n\n  return "";\n}';
    return function;
}