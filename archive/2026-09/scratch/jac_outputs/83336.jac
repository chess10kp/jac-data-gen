"""Bernoulli probability of observing binary presence / absence given circulating frequency"""
def obs_likelihood(obs: int, freq: float) -> float {
    return (1 - freq) ** (1 - obs) * freq ** obs;
}