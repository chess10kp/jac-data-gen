"""
Mock for remote PRD info.
"""
def remote_prd_mock(url: str, request: dict[str, str]) -> dict[str, int | bytes] {
    thebody = b'{"PRD-63999-999":{"curef":"PRD-63999-999","variant":"Snek","last_ota":"AAZ888","last_full":"AAZ999"}}';
    return {'status_code': 200, 'content': thebody};
}