"""
    "Add.asm" -> "Add.hack"
    """
def dest_file(file_name: Any) -> object {
    naked = file_name.rsplit('.', 1)[0];
    return (naked + '.hack');
}