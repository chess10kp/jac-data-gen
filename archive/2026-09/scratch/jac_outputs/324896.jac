import numpy;

""" Return normalized frame """
def normalize(frame: numpy.ndarray) -> numpy.ndarray {
    frame -= 128.0;
    frame /= 128.0;
    return frame;
}