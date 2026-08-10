def nfp_rectangle(A: list[dict[str, int]], B: list[dict[str, int]]) -> list[list[dict[str, int]]] | None {
    min_ax = A[0]['x'];
    min_ay = A[0]['y'];
    max_ax = A[0]['x'];
    max_ay = A[0]['y'];
    for point in A[1:] {
        if point['x'] < min_ax { min_ax = point['x']; }
        if point['x'] > max_ax { max_ax = point['x']; }
        if point['y'] < min_ay { min_ay = point['y']; }
        if point['y'] > max_ay { max_ay = point['y']; }
    }
    min_bx = B[0]['x'];
    min_by = B[0]['y'];
    max_bx = B[0]['x'];
    max_by = B[0]['y'];
    for point in B[1:] {
        if point['x'] < min_bx { min_bx = point['x']; }
        if point['x'] > max_bx { max_bx = point['x']; }
        if point['y'] < min_by { min_by = point['y']; }
        if point['y'] > max_by { max_by = point['y']; }
    }
    if max_bx - min_bx > max_ax - min_ax { return None; }
    if max_by - min_by > max_ay - min_ay { return None; }
    b0x = B[0]['x'];
    b0y = B[0]['y'];
    return [[
        {'x': min_ax - min_bx + b0x, 'y': min_ay - min_by + b0y},
        {'x': max_ax - max_bx + b0x, 'y': min_ay - min_by + b0y},
        {'x': max_ax - max_bx + b0x, 'y': max_ay - max_by + b0y},
        {'x': min_ax - min_bx + b0x, 'y': max_ay - max_by + b0y}
    ]];
}