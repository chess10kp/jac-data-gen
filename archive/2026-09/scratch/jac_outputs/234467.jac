"""Keeps "best" item of each f-defined equivalence class."""
def fancier_uniquer(seq: list[object], f: Callable[[object], object], p: Callable[[list[tuple[int, object]]], tuple[int, object]]) -> list[object] {
    bunches: dict[object, list[tuple[int, object]]] = {};
    for (index, item) in enumerate(seq) {
        marker = f(item);
        bunches.setdefault(marker, []).append((index, item));
    }
    auxlist = [p(candidates) for candidates in bunches.values()];
    auxlist.sort();
    return [item for (_, item) in auxlist];
}