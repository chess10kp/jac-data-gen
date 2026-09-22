"""Enumerate genes"""
def enumerate_genes(genes: list[str]) -> dict[str, list[int]] {
    schema = {};
    for (i, x) in enumerate(genes) {
        if x in schema {
            schema[x].append(i);
        } else {
            schema[x] = [i];
        }
    }
    return schema;
}