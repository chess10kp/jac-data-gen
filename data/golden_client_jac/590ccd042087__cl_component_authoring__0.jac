"""useRowPager — shared pager/fetch controller behind the RowBrowser.

Owns the files/path/rows/offset/total/expanded state plus the openFile /
toggleRow / prevPage / nextPage actions that the 01 (Data), 02 (RlData) and
03 (CptData) sections used to triplicate. Parameterized by two fetch callables
the section supplies:

  fetch_files(ctx?)          -> list[FileRefView-like]  (ctx optional, see below)
  fetch_rows(path, off, ctx?) -> {"rows": [...], "total": n}

`ctx` is an optional opaque value threaded from loadFiles(ctx) into both
callables, for sections with an extra fetch dimension (RlData's source):
setting state then fetching in the same handler reads the stale value (React
writes are async — same reason `p`/`off` are passed explicitly everywhere), so
the new source must ride along explicitly. Sections without the dimension just
ignore the extra arg.

Loads the file list (and opens the first file) on mount; loadFiles(ctx) re-runs
that reset for source switches, refreshFiles() re-reads the file list only
(counts changed) without disturbing the open file/page.
"""

def:pub useRowPager(fetch_files: any = None, fetch_rows: any = None, page_size: int = 25) -> dict {
    has files: list = [],
        path: str = "",
        rows: list = [],
        offset: int = 0,
        total: int = 0,
        expanded: int = -1;

    # `p`/`off` are passed explicitly — reading the state right after setting it
    # returns the stale value (React state writes are async).
    async def _fetch(p: str, off: int, ctx: any = None) -> None {
        r = await fetch_rows(p, off, ctx);
        rows = list(r["rows"]);
        total = int(r["total"]);
    }

    async def openFile(p: str) -> None {
        path = p;
        offset = 0;
        expanded = -1;
        await _fetch(p, 0);
    }

    def toggleRow(idx: int) -> None {
        expanded = -1 if expanded == idx else idx;
    }

    async def prevPage -> None {
        if offset > 0 {
            noff = max(0, offset - page_size);
            offset = noff;
            expanded = -1;
            await _fetch(path, noff);
        }
    }

    async def nextPage -> None {
        if offset + len(rows) < total {
            noff = offset + page_size;
            offset = noff;
            expanded = -1;
            await _fetch(path, noff);
        }
    }

    async def loadFiles(ctx: any = None) -> None {
        fs = await fetch_files(ctx);
        files = list(fs);
        offset = 0;
        expanded = -1;
        if len(list(fs)) > 0 {
            path = str(fs[0].path);
            await _fetch(str(fs[0].path), 0, ctx);
        } else {
            path = ""; rows = []; total = 0;
        }
    }

    async def refreshFiles -> None {
        fs = await fetch_files();
        files = list(fs);
    }

    async can with entry {
        await loadFiles();
    }

    return {
        "files": files, "path": path, "rows": rows, "offset": offset,
        "total": total, "expanded": expanded,
        "openFile": openFile, "toggleRow": toggleRow,
        "prevPage": prevPage, "nextPage": nextPage,
        "loadFiles": loadFiles, "refreshFiles": refreshFiles
    };
}
