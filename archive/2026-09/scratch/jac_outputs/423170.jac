"""
Return the byte in 7- or 8-bit code table identified by column and row.

"An 8-bit code table consists of 256 positions arranged in 16
columns and 16 rows.  The columns and rows are numbered 00 to 15."

"A 7-bit code table consists of 128 positions arranged in 8
columns and 16 rows.  The columns are numbered 00 to 07 and the
rows 00 to 15 (see figure 1)."

p.5 of "Standard ECMA-35: Character Code Structure and Extension
Techniques", 6th Edition (December 1994).
"""
def _ecmaCodeTableCoordinate(column: int, row: int) -> bytes {
    return bytes(bytearray([(column << 4) | row]));
}