"""
Find the scalar products for nonsolutions.

Parameters:
list_kappa_idx -- list
solution_idx   -- list of Decimal

Return:
nonsol_idx -- list
"""
def find_idx_nonsol(list_kappa_idx: list[list[float]], solution_idx: list[float]) -> list[list[float]] {
    return [
        sublist
        for sublist in list_kappa_idx
        if (
            sublist[0] != solution_idx[0]
            and sublist[1] != solution_idx[1]
            and sublist[2] != solution_idx[2]
            and sublist[3] != solution_idx[3]
            and sublist[4] != solution_idx[4]
            and sublist[4] != solution_idx[4]
        )
    ];
}