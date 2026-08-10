"""Count recipes in the sequence before the given pattern appears."""
def find_recipes_2(pattern: str) -> int {
    pattern_len = len(pattern);
    digits = [int(i) for i in pattern];
    last_digits = [];
    recipes = [3, 7];
    elf1 = 0;
    elf2 = 1;
    looking = True;
    while looking {
        new_recipe = recipes[elf1] + recipes[elf2];
        for i in str(new_recipe) {
            if len(last_digits) == pattern_len {
                last_digits.pop(0);
            }
            recipes.append(int(i));
            last_digits.append(int(i));
            if last_digits == digits {
                looking = False;
                break;
            }
        }
        elf1 = (elf1 + recipes[elf1] + 1) % len(recipes);
        elf2 = (elf2 + recipes[elf2] + 1) % len(recipes);
    }
    return len(recipes) - len(digits);
}