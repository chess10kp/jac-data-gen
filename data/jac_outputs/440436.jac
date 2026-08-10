"""Returns a float with the project length in nanoseconds (ns)."""
def project_length_in_ns(projnum: int) -> float {
    w = {};
    w[14346] = 1.0;
    w[14348] = 10.0;
    w[14337] = 1.0;
    w[14339] = 10.0;
    for i in range(14600, 14613) {
        w[i] = 1.0;
    }
    for i in range(14349, 14362) {
        w[i] = 10.0;
    }
    w[14363] = 1.0;
    w[14364] = 10.0;
    for i in range(14365, 14369) {
        w[i] = 1.0;
    }
    for i in range(14369, 14373) {
        w[i] = 10.0;
    }
    w[14373] = 1.0;
    w[14374] = 10.0;
    w[14375] = 1.0;
    w[14376] = 10.0;
    w[14377] = 1.0;
    w[14378] = 10.0;
    w[14379] = 1.0;
    w[14380] = 10.0;
    w[14381] = 1.0;
    w[14382] = 1.0;
    w[14383] = 1.0;
    w[14384] = 10.0;
    w[14385] = 10.0;
    w[14386] = 10.0;
    for i in range(14613, 14628) {
        w[i] = 1.0;
    }
    for i in range(14630, 14644) {
        w[i] = 10.0;
    }
    w[14398] = 1.0;
    w[14399] = 1.0;
    for i in range(14700, 14900) {
        w[i] = 1.0;
    }
    return w[projnum];
}