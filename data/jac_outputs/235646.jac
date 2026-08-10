"""Figure out what layers should have reductions."""
def calc_reduction_layers(num_cells: int, num_reduction_layers: int) -> list[int] {
    reduction_layers: list[int] = [];
    for pool_num in range(1, num_reduction_layers + 1) {
        layer_num = int(float(pool_num) / (num_reduction_layers + 1) * num_cells);
        reduction_layers.append(layer_num);
    }
    return reduction_layers;
}