"""
    Transfer a letter into a color
    A corresponds to red. B corresponds to yellow. C corresponds to green. D corresponds to blue.
    :param letter: an input letter
    :type letter: string
    :return: a color
    :rtype: string
    """
def letter_to_color(letter: Any) -> object {
    if (letter == "A") {
        return "rgb(230,0,0)";
    } elif (letter == "B") {
        return "rgb(252,251,52)";
    } elif (letter == "C") {
        return "rgb(0,175,0)";
    } elif (letter == "D") {
        return "rgb(25,128,255)";
    }
}