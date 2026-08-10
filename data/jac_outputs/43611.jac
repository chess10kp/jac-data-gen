"""Return atomic counts for C, H, N, O, P, and S in each formula string."""
def element_counts(formula_list: list[str]) -> list[dict[str, int]] {
    elements = ['C', 'H', 'N', 'O', 'P', 'S'];
    count_list = [];
    for formula in formula_list {
        element_numbers = dict();
        for element in elements {
            element_numbers[element] = 0;
            alpha_idx = formula.find(element);
            if alpha_idx > -1 {
                element_numbers[element] = 1;
                for i in range(alpha_idx + 2, len(formula) + 1) {
                    try {
                        element_numbers[element] = int(formula[alpha_idx + 1:i]);
                    } except ValueError {
                        break;
                    }
                }
            }
        }
        count_list.append(element_numbers);
    }
    return count_list;
}