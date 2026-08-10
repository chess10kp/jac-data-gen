"""Pay any excess remaining after making minimum payments."""
def pay_excess(principal: int, minimum: int, remainder: int) -> tuple[int, int, int] {
    excess = remainder;
    if principal - excess <= 0 {
        excess = principal;
        remainder = remainder - principal;
    } else {
        remainder = 0;
    }
    return (principal - excess, minimum + excess, remainder);
}