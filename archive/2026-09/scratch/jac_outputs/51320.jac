"""Update function for the vanilla gradient descent: w = w - learningRate * grad_w."""
def vanilla_grad_desc(para: float, grad_para: float, lr: float) -> float {
    para - lr * grad_para
}