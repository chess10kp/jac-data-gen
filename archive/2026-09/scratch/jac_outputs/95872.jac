"""Retrieves the shard number from a shard filename."""
def get_shard_number(file_name: str) -> int {
    return int(file_name[5:]);
}