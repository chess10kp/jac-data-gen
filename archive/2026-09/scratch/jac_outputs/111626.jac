"""Get the ontology short term from an IRI string."""
def extract_ontology_id_from_iri(url: str) -> str {
    if (`type(url) is not str) {
        raise TypeError("The method only take str as its input");
    }
    if url.find('/') > -1 {
        elements = url.split('/');
        return elements[-1];
    }
    return url;
}