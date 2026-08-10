"""Retrieve input data storage account settings link."""
def data_storage_account_settings(conf: dict[str, str]) -> str {
    return conf["storage_account_settings"];
}