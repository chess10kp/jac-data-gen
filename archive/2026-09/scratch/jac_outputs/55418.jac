"""
    tries to return a CamelCased class name as good as poosible
    capitalize
    split at underscores "_" and capitelize the following letter
    merge
    this_is_Test => ThisIsTest
    test => Test
    testone => Testone
    """
def get_class_name(name: str) -> str {
    "".join([c.capitalize() for c in name.split("_")])
}