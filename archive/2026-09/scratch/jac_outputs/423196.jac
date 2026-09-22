"""\
    parser_multiplex_buffer_utilisation_Descriptor(data,i,length,end) -> dict(parsed descriptor elements).

    This descriptor is not parsed at the moment. The dict returned is:
       { "type": "multiplex_buffer_utilisation", "contents" : unparsed_descriptor_contents }

    (Defined in ISO 13818-1 specification)
    """
def parser_multiplex_buffer_utilisation_Descriptor(
    data: Any, i: Any, length: Any, end: Any
) -> object {
    return {"type": "multiplex_buffer_utilisation", "contents": data[(i + 2):end]};
}