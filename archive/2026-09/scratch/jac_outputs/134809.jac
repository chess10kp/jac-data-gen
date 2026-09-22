""" use memoization, dp """
def canGetExactChange(targetMoney: int, denominations: list[int]) -> bool {
    mem: dict[int, bool] = {};
    def helper(target: int) -> bool {
        if target in mem {
            return mem[target];
        }
        mem[target] = False;
        for d in denominations {
            if d > target {
                continue;
            }
            if target % d == 0 or helper(target - d) {
                mem[target] = True;
                break;
            }
        }
        return mem[target];
    }
    return helper(targetMoney);
}