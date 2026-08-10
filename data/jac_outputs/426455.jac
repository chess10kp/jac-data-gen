"""Compile a list of attribute terms from all variants of a variable product."""
def get_attribute_terms(product: dict[str, list[dict[str, str]]]) -> list[str] {
    attribute_terms: list[str] = [];
    for variation in product["variants"] {
        if variation["option_1_value"] not in attribute_terms {
            attribute_terms.append(variation["option_1_value"]);
        }
    }
    return attribute_terms;
}