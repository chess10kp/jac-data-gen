"""check if for_["value"] == 2"""
def is_value_2(for_: dict[str, int]) -> bool {
    v = for_.get("value", None);
    return v == 2;
}