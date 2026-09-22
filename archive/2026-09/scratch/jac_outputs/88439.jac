import from logging { Logger }

"""Return sync url from Shotgun File/Link field."""
def _get_project_sync_url(sg_field_value: object | None, logger: Logger) -> str | None {
    sync_url = None;
    if isinstance(sg_field_value, dict) {
        if sg_field_value.get("link_type") == "web" {
            sync_url = sg_field_value.get("url");
            if isinstance(sync_url, str) and sync_url.endswith("/") {
                sync_url = sync_url[:-1];
            }
        }
    }
    if sync_url is None and sg_field_value {
        logger.warning(
            (
                "Sync URL could not be extracted from %s. Expected a dictionary "
                "representing a web link like {'link_type': 'web', 'url': "
                "'https://<servername>/sg2jira/<settingsname>'}"
                % sg_field_value
            )
        );
    }
    return sync_url;
}