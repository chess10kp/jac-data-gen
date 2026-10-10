import from .server { get_executives, get_system_metrics, initialize_graph }

test "regression: seeding and metrics still work" {
    initialize_graph();
    initialize_graph();
    assert len(get_executives()) == 6;
    m = get_system_metrics();
    assert m.net_latency >= 0;
}
