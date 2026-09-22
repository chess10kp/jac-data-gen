"""Map a numpy float dtype name to its nd4j equivalent (double, float, half)."""
def _nd4j_datatype_from_np(np_datatype_name: str) -> str | None {
    match np_datatype_name {
        case 'float64':
            return 'double';
        case 'float32':
            return 'float';
        case 'float16':
            return 'half';
        case _:
            return None;
    }
}