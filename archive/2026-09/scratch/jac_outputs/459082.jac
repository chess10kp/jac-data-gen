"""Returns PIP package name for the package id."""
def get_pip_package_name(provider_package_id: str) -> str {
    return "apache-airflow-providers-" + provider_package_id.replace(".", "-");
}