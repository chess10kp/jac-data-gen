"""Build valid run arguments for spk_run.py from a settings dict."""
def run_args_from_settings(settings: dict[str, object]) -> list[str] {
    run_args = [
        settings["script"],
        settings["mode"],
        settings["representation"],
        settings["dataset"],
        settings["dbpath"],
        settings["modeldir"],
        "--split",
        *settings["split"],
        "--property",
        settings["property"],
        "--max_epochs",
        settings["max_epochs"],
        "--checkpoint_interval",
        settings["checkpoint_interval"],
        "--keep_n_checkpoints",
        settings["keep_n_checkpoints"]
    ];
    if settings["derivative"] is not None {
        run_args += ["--derivative", settings["derivative"]];
        if settings["negative_dr"] {
            run_args += ["--negative_dr"];
        }
    }
    if settings["contributions"] is not None {
        run_args += ["--contributions", settings["contributions"]];
    }
    if settings["output_module"] is not None {
        run_args += ["--output_module", settings["output_module"]];
    }
    return [str(arg) for arg in run_args];
}