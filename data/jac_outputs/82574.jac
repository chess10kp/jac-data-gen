"""This function read a dictionary with attributes and returns a string displaying the attributes it gives.
A template: {armor} {health} {mana} {strength} {agility}
If any are missing, we don't add them"""
def display_attributes(attributes: dict[str, str | int]) -> str {
    attributes_to_print = [
        f'{attr.replace("bonus_", "")}: {val}'
        for (attr, val) in attributes.items()
        if val
    ];
    return ", ".join(attributes_to_print);
}