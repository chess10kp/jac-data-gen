"""Determine the L_out of a 1d-CNN model given parameters for the 1D CNN"""
def l_out(l_in: int, padding: int, dilation: int, kernel: int, stride: int) -> int {
    return (l_in + 2 * padding - dilation * (kernel - 1) - 1) // stride + 1;
}