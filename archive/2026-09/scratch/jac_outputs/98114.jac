obj HtmlBuilder {
    has format: str;
    has name: str;
}

obj BuilderHolder {
    has builder: HtmlBuilder;
}

"""Return True when builder is supported. Supported builders output in
    html format, but exclude `PickleHTMLBuilder` and `JSONHTMLBuilder`,
    which run into issues when serializing blog objects."""
def builder_support(builder: HtmlBuilder | BuilderHolder) -> bool {
    if hasattr(builder, 'builder') {
        builder = builder.builder;
    }
    not_supported = set(['json', 'pickle']);
    return builder.format == 'html' and builder.name not in not_supported;
}