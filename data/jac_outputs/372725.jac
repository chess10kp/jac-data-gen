"""Format the path for the storage of a verification object."""
def verification_storage_location(
    l1_block_id: str, level_received_from: int, chain_id: str
) -> str {
    return f"BLOCK/{l1_block_id}-l{level_received_from}-{chain_id}";
}