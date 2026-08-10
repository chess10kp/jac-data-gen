"""Update streak based on bet outcome.

If streak is positive and bet hits it will increment streak.
If streak is negative and bet hits it will assign it 1.
If streak is positive and bet misses it will assign it -1.
If streak is negative and bet misses it will decrement streak."""
def calculate_streak(streak: int, operation: int) -> int {
    operation if streak * operation < 0 else streak + operation
}