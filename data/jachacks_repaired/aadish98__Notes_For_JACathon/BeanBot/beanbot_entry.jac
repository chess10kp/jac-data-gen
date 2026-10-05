# Shared `with entry_path` logic for beanbot_with_ui.jac (alternate entry_path).

def beanbot_try_delegate_jac_start() -> None {
    import os;
    import subprocess;
    import sys;
    if len(sys.argv) >= 2 and sys.argv[1] == "start" and str(sys.argv[0]).endswith(".jac") {
        cwd = os.path.dirname(os.path.abspath(sys.argv[0]));
        rc = subprocess.call(
            ["jac", "start", sys.argv[0]] + sys.argv[2:],
            cwd=cwd,
        );
        sys.exit(rc);
    }
    if (
        len(sys.argv) >= 3
        and str(sys.argv[1]).endswith(".jac")
        and sys.argv[2] == "start"
    ) {
        # e.g. [jac, main.jac, start, --no_client]
        entry_path = sys.argv[1];
        cwd = os.path.dirname(os.path.abspath(entry_path));
        rc = subprocess.call(
            ["jac", "start", entry_path] + sys.argv[3:],
            cwd=cwd,
        );
        sys.exit(rc);
    }
    if (
        len(sys.argv) >= 3
        and sys.argv[1] == "start"
        and str(sys.argv[2]).endswith(".jac")
    ) {
        # e.g. [jac, start, main.jac, --dev]
        entry_path = sys.argv[2];
        cwd = os.path.dirname(os.path.abspath(entry_path));
        rc = subprocess.call(
            ["jac", "start", entry_path] + sys.argv[3:],
            cwd=cwd,
        );
        sys.exit(rc);
    }
}

def beanbot_run_entry() -> None {
    import sys;
    beanbot_try_delegate_jac_start();
    import from db { init_db };
    init_db();
    print(
        "BeanBot ready. Same as main.jac: jac start beanbot_with_ui.jac (README). "
        + "API only: jac start main.jac --no_client. DB smoke: jac run main.jac."
    );
}
