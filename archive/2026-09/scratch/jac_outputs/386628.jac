"""Convert string to dictionary. Then check if all values are, in fact,
    integers"""
def make_tax_group_dict(taxonomic_groups: str) -> dict[str, int] | None {
    tg = eval(taxonomic_groups);
    if type(tg) == dict {
        ;
    } else {
        raise TypeError(
            "Taxonomic groups can not be coerced into a"
            "dictionary! Check `--taxonomic_groups` input!"
        );
    }
    all_ints = all(type(value) == int for value in tg.values());
    if all_ints {
        return tg;
    }
}