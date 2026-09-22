"""Convert output of sigmoid function to its derivative."""
def sigmoid_output_to_derivative(output: float) -> float {
    output * (1 - output)
}