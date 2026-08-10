"""Remove any unwanted characters from the layer name."""
def get_clean_layer_name(name: str) -> str {
    delimit_chars = ":_/";
    for char in delimit_chars {
        name = name.split(char)[0];
    }
    return name;
}