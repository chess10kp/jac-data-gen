"""Generate matrices benchmarking parameters."""
def matrices_params(n_samples: int) -> list[tuple[str, str, str, int, dict[str, object], tuple[int, int], tuple[int, int]]] {
    manifold = "Matrices";
    manifold_args = [(3, 3), (5, 5)];
    module = "geomstats.geometry.matrices";
    metric = "MatricesMetric";
    metric_args = manifold_args;
    kwargs = {};
    common = (manifold, module, metric, n_samples, kwargs);
    return [(common + (manifold_arg, metric_arg)) for (manifold_arg, metric_arg) in zip(manifold_args, metric_args)];
}