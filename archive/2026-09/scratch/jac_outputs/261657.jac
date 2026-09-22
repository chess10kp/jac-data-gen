"""Returns a group for a URI e.g. science museum, v&a, wikidata. Should operate on the normalised URI produced by `normaliseURI`."""
def assignGroupToURI(uri: str) -> str {
    if "collection.sciencemuseumgroup" in uri {
        return "Science Museum Group Collection";
    } elif "blog.sciencemuseum.org.uk" in uri {
        return "Science Museum Blog";
    } elif "journal.sciencemuseum.ac.uk" in uri {
        return "Science Museum Journal";
    } elif "collections.vam.ac.uk" in uri or "api.vam.ac.uk/v2/objects/search?" in uri {
        return "V&A collection";
    } elif "http://www.wikidata.org/entity/" in uri {
        return "Wikidata";
    } else {
        return "Literal (raw value)";
    }
}