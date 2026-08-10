"""Given a list of 6 items, each containing a hex-string of
an error corrected block, return a string with all 6 hex strings
concatinated. Used only for FIS-B.

This only returns the bare hex-string with '+'
prepended and no time, signal strength, or error count attached.

Args:
    hexBlocks (list):  List of 6 strings containing a hex string for each
        of the 6 FIS-B hexblocks. Only called if all blocks error corrected
        successfully (i.e. there should be no ``None`` items).

Returns:
    str: String with all hex data and a '+' prepended at the front.
    This function is only for FIS-B packets. No comment data is appended to
    the end.
"""
def fisbHexBlocksToHexString(hexBlocks: list[str]) -> str {
    return '+' + hexBlocks[0] + hexBlocks[1] + hexBlocks[2] + hexBlocks[3] + hexBlocks[4] + hexBlocks[5];
}