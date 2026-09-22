"""Computes the size of output image after the convolution defined by the input arguments."""
def conv_outsize(in_size: int, kernel_size: int, padding: int, stride: int) -> int {
    out_size = (in_size - kernel_size + 2 * padding) // stride;
    out_size += 1;
    return out_size;
}