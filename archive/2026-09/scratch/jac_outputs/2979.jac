"""Given a list, possibly nested to any level, return it flattened."""
def flatten(lis: list) -> list {
    new_lis = [];
    for item in lis {
        if `type(item) == `type([]) {
            new_lis.extend(flatten(item));
        } else {
            new_lis.append(item);
        }
    }
    return new_lis;
}