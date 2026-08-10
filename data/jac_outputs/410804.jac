"""Pad or trim list to len length.

Args:
  ids: list of ints to pad
  pad_id: what to pad with
  length: length to pad or trim to

Returns:
  ids trimmed or padded with pad_id
"""
def Pad(ids: list[int], pad_id: int, length: int) -> list[int] {
    assert pad_id is not None;
    assert length is not None;
    if len(ids) < length {
        a = [pad_id] * (length - len(ids));
        return ids + a;
    }
    return ids[:length];
}