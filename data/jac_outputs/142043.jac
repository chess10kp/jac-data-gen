obj SubcloudStatusDbModel {
    has subcloud_id: int;
    has sync_status: str;
}

"""Convert subcloud status db model to dictionary."""
def subcloud_status_db_model_to_dict(subcloud_status: SubcloudStatusDbModel | None) -> dict[str, int | str] {
    if subcloud_status {
        result = {
            "subcloud_id": subcloud_status.subcloud_id,
            "sync_status": subcloud_status.sync_status
        };
    } else {
        result = {"subcloud_id": 0, "sync_status": "unknown"};
    }
    return result;
}