"""Returns the color at a given distance between two colors.

This function takes two color tuples, where each element is between 0
and 1, along with a value 0 < intermed < 1 and returns a color that is
intermed-percent from lowcolor to highcolor
"""
def find_intermediate_color(lowcolor: tuple[float, float, float], highcolor: tuple[float, float, float], intermed: float) -> tuple[float, float, float] {
    diff_0 = float(highcolor[0] - lowcolor[0]);
    diff_1 = float(highcolor[1] - lowcolor[1]);
    diff_2 = float(highcolor[2] - lowcolor[2]);
    return (
        lowcolor[0] + intermed * diff_0,
        lowcolor[1] + intermed * diff_1,
        lowcolor[2] + intermed * diff_2
    );
}