"""Calculate the total number of direct and indirect orbits in n_orbit_dict."""
def calc_tot_orbits(n_orbit_dict: dict[str, tuple[int, int]]) -> tuple[int, int] {
    n_direct_tot = sum(n_orbits[0] for n_orbits in n_orbit_dict.values());
    n_indirect_tot = sum(n_orbits[1] for n_orbits in n_orbit_dict.values());
    return (n_direct_tot, n_indirect_tot);
}