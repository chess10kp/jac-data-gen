"""Reorder frame_dict keys by frameid in ascending order."""
def reorder_frameID(frame_dict: dict[str, list[list[int]]]) -> dict[str, list[list[int]]] {
    return {str(key): frame_dict[str(key)] for key in sorted([int(i) for i in frame_dict.keys()])};
}