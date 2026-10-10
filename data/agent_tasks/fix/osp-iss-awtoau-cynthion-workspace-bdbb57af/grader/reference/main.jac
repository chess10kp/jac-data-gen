"""Models the luna/luna_soc upstream dependency graph and demonstrates
a traversal walker that audits what still depends on what, plus a
cascade-disconnect walker that simulates removing an upstream module
and observes which downstream consumers become orphaned."""

node UpstreamModule {
    has name: str = "";
    has fork_commits_behind: int = 0;
    has defect_driven_replacements: int = 0;
}

node DownstreamConsumer {
    has name: str = "";
    has location: str = "";
}

node SoCBundle {
    has name: str = "";
    has luna_imports: int = 0;
    has luna_soc_imports: int = 0;
}

edge DependsOn {
    has weight: int = 1;
}

edge VendorBypass {
    has reason: str = "";
}

walker DependencyAuditor {
    can start with Root entry {
        print("=== Luna upstream dependency audit ===");
        visit [-->];
    }

    can audit with UpstreamModule entry {
        behind = "FORK-PINNED" if here.fork_commits_behind > 0 else "OK";
        print(
            f"[{behind}] upstream module {here.name}: "
            f"{here.defect_driven_replacements} defect-driven replacements vendored"
        );
        visit [->:DependsOn:->];
    }

    can list_dependents with DownstreamConsumer entry {
        print(f"  -> consumer {here.name} (in {here.location})");
        visit [-->];
    }

    can tally_soc with SoCBundle entry {
        print(
            f"  SoC bundle {here.name}: luna={here.luna_imports}, "
            f"luna_soc={here.luna_soc_imports}"
        );
        visit [-->];
    }
}

walker CascadeDisconnect {
    has disconnected: list[str] = [];
    has orphan_dependents: list[str] = [];

    can start with Root entry {
        print("=== Cascade-disconnect: removing upstream and tallying orphans ===");
        visit [-->];
    }

    can pull with UpstreamModule entry {
        self.disconnected.append(here.name);
        print(f"DISCONNECT upstream: {here.name}");
        visit [-->];
    }

    can record_orphan with DownstreamConsumer entry {
        self.orphan_dependents.append(here.name);
        print(f"  orphan consumer after disconnect: {here.name}");
        visit [-->];
    }

    can tally_soc_cascade with SoCBundle entry {
        print(
            f"  SoC bundle {here.name}: luna={here.luna_imports}, "
            f"luna_soc={here.luna_soc_imports}"
        );
        visit [-->];
    }
}

with entry {
    jtag = UpstreamModule(
        name="luna.gateware.interface.jtag",
        fork_commits_behind=0,
        defect_driven_replacements=0
    );
    car = UpstreamModule(
        name="luna.gateware.architecture.car",
        fork_commits_behind=0,
        defect_driven_replacements=0
    );
    psram = UpstreamModule(
        name="luna.gateware.interface.psram",
        fork_commits_behind=0,
        defect_driven_replacements=1
    );
    spiflash = UpstreamModule(
        name="luna_soc.gateware.core.spiflash.*",
        fork_commits_behind=0,
        defect_driven_replacements=3
    );

    probes = DownstreamConsumer(name="probes/jtag_registers.py", location="probes");
    bist = DownstreamConsumer(name="bist.py", location="probes");
    soc_flash = DownstreamConsumer(name="peripherals/flash.py", location="SoC");
    soc_flash_cdc = DownstreamConsumer(name="flash_cdc.py", location="SoC");
    soc_hyperram = DownstreamConsumer(name="peripherals/hyperram.py", location="SoC");

    soc = SoCBundle(
        name="gateware/soc",
        luna_imports=8,
        luna_soc_imports=8
    );

    root ++> jtag ++> car ++> psram ++> spiflash;
    root ++> probes ++> bist ++> soc_flash ++> soc_flash_cdc ++> soc_hyperram;
    root ++> soc;

    jtag +>:DependsOn(weight=18):+> probes;
    jtag +>:DependsOn(weight=1):+> bist;
    car +>:DependsOn(weight=18):+> probes;
    psram +>:DependsOn(weight=9):+> probes;
    psram +>:DependsOn(weight=1):+> soc_hyperram;
    spiflash +>:DependsOn(weight=4):+> soc_flash;
    spiflash +>:DependsOn(weight=4):+> soc_flash_cdc;

    root spawn DependencyAuditor();

    print("");

    disconnect_walker = CascadeDisconnect();
    root spawn disconnect_walker;
    print(
        f"disconnected {len(disconnect_walker.disconnected)} upstream module(s); "
        f"orphaned {len(disconnect_walker.orphan_dependents)} downstream consumer(s)"
    );
}
