"""Given a credential definition identifier and a tag, return the corresponding
    revocation registry identifier, repeating the issuer DID from the
    input identifier."""
def rev_reg_id(cd_id: str, tag: str) -> str {
    return '{}:4:{}:CL_ACCUM:{}'.format(cd_id.split(':', 1)[0], cd_id, tag);
}