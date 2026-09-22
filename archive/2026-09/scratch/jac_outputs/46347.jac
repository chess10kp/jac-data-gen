"""Given a credential definition identifier, return its schema sequence number."""
def cred_def_id2seq_no(cd_id: str) -> int {
    return int(cd_id.split(':')[-2]);
}