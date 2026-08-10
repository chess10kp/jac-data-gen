"""
Return the distinct prime factors from l_nb_p that divide nb.
"""
def unique_decompo_prime_factors(nb: int, l_nb_p: list[int]) -> list[int] {
    decompo = [];
    for elt in l_nb_p {
        if nb % elt == 0 {
            decompo.append(elt);
        }
    }
    return decompo;
}