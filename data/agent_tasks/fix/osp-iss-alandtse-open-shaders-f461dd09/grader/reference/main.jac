"""VR performance settings registry: one backing state surfaced in central and feature panel views."""

node VRFeature {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
}

node VRToggle {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
    has tooltip: str = "";
    has enabled: bool = True;
}

node VRCentralPanel {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
}

edge OwnedBy { }

edge RegisteredWith { }

walker RegistryRenderer {
    has drawn: int = 0;

    can start with Root entry {
        print("=== Central VR Panel (registry iteration) ===");
        visit [-->];
    }

    can open_panel with VRCentralPanel entry {
        print(f"[{here.title}]");
        visit [->:RegisteredWith:->] else { disengage; };
    }

    can draw_toggle with VRToggle entry {
        state = "ON" if here.enabled else "OFF";
        print(f"  * {here.title} = {state} — {here.tooltip}");
        self.drawn += 1;
    }
}

walker FeaturePanelRenderer {
    has drawn: int = 0;

    can start with VRFeature entry {
        print(f"=== {here.title} Feature Panel (contextual view) ===");
        visit [->:OwnedBy:->] else { disengage; };
    }

    can draw_toggle with VRToggle entry {
        state = "ON" if here.enabled else "OFF";
        print(f"  * {here.title} = {state}");
        self.drawn += 1;
    }
}

walker ToggleMutator {
    can flip with VRToggle entry {
        prior = here.enabled;
        here.enabled = not prior;
        new_state = "OFF" if prior else "ON";
        print(f">> Toggled '{here.title}' to {new_state} (single backing state)");
        disengage;
    }
}

with entry {
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

    root spawn RegistryRenderer();
    sss spawn FeaturePanelRenderer();
    ssgi spawn FeaturePanelRenderer();

    sss_reproj spawn ToggleMutator();

    print("--- After feature-panel toggle, central registry reflects same state ---");
    root spawn RegistryRenderer();
    sss spawn FeaturePanelRenderer();
}
