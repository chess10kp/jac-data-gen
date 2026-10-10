import from main { CascadeDisconnect, DependencyAuditor, DependsOn, DownstreamConsumer, SoCBundle, UpstreamModule }
import io;
import from contextlib { redirect_stdout }

test "auditor marks zero-behind upstream OK not fork-pinned" {
    car = UpstreamModule(
        name="luna.gateware.architecture.car",
        fork_commits_behind=0,
        defect_driven_replacements=0
    );
    root ++> car;
    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn DependencyAuditor();
    }
    out = buf.getvalue();
    assert "[OK]" in out, f"expected OK marker in audit output: {out}";
    assert "FORK-PINNED" not in out, f"zero-behind module must not be fork-pinned: {out}";
}

test "auditor reports defect-driven replacement counts" {
    spiflash = UpstreamModule(
        name="luna_soc.gateware.core.spiflash.*",
        fork_commits_behind=0,
        defect_driven_replacements=3
    );
    root ++> spiflash;
    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn DependencyAuditor();
    }
    out = buf.getvalue();
    assert "3 defect-driven replacements vendored" in out, f"missing replacement tally: {out}";
    assert "luna_soc.gateware.core.spiflash.*" in out, f"missing spiflash module name: {out}";
}

test "auditor follows DependsOn edges to downstream consumers" {
    spiflash = UpstreamModule(
        name="luna_soc.gateware.core.spiflash.*",
        fork_commits_behind=0,
        defect_driven_replacements=0
    );
    flash = DownstreamConsumer(name="peripherals/flash.py", location="SoC");
    root ++> spiflash;
    root ++> flash;
    spiflash +>:DependsOn(weight=4):+> flash;
    deps = [spiflash ->:DependsOn:->];
    assert flash in deps, f"DependsOn edge missing, got {deps}";
    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn DependencyAuditor();
    }
    out = buf.getvalue();
    assert "consumer peripherals/flash.py" in out, f"DependsOn consumer not listed: {out}";
    assert "(in SoC)" in out, f"consumer location not listed: {out}";
}

test "cascade disconnect records upstream chain and orphan consumers" {
    jtag = UpstreamModule(name="jtag", fork_commits_behind=0, defect_driven_replacements=0);
    car = UpstreamModule(name="car", fork_commits_behind=0, defect_driven_replacements=0);
    probes = DownstreamConsumer(name="probes/jtag_registers.py", location="probes");
    bist = DownstreamConsumer(name="bist.py", location="probes");
    root ++> jtag ++> car;
    root ++> probes ++> bist;
    direct = len([root-->]);
    assert direct == 2, f"root should fan out to 2 chains, got {direct} direct children";
    disconnect_walker = CascadeDisconnect();
    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn disconnect_walker;
    }
    disc = disconnect_walker.disconnected;
    orphans = disconnect_walker.orphan_dependents;
    assert len(disc) == 2, f"expected 2 upstream disconnects, got {disc}";
    assert len(orphans) == 2, f"expected 2 orphan consumers, got {orphans}";
    assert "jtag" in disc, f"jtag not disconnected: {disc}";
    assert "car" in disc, f"car not disconnected: {disc}";
    assert "probes/jtag_registers.py" in orphans, f"probes not orphaned: {orphans}";
    assert "bist.py" in orphans, f"bist not orphaned: {orphans}";
}

test "walkers tally soc bundle import counts" {
    soc = SoCBundle(name="gateware/soc", luna_imports=8, luna_soc_imports=8);
    root ++> soc;
    audit_buf = io.StringIO();
    with redirect_stdout(audit_buf) {
        root spawn DependencyAuditor();
    }
    audit_out = audit_buf.getvalue();
    assert "luna=8" in audit_out, f"DependencyAuditor missing luna count: {audit_out}";
    assert "luna_soc=8" in audit_out, f"DependencyAuditor missing luna_soc count: {audit_out}";
    cascade_walker = CascadeDisconnect();
    cascade_buf = io.StringIO();
    with redirect_stdout(cascade_buf) {
        root spawn cascade_walker;
    }
    cascade_out = cascade_buf.getvalue();
    assert "luna=8" in cascade_out, f"CascadeDisconnect missing luna count: {cascade_out}";
    assert "luna_soc=8" in cascade_out, f"CascadeDisconnect missing luna_soc count: {cascade_out}";
}
