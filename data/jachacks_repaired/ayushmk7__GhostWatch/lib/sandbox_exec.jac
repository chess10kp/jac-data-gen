# lib/sandbox_exec.jac — Local subprocess sandbox instrumentation (no live E2B in tests).

# requirements.txt values from parse_manifest_deps are full PEP 508 lines; npm uses bare semver in package.json.
def pip_requirements_file_line(package_name: str, version_spec: str) -> str;

def run_dependency_install_sandbox(
    ecosystem: str,
    package_name: str,
    version_spec: str,
    workspace_root: str
) -> dict;

def run_manifest_body_sandbox(manifest_path: str, manifest_body: str) -> dict;
