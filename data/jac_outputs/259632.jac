"""Find number of step combinations for maximum of three steps at a time

:param step Number of steps left
:return     Number of step combinations

"""
def triple_step_combinations(step: int) -> int {
    if step < 0 {
        return 0;
    } elif step == 0 {
        return 1;
    }
    return triple_step_combinations(step - 3) + triple_step_combinations(step - 2) + triple_step_combinations(step - 1);
}