"""We are given a 2 x N board. This problem is mostly about figuring out
    the possible cases for laying out the shapes. Here are the possible cases:

    * Place a domino vertically
    * Place two dominos horizontal on top of each other
    * two trominos interlocking

    We can solve this problem by handling state transitions as we iterate from
    0 to `n`. We just record the state of the last column, noting which bits
    were filled.

    The last column can have several states, which can lead to the following
    situations:

    * no rows filled (0, 0b11)
        * nothing
        * both rows filled + vertical domino
    * top row filled (1, 0b01)
        * 0 rows filled and a tromino
        * bottom row filled and a horizontal domino
    * bottom row filled (2, 0b10)
        * 0 rows filled and a tromino
        * top row filled and a horizontal domino
    * both rows filled (3, 0b11)
        * two trominos
        * 0 rows filled and two dominos
    """
def num_configs(n: int) -> int {
    if n <= 0 {
        return 0;
    }
    last_state = [1, 0, 0, 0];
    for _ in range(n) {
        next_state = [0, 0, 0, 0];
        next_state[0] = last_state[0] + last_state[3];
        next_state[1] = last_state[0] + last_state[2];
        next_state[2] = last_state[0] + last_state[1];
        next_state[3] = last_state[0] + last_state[1] + last_state[2];
        last_state = next_state;
    }
    return last_state[0];
}