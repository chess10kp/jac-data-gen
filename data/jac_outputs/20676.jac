"""Make the name nice looking for plots"""
def clean_name(name: str) -> str {
    if name.startswith('SUBSET') {
        name = 'Subset' + name[-1];
    } else {
        name = name.capitalize();
    }
    return name;
}