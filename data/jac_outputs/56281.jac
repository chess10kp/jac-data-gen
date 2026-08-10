"""Return the integer colour code for an ARC colour name."""
def get_colour_code(colour: str) -> int {
    colour_mapping = {
        'black': 0,
        'blue': 1,
        'red': 2,
        'green': 3,
        'yellow': 4,
        'grey': 5,
        'pink': 6,
        'orange': 7,
        'babyblue': 8,
        'maroon': 9
    };
    return colour_mapping[colour];
}