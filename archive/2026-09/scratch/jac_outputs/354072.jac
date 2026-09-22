"""Pop pop_targets from dict dicty and replace nan values with False."""
def dict_popper(dicty: list[dict[str, str | bool]], pop_target: list[str]) -> list[dict[str, str | bool]] {
    for item in dicty {
        for col in pop_target {
            item.pop(col, None);
        }
        for (k, v) in item.items() {
            if v == "nan" {
                item[k] = False;
            }
        }
    }
    return dicty;
}