"""Mirror an action, swapping left/right."""
def mirror_action(act: int) -> int {
    direction = act % 18 // 6;
    act -= direction * 6;
    if direction == 1 {
        direction = 2;
    } elif direction == 2 {
        direction = 1;
    }
    act += direction * 6;
    return act;
}