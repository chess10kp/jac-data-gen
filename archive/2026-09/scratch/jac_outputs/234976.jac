"""Function for looping until correct coordinate is found."""
def get_coordinates(
    threshold: int,
    value: int,
    step: int,
    direction: int,
    current_x: int,
    current_y: int
) -> tuple[int, int] | None {
    while value <= threshold {
        for _ in range(2) {
            for _ in range(step) {
                value += 1;
                if direction == 0 {
                    current_x += 1;
                } elif direction == 1 {
                    current_y += 1;
                } elif direction == 2 {
                    current_x -= 1;
                } elif direction == 3 {
                    current_y -= 1;
                }
                if value == threshold {
                    return (current_x, current_y);
                }
            }
            direction = (direction + 1) % 4;
        }
        step += 1;
    }
}