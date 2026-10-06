# lib/impl/sandbox_exec.impl.jac

import from tempfile { mkdtemp }
import from shutil { rmtree }
import subprocess;
import from json { dumps as json_dumps }

impl pip_requirements_file_line(package_name: str, version_spec: str) -> str {
    vs = str(version_spec).strip();
    if vs {
        return vs;
    }
    return package_name;
}

impl run_dependency_install_sandbox(
    ecosystem: str,
    package_name: str,
    version_spec: str,
    workspace_root: str
) -> dict {
    _ = workspace_root;
    tmp = mkdtemp(prefix="gw_sbx_");
    logs = [];
    outbound = False;
    cred_touch = False;
    self_del = False;
    children = [];
    install_ok = False;
    writes_outside = False;
    try {
        if ecosystem == "npm" {
            pkg = {"name": "gw-sandbox", "version": "1.0.0", "dependencies": {package_name: version_spec or "*"}};
            pj = f"{tmp}/package.json";
            f = open(pj, "w");
            f.write(json_dumps(pkg));
            f.close();
            logs.append("npm install starting");
            p = subprocess.run(
                ["npm", "install", "--ignore-scripts", "--no-fund", "--no-audit"],
                cwd=tmp,
                capture_output=True,
                text=True,
                timeout=120
            );
            logs.append(str(p.stdout or ""));
            logs.append(str(p.stderr or ""));
            install_ok = p.returncode == 0;
            if "http" in str(p.stderr).lower() or "http" in str(p.stdout).lower() {
                outbound = True;
            }
        } else {
            req = f"{tmp}/requirements.txt";
            f2 = open(req, "w");
            line = pip_requirements_file_line(package_name, version_spec);
            f2.write(line + "\n");
            f2.close();
            logs.append("pip install starting");
            p2 = subprocess.run(
                ["pip", "install", "-r", "requirements.txt", "--target", f"{tmp}/site"],
                cwd=tmp,
                capture_output=True,
                text=True,
                timeout=120
            );
            logs.append(str(p2.stdout or ""));
            logs.append(str(p2.stderr or ""));
            install_ok = p2.returncode == 0;
            if "http" in str(p2.stderr).lower() {
                outbound = True;
            }
        }
        if ".ssh" in str(logs).lower() or ".aws" in str(logs).lower() or "credential" in str(logs).lower() {
            cred_touch = True;
        }
        if "rm " in str(logs) or "unlink" in str(logs).lower() {
            self_del = True;
        }
        if ecosystem == "npm" {
            children.append("npm");
        } else {
            children.append("pip");
        }
    } except Exception as e {
        logs.append(str(e));
        install_ok = False;
    } finally {
        try {
            rmtree(tmp);
        } except Exception {
            noop = 0;
        }
    }
    return {
        "ecosystem": ecosystem,
        "install_ok": install_ok,
        "outbound_network_observed": outbound,
        "file_writes_outside_workspace": writes_outside,
        "child_processes": children,
        "credential_path_access": cred_touch,
        "self_delete_indicators": self_del,
        "raw_logs": "\n".join(logs)
    };
}

impl run_manifest_body_sandbox(manifest_path: str, manifest_body: str) -> dict {
    mp = str(manifest_path);
    body = str(manifest_body);
    tmp = mkdtemp(prefix="gw_sbx_mf_");
    logs = [];
    outbound = False;
    cred_touch = False;
    self_del = False;
    children = [];
    install_ok = False;
    writes_outside = False;
    try {
        if mp.endswith("package.json") {
            pj = f"{tmp}/package.json";
            f = open(pj, "w");
            f.write(body);
            f.close();
            logs.append("npm install (manifest body) starting");
            p = subprocess.run(
                ["npm", "install", "--ignore-scripts", "--no-fund", "--no-audit"],
                cwd=tmp,
                capture_output=True,
                text=True,
                timeout=120
            );
            logs.append(str(p.stdout or ""));
            logs.append(str(p.stderr or ""));
            install_ok = p.returncode == 0;
            if "http" in str(p.stderr).lower() or "http" in str(p.stdout).lower() {
                outbound = True;
            }
            children.append("npm");
        } elif mp.endswith("requirements.txt") {
            req = f"{tmp}/requirements.txt";
            f2 = open(req, "w");
            f2.write(body);
            if body and not body.endswith("\n") {
                f2.write("\n");
            }
            f2.close();
            logs.append("pip install -r (manifest body) starting");
            p2 = subprocess.run(
                ["pip", "install", "-r", "requirements.txt", "--target", f"{tmp}/site"],
                cwd=tmp,
                capture_output=True,
                text=True,
                timeout=120
            );
            logs.append(str(p2.stdout or ""));
            logs.append(str(p2.stderr or ""));
            install_ok = p2.returncode == 0;
            if "http" in str(p2.stderr).lower() {
                outbound = True;
            }
            children.append("pip");
        } else {
            logs.append("manifest body sandbox skipped for this manifest type");
            install_ok = True;
        }
        if ".ssh" in str(logs).lower() or ".aws" in str(logs).lower() or "credential" in str(logs).lower() {
            cred_touch = True;
        }
        if "rm " in str(logs) or "unlink" in str(logs).lower() {
            self_del = True;
        }
    } except Exception as e {
        logs.append(str(e));
        install_ok = False;
    } finally {
        try {
            rmtree(tmp);
        } except Exception {
            noop = 0;
        }
    }
    eco = "pip";
    if mp.endswith("package.json") {
        eco = "npm";
    }
    return {
        "ecosystem": eco,
        "install_ok": install_ok,
        "outbound_network_observed": outbound,
        "file_writes_outside_workspace": writes_outside,
        "child_processes": children,
        "credential_path_access": cred_touch,
        "self_delete_indicators": self_del,
        "raw_logs": "\n".join(logs)
    };
}
