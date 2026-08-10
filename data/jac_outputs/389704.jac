"""Return the sum of given vec3 values."""
def add_vec3_vec3(va: list[int], vb: list[int]) -> list[int] {
    assert type(va) == list;
    assert type(vb) == list;
    return [va[row] + vb[row] for row in range(3)];
}