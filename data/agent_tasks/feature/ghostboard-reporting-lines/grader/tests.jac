import from .server { initialize_graph, get_executives, get_system_metrics, get_direct_reports, get_chain_of_command }
import from .models { Executive, reports_to }

test "direct reports of the CEO" {
    initialize_graph();
    assert [e.id for e in get_direct_reports("ceo")] == ["cto", "mkt", "ops"];
}

test "direct reports of mid-level executives" {
    initialize_graph();
    assert [e.id for e in get_direct_reports("ops")] == ["hr"];
    assert [e.id for e in get_direct_reports("cto")] == ["sec"];
    assert len(get_direct_reports("hr")) == 0;
    assert len(get_direct_reports("nobody")) == 0;
}

test "chain of command walks up to the CEO" {
    initialize_graph();
    assert get_chain_of_command("hr") == ["hr", "ops", "ceo"];
    assert get_chain_of_command("sec") == ["sec", "cto", "ceo"];
    assert get_chain_of_command("ceo") == ["ceo"];
    assert len(get_chain_of_command("nobody")) == 0;
}

test "reporting edges are real reports_to edges and not duplicated" {
    initialize_graph();
    initialize_graph();
    hr = [e for e in [root-->[?:Executive]] if e.id == "hr"][0];
    assert len([hr ->:reports_to:->]) == 1;
    ceo = [e for e in [root-->[?:Executive]] if e.id == "ceo"][0];
    assert len([ceo <-:reports_to:<-]) == 3;
    assert len([ceo ->:reports_to:->]) == 0;
}

test "regression: seeding and metrics still work" {
    initialize_graph();
    assert len(get_executives()) == 6;
    assert get_system_metrics().net_latency >= 0;
}
