"""Creates a Jupyter Config JSON file with one package defined."""
def jupyter_config_json(package_name: str, enabled: bool = True) -> dict[str, dict[str, dict[str, bool]]] {
    return {"NotebookApp": {"nbserver_extensions": {package_name: enabled}}};
}