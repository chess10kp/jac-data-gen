"""VR performance settings: a central panel consumes a per-feature registry
of toggle descriptors. One backing bool per setting, rendered in both the
feature's own panel and the central VR panel — single source of truth,
multiple views."""

# ---------- Domain nodes ----------

node Setting {
    has label: str = "";
    has tooltip: str = "";
    has enabled: bool = False;
    has developer_only: bool = False;
    has owner: str = "";
}

node Panel {
    has name: str = "";
}

# ---------- Relationships ----------

edge Owns {
    # Feature -> Setting: the feature owns the canonical bool.
    has since: str = "v1";
}

edge Mounts {
    # Panel -> Setting: the panel renders the setting (one of the views).
}

edge BelongsTo {
    # Setting -> Panel: the setting's contextual home panel.
}

# ---------- Central registry + renderer ----------

node VRRegistry {
    # The single source of truth for "what VR perf toggles exist".
    # The central VR panel renders all settings reachable via Mounts.
    has panel_name: str = "VR Performance";

    can render with Root entry {
        print(f"=== {self.panel_name} (central panel) ===");
        visit [-->];
    }

    can list_settings with Setting entry {
        gate = " [dev-only]" if here.developer_only else "";
        state = "ON" if here.enabled else "OFF";
        print(f"  [{state}]{gate} {here.label} — {here.tooltip} (owned by {here.owner})");
        # Walker has no built-in cycle guard in jac 0.36.1; explicit policy:
        # central panel renders this setting and stops — no further descent.
    }
}

# A contextual panel — e.g. the SSS or SSGI feature panel that hosts its own toggle(s).
walker FeaturePanel {
    has panel_name: str = "";
    has owner_name: str = "";

    can start with Panel entry {
        print(f"--- {here.name} (contextual panel) ---");
        # From the panel, traverse to the settings mounted on it (its own view).
        visit [here ->:Mounts:->];
    }

    can show_toggle with Setting entry {
        gate = " [dev-only]" if here.developer_only else "";
        state = "ON" if here.enabled else "OFF";
        print(f"  [{state}]{gate} {here.label} — {here.tooltip}");
        visit [-->];
    }
}

# ---------- Demo wiring ----------

with entry {
    # Settings (canonical state lives here, one bool per setting).
    sss_sync = Setting(
        label="SSS VR Stereo Sync",
        tooltip="Reconcile both eyes for subsurface scattering",
        enabled=True,
        developer_only=False,
        owner="SSS"
    );
    sss_reproj = Setting(
        label="SSS VR Stereo Reprojection",
        tooltip="Skip one eye for SSS",
        enabled=True,
        developer_only=False,
        owner="SSS"
    );
    ssgi_reproj = Setting(
        label="SSGI VR Stereo Reprojection",
        tooltip="Skip one eye for SSGI",
        enabled=True,
        developer_only=False,
        owner="SSGI"
    );
    debug_disocc = Setting(
        label="Disocclusion debug view",
        tooltip="Developer-only visualizer",
        enabled=False,
        developer_only=True,
        owner="Core"
    );

    # Feature panels (the contextual view: feature panel mounts its own settings).
    sss_panel = Panel(name="SSS Feature Panel");
    ssgi_panel = Panel(name="SSGI Feature Panel");
    debug_panel = Panel(name="Debug Panel");

    # Central VR panel (the discoverability view: mounts everything).
    central = VRRegistry(panel_name="VR Performance");

    # Ownership: feature owns its setting (typed edge).
    sss_panel +>:Owns(since="pre-consolidation"):+> sss_sync;
    sss_panel +>:Owns:+> sss_reproj;
    ssgi_panel +>:Owns:+> ssgi_reproj;
    debug_panel +>:Owns:+> debug_disocc;

    # Mounts: each panel renders its own settings (contextual view).
    sss_panel +>:Mounts:+> sss_sync;
    sss_panel +>:Mounts:+> sss_reproj;
    ssgi_panel +>:Mounts:+> ssgi_reproj;
    debug_panel +>:Mounts:+> debug_disocc;

    # The central VR registry mounts ALL VR-relevant settings (central view).
    central +>:Mounts:+> sss_sync;
    central +>:Mounts:+> sss_reproj;
    central +>:Mounts:+> ssgi_reproj;
    # Debug disocclusion stays dev-only — central panel still lists it
    # but tags it so normal users can ignore / hide it.

    # Setting -> its contextual panel (for cross-reference).
    sss_sync +>:BelongsTo:+> sss_panel;
    sss_reproj +>:BelongsTo:+> sss_panel;
    ssgi_reproj +>:BelongsTo:+> ssgi_panel;
    debug_disocc +>:BelongsTo:+> debug_panel;

    # ---- Demonstrate: central panel renders the registry ----
    root spawn central;

    # ---- Demonstrate: each feature panel renders its own toggles ----
    sss_panel spawn FeaturePanel(panel_name="SSS Feature Panel", owner_name="SSS");
    ssgi_panel spawn FeaturePanel(panel_name="SSGI Feature Panel", owner_name="SSGI");
    debug_panel spawn FeaturePanel(panel_name="Debug Panel", owner_name="Core");

    # ---- Demonstrate: flipping the backing bool in one place updates both views ----
    print("\n--- User toggles SSS Reprojection OFF in the central panel ---");
    sss_reproj.enabled = False;
    central spawn VRRegistry(panel_name="VR Performance");
}