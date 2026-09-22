"""Checks if two given sites are an anion and a cation."""
def is_anion_cation_bond(valences: list[int] | str, ii: int, jj: int) -> bool {
    if valences == "undefined" {
        return True;
    }
    v = valences as list[int];
    if v[ii] == 0 or v[jj] == 0 {
        return True;
    }
    return v[ii] > 0 > v[jj] or v[jj] > 0 > v[ii];
}