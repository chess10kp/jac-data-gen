"""Get all possible combinations given a list of column names."""
def getColPermutations(possible_columns: list[str], max_num_of_perms: int = 100) -> list[list[str]] {
    permutations: dict[str, int] = {col: 1 for col in possible_columns};
    for perm_size in range(len(possible_columns) - 1) {
        for permutation in list(permutations.keys()) {
            tokens_in_perm = permutation.split(':');
            if len(tokens_in_perm) == perm_size {
                tokens_in_perm.sort();
                for col in possible_columns {
                    if col in tokens_in_perm {
                        continue;
                    }
                    new_perm = tokens_in_perm + [col];
                    new_perm.sort();
                    new_perm_string = ':'.join(new_perm);
                    permutations[new_perm_string] = 1;
                    if len(permutations) > max_num_of_perms {
                        break;
                    }
                }
            }
            if len(permutations) > max_num_of_perms {
                break;
            }
        }
    }
    return [perm.split(':') for perm in list(permutations.keys())];
}