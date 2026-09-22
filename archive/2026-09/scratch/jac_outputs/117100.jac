"""
    This converts a WMI type name to the equivalent XSD type, as a string.
    Later, the conversion to a 'real' XSD type is straightforward.
    The point of this conversion is that it does not need rdflib.

    WMI types: https://powershell.one/wmi/datatypes
    RDF types: https://rdflib.readthedocs.io/en/stable/rdf_terms.html
    """
def _convert_wmi_type_to_xsd_type(predicate_type_name: str) -> str | None {
    wmi_type_to_xsd = {
        'string': "survol_string",
        'boolean': 'survol_boolean',
        'datetime': 'survol_dateTime',
        'sint64': 'survol_integer',
        'sint32': 'survol_integer',
        'sint16': 'survol_integer',
        'sint8': 'survol_integer',
        'uint64': 'survol_integer',
        'uint32': 'survol_integer',
        'uint16': 'survol_integer',
        'uint8': 'survol_integer',
        'real64': 'survol_double',
        'real32': 'survol_double'
    };
    try {
        return wmi_type_to_xsd[predicate_type_name.lower()];
    } except KeyError {
        return None;
    }
}