"""Test annex for VR performance settings registry: one state, multiple views."""
import from main { FeaturePanelRenderer, OwnedBy, RegisteredWith, RegistryRenderer, ToggleMutator, VRCentralPanel, VRFeature, VRToggle }

import io;
import from contextlib { redirect_stdout }

# Helper: build the demo graph freshly for each test.
def build_graph {
    panel = VRCentralPanel(title="VR Performance");
    sss = VRFeature(title="SSS", year=236);
    ssgi = VRFeature(title="SSGI", year=237);
    gbuffer = VRFeature(title="GBuffer", year=229);

    sss_sync = VRToggle(
        title="VR Stereo Sync",
        tooltip="Reconcile both eyes",
        enabled=True
    );
    sss_reproj = VRToggle(
        title="VR Stereo Reprojection",
        tooltip="Skip one eye for SSS",
        enabled=True
    );
    ssgi_reproj = VRToggle(
        title="VR Stereo Reprojection",
        tooltip="Skip one eye for SSGI",
        enabled=True
    );
    gbuffer_mode = VRToggle(
        title="Stereo Reprojection",
        tooltip="Global G-buffer reprojection mode",
        enabled=True
    );

    sss +>:OwnedBy:+> sss_sync;
    sss +>:OwnedBy:+> sss_reproj;
    ssgi +>:OwnedBy:+> ssgi_reproj;
    gbuffer +>:OwnedBy:+> gbuffer_mode;

    panel +>:RegisteredWith:+> sss_sync;
    panel +>:RegisteredWith:+> sss_reproj;
    panel +>:RegisteredWith:+> ssgi_reproj;
    panel +>:RegisteredWith:+> gbuffer_mode;

    root ++> panel;
    root ++> sss;
    root ++> ssgi;
    root ++> gbuffer;

    return {
        "panel": panel,
        "sss": sss,
        "ssgi": ssgi,
        "gbuffer": gbuffer,
        "sss_sync": sss_sync,
        "sss_reproj": sss_reproj,
        "ssgi_reproj": ssgi_reproj,
        "gbuffer_mode": gbuffer_mode
    };
}

test "central registry renders all four toggles from the panel" {
    g = build_graph();

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn RegistryRenderer();
    }
    out = buf.getvalue();

    assert "[VR Performance]" in out, f"missing panel header: {out}";
    assert "* VR Stereo Sync = ON" in out, f"missing SSS Sync toggle: {out}";
    assert "* VR Stereo Reprojection = ON" in out, f"missing reprojection toggle(s): {out}";
    assert "* Stereo Reprojection = ON" in out, f"missing G-buffer mode toggle: {out}";
    assert "Reconcile both eyes" in out, f"tooltip not surfaced for Sync toggle: {out}";
    assert "Skip one eye for SSS" in out, f"tooltip not surfaced for SSS reproj: {out}";
    assert "Skip one eye for SSGI" in out, f"tooltip not surfaced for SSGI reproj: {out}";
    assert "Global G-buffer reprojection mode" in out, f"tooltip not surfaced for G-buffer mode: {out}";
    assert res.drawn == 4, f"expected to draw 4 toggles, drew {res.drawn}";
}

test "feature panel renders only its own toggles via OwnedBy edges" {
    g = build_graph();

    buf = io.StringIO();
    with redirect_stdout(buf) {
        sss_res = g["sss"] spawn FeaturePanelRenderer();
        ssgi_res = g["ssgi"] spawn FeaturePanelRenderer();
    }
    out = buf.getvalue();

    assert "SSS Feature Panel" in out, f"missing SSS panel header: {out}";
    assert "SSGI Feature Panel" in out, f"missing SSGI panel header: {out}";
    assert sss_res.drawn == 2, f"SSS owns 2 toggles, drew {sss_res.drawn}";
    assert ssgi_res.drawn == 1, f"SSGI owns 1 toggle, drew {ssgi_res.drawn}";

    # The GBuffer toggle must not appear in feature panels (not OwnedBy SSS/SSGI).
    assert "Global G-buffer reprojection mode" not in out, f"cross-bleed: GBuffer toggle leaked into feature panel: {out}";
}

