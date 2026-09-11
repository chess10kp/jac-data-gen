"""OLE2 sector-chain traversal with bounded walk.

Compound-file streams are stored as chains of sectors: each FAT/MiniFAT
entry names the next sector in the stream and ENDOFCHAIN (-2) terminates
the chain. ``sect_chain`` chases that linked list to materialize the
sector sequence for a write. A malformed document can contain a cyclic
chain (e.g. a MiniFAT entry pointing back at itself); this walk had no
visited set or iteration bound, so a crafted file hung ``write_stream``
forever. The remediation adds a visited-sector set and raises on cycles.
Ref: decalage2/olefile#179
"""

ENDOFCHAIN = -2
FREESECT = -1


class ChainCycleError(ValueError):
    """Raised when a FAT/MiniFAT chain loops back onto itself."""


def load_fat(table):
    """``table``: {sector: next_sector} mapping; returns the fat handle."""
    return {"fat": dict(table)}


def sect_chain(fat, start):
    """Sector ids of the chain starting at ``start``, ENDOFCHAIN excluded.

    Raises ChainCycleError when the chain revisits a sector.
    """
    table = fat["fat"]
    chain = []
    seen = set()
    cur = start
    while cur != ENDOFCHAIN:
        if cur in seen:
            raise ChainCycleError("cyclic sector chain")
        seen.add(cur)
        chain.append(cur)
        if cur not in table or table[cur] == FREESECT:
            break  # truncated / free tail: tolerated, chain ends here
        cur = table[cur]
    return chain


def is_well_formed(fat, start):
    """True when the chain from ``start`` is acyclic."""
    try:
        sect_chain(fat, start)
    except ChainCycleError:
        return False
    return True


def chain_length(fat, start):
    """Number of sectors in the chain; -1 when malformed (cyclic)."""
    try:
        return len(sect_chain(fat, start))
    except ChainCycleError:
        return -1
