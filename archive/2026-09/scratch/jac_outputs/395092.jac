"""Calculates the area under graph."""
def calculate_area(chart: list[list[str]], n_var: int, m_var: int) -> str {
    area = 0.0;
    seen_graph = [False] * m_var;
    for row in range(n_var) {
        for col in range(m_var) {
            point = chart[row][col];
            if point in '_/\\' {
                seen_graph[col] = True;
            }
            if seen_graph[col] {
                if point != '_' {
                    area += 0.5 if point in '/\\' else 1.0;
                }
            }
        }
    }
    return f"{area:.3f}";
}