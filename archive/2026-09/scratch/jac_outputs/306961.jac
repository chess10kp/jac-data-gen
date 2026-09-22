"""Enables, or disables, the in-game music. Useful if you want to use an MSU-1 soundtrack instead."""
def music(music: bool = True) -> list[dict[str, list[int]]] {
    return [{'1573402': [0 if music else 1]}];
}