"""Yield successive n-sized chunks from l."""
def chunks(l: list[int], n: int) -> list[list[int]] {
    return [l[i:i + n] for i in range(0, len(l), n)];
}