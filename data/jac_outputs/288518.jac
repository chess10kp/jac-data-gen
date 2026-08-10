""" Amount of damage from a mosh with N players on stage """
def getMoshDamage(n: Any) -> object {
    if ((n > 6) or (n < 1)) {
        raise Exception("Invalid n={}".format(n));
    }
    return [5, 10, 20, 40, 64, 100][(n - 1)];
}