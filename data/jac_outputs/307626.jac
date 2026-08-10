"""Find matrix in document."""
def find_matrix(document: dict[str, list]) -> list {
    if 'matrix' in document {
        return document['matrix'];
    } elif 'matrix(ordered)' in document {
        return document['matrix(ordered)'];
    } elif 'matrix(parallel)' in document {
        return document['matrix(parallel)'];
    } else {
        return [];
    }
}