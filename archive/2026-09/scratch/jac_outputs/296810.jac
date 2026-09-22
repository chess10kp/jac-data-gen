"""Returns the name of the directory containing the appliance log files."""
def applianceLogsDirName(config: dict[str, str]) -> str {
    return config['converter.appliance_logs_dir'];
}