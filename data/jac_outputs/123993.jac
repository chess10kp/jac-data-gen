"""Sphere test objective function.
        F(x) = sum_{i=1}^d xi^2
        d=1,2,3,...
        Range: [-100,100]
        Minima: 0"""
def Sphere(individual: list[int]) -> int {
    return sum(x ** 2 for x in individual);
}