test "single backing state: feature-panel and central view reflect the same flip" {
    g = build_graph();
    sss_reproj = g["sss_reproj"];
    sss = g["sss"];

    # Mutate via the feature's own toggle node (single backing var).
    buf = io.StringIO();
    with redirect_stdout(buf) {
        sss_reproj spawn ToggleMutator();
    }
    out = buf.getvalue();
    assert "Toggled 'VR Stereo Reprojection'" in out, f"mutator did not report: {out}";

    # After the flip the toggle is OFF.
    assert sss_reproj.enabled == False, f"toggle should be OFF after flip, got {sss_reproj.enabled}";

    # Central registry view of that same node shows OFF (no drift).
    buf2 = io.StringIO();
    with redirect_stdout(buf2) {
        res = root spawn RegistryRenderer();
    }
    out2 = buf2.getvalue();
    # Exactly one reprojection line is now OFF (the SSS one); the SSGI & GBuffer stay ON.
    assert "  * VR Stereo Reprojection = OFF — Skip one eye for SSS" in out2, f"central view did not reflect flip: {out2}";
    assert "  * VR Stereo Reprojection = ON — Skip one eye for SSGI" in out2, f"SSGI state drifted: {out2}";
    assert "  * Stereo Reprojection = ON — Global G-buffer reprojection mode" in out2, f"GBuffer state drifted: {out2}";

    # Same node from the feature panel also shows OFF.
    buf3 = io.StringIO();
    with redirect_stdout(buf3) {
        sss_res = sss spawn FeaturePanelRenderer();
    }
    out3 = buf3.getvalue();
    assert "* VR Stereo Reprojection = OFF" in out3, f"feature panel did not reflect flip: {out3}";
    assert sss_res.drawn == 2, f"SSS should still own 2 toggles, drew {sss_res.drawn}";
}

test "toggles are default-on and not gated by a developer-mode flag" {
    g = build_graph();
    sss_reproj = g["sss_reproj"];
    ssgi_reproj = g["ssgi_reproj"];
    gbuffer_mode = g["gbuffer_mode"];
    sss_sync = g["sss_sync"];

    # Default-on (graduated out of dev-mode gate) — every perf toggle starts ON.
    assert sss_sync.enabled == True, f"SSS Sync must default-on, got {sss_sync.enabled}";
    assert sss_reproj.enabled == True, f"SSS Reproj must default-on, got {sss_reproj.enabled}";
    assert ssgi_reproj.enabled == True, f"SSGI Reproj must default-on, got {ssgi_reproj.enabled}";
    assert gbuffer_mode.enabled == True, f"GBuffer mode must default-on, got {gbuffer_mode.enabled}";

    # Toggles must be discoverable (available) to a normal user — no IsDeveloperMode() gate.
    assert sss_reproj.available == True, f"toggles must be available without IsDeveloperMode() gate, got {sss_reproj.available}";
    assert ssgi_reproj.available == True, f"toggles must be available without IsDeveloperMode() gate, got {ssgi_reproj.available}";

    # All three per-effect reprojection toggles are reachable from the central panel.
    central_toggles = set([]);
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn RegistryRenderer();
    }
    out = buf.getvalue();
    # Resolved via the typed edge, not parsing strings:
    for t in [g["panel"] ->:RegisteredWith:->] {
        central_toggles.add(t);
    }
    assert sss_reproj in central_toggles, "central panel does not list SSS reprojection";
    assert ssgi_reproj in central_toggles, "central panel does not list SSGI reprojection";
    assert gbuffer_mode in central_toggles, "central panel does not list GBuffer mode";
    assert sss_sync in central_toggles, "central panel does not list SSS sync";
    assert len(central_toggles) == 4, f"central panel should list 4 toggles, got {len(central_toggles)}";

    # Each toggle is owned by exactly one feature.
    sss_owned = [g["sss"] ->:OwnedBy:->];
    ssgi_owned = [g["ssgi"] ->:OwnedBy:->];
    gbuffer_owned = [g["gbuffer"] ->:OwnedBy:->];
    assert len(sss_owned) == 2, f"SSS should own 2 toggles, owns {len(sss_owned)}";
    assert len(ssgi_owned) == 1, f"SSGI should own 1 toggle, owns {len(ssgi_owned)}";
    assert len(gbuffer_owned) == 1, f"GBuffer should own 1 toggle, owns {len(gbuffer_owned)}";
}
