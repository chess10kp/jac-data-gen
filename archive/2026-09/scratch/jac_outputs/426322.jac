"""This takes a pH value as input and returns a color to be used in the form of a string."""
def ph_color_code(value: float) -> str {
    match value {
        case v if v > 12.6:
            return 'navy';
        case v if v > 11.2:
            return 'blue';
        case v if v > 9.8:
            return 'dodgerblue';
        case v if v > 8.4:
            return 'aqua';
        case v if v > 7.0:
            return 'darkgreen';
        case v if v > 5.6:
            return 'lawngreen';
        case v if v > 4.2:
            return 'yellow';
        case v if v > 2.8:
            return 'orange';
        case v if v > 1.4:
            return 'indianred';
        case _:
            return 'red';
    }
}