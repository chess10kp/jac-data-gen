"""Converts a build target's name into the name of its associated crate.

    Crate names cannot contain certain characters, such as -, which are allowed
    in build target names. All illegal characters will be converted to
    underscores.

    This is a similar conversion as that which cargo does, taking a
    `Cargo.toml`'s `package.name` and canonicalizing it

    Note that targets can specify the `crate_name` attribute to customize their
    crate name; in situations where this is important, use the
    compute_crate_name() function instead.

    Args:
        name (str): The name of the target.

    Returns:
        str: The name of the crate for this target.
    """
def name_to_crate_name(name: str) -> str {
    for illegal in ("-", "/") {
        name = name.replace(illegal, "_");
    }
    return name;
}