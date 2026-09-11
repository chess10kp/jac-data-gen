"""DanielMSchmidt/cfast#305 — folder visibility inheritance parent walk."""


def load_folders(parents: dict[str, str | None], visibility: dict[str, str]) -> dict:
    return {"parents": dict(parents), "visibility": dict(visibility)}


def _walk_up(reg: dict, fid: str) -> list[str]:
    chain: list[str] = []
    cur: str | None = fid
    seen: set[str] = set()
    while cur is not None and cur in reg["parents"]:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = reg["parents"][cur]
    return chain


def effective_visibility(reg: dict, folder: str) -> str:
    if folder not in reg["parents"]:
        return "restricted"
    for fid in _walk_up(reg, folder):
        vis = reg["visibility"].get(fid, "inherit")
        if vis != "inherit":
            return vis
    return "restricted"


def ancestor_folders(reg: dict, folder: str) -> list[str]:
    chain = _walk_up(reg, folder)
    return list(reversed(chain))
