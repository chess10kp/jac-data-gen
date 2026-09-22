"""Generate info about the config."""
def _config_info(mode: Any, config: Any) -> object {
    return {"mode": mode, "views": len(config.get("views", []))};
}