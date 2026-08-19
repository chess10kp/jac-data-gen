def mat4_mul(mats: dict) -> list {
    a = mats["a"];
    b = mats["b"];
    return [sum([a[row + 4 * k] * b[k + 4 * col] for k in range(4)])
            for col in range(4) for row in range(4)];
}

with entry {
    print(mat4_mul({'a': [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 2.0, 3.0, 4.0, 1.0], 'b': [2.0, 0.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 0.0, 1.0]}));
}
