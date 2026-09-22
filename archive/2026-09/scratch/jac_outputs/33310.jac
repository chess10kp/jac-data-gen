""" paper : https://arxiv.org/abs/1509.02971
        + effective to use with replay buffer
        - using grads from critic not from actual pollicy ( harder to conv )
    """
def ddpg(loss: float) -> float {
    grads = loss;
    return loss;
}