"""
    Function to get dictionary to dereference
    output labels as numbers (from the model)
    to output labels as names.
    Need name of dataset of which to dereference
    """
def dereference_dict(name: str) -> object {
    if (name == "kauto5cls") {
        kauto_dict = {
            0: "woosan-song",
            1: "comsnip-winnow",
            2: "whimbr1-song",
            3: "eugplo-call",
            4: "eugplo-song"
        };
        return kauto_dict;
    }
}