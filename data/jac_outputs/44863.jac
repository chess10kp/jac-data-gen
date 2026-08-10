""" Function to parse the json response from the references collection
    in Solr. It returns the results as a list with the annotation and details.
    """
def parse_refs_json(data: Any) -> object {
    docs = data['response']['docs'];
    results = [
        [docs[i].get('annotation'), docs[i].get('details')[0]]
        for i in range(len(data['response']['docs']))
    ];
    return results;
}