import from hashlib { md5 }

"""Removes duplicates from a given data structure."""
def dedupe(duped_data: list[str | int | float | bool], encoding: str = 'utf-8') -> list[str | int | float | bool] {
    codes = set();
    deduped_data = [];
    for item in duped_data {
        hash_digest = md5(str(item).encode(encoding)).hexdigest();
        if hash_digest not in codes {
            codes.add(hash_digest);
            deduped_data.append(item);
        }
    }
    return deduped_data;
}