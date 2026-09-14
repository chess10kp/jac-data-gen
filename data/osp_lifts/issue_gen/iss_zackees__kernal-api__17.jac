# iss_zackees__kernal-api__17.jac

node Blob {
    has blob_id: str;
    has quota: int;
    has max_chunk: int;
    has used: int = 0;
    has read_at: int = 0;
    has closed: bool = False;
    has chunks: list[str] = [];
}

node BlobRegistry {
    has entries: dict[str, Blob] = {};
}

node WriteProgress {
    has accepted: int;
    has remaining: int;
}

node ReadChunk {
    has data: str;
    has done: bool;
}

node OutputFile {
    has output_id: str;
    has authorized: bool = True;
    has content: str = "";
    has temp: str = "";
    has committed: bool = False;
}

edge Owns {}
edge Lineage {}

walker BlobLineage {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Blob entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.blob_id);
        print("visit blob lineage");
        kids: list[Blob] = [];
        for kid in [here ->:Lineage:->][?:Blob] {
            kids.append(kid);
        }
        if len(kids) > 0 {
            visit :0: [kids];
        }
    }
}

def register_blob(registry: BlobRegistry, blob: Blob) -> bool {
    if blob.blob_id in registry.entries {
        return False;
    }
    registry.entries[blob.blob_id] = blob;
    registry +>:Owns:+> blob;
    return True;
}

def blob_exists(registry: BlobRegistry, blob_id: str) -> bool {
    return blob_id in registry.entries;
}

def link_lineage(parent: Blob, child: Blob) -> bool {
    parent +>:Lineage:+> child;
    return True;
}

def lineage_ids(graph_root: Blob) -> list[str] {
    w = graph_root spawn BlobLineage(claimed={}, found=[]);
    return w.found;
}

def blob_write_chunk(blob: Blob, data: str) -> WriteProgress {
    if blob.closed {
        return WriteProgress(accepted=0, remaining=blob.quota - blob.used);
    }
    if len(data) > blob.max_chunk {
        return WriteProgress(accepted=0, remaining=blob.quota - blob.used);
    }
    if blob.used + len(data) > blob.quota {
        return WriteProgress(accepted=0, remaining=blob.quota - blob.used);
    }
    blob.chunks.append(data);
    blob.used = blob.used + len(data);
    return WriteProgress(
        accepted=len(data),
        remaining=blob.quota - blob.used
    );
}

def blob_read_chunk(blob: Blob, max_bytes: int) -> ReadChunk {
    if blob.closed {
        return ReadChunk(data="", done=True);
    }
    if max_bytes <= 0 {
        return ReadChunk(data="", done=blob.read_at >= blob.used);
    }
    if blob.read_at >= blob.used {
        return ReadChunk(data="", done=True);
    }

    start: int = blob.read_at;
    stop: int = start + max_bytes;
    if stop > blob.used {
        stop = blob.used;
    }

    result: str = "";
    position: int = 0;
    for part in blob.chunks {
        next_position: int = position + len(part);
        if next_position > start and position < stop {
            left: int = 0;
            right: int = len(part);
            if start > position {
                left = start - position;
            }
            if stop < next_position {
                right = stop - position;
            }
            result = result + part[left:right];
        }
        position = next_position;
    }
    blob.read_at = stop;
    return ReadChunk(data=result, done=blob.read_at >= blob.used);
}

def blob_close(blob: Blob) -> bool {
    if blob.closed {
        return False;
    }
    blob.closed = True;
    return True;
}

def write_blob_to_output(blob: Blob, output: OutputFile) -> bool {
    if blob.closed or not output.authorized or output.committed {
        return False;
    }
    if blob.max_chunk <= 0 and blob.used > 0 {
        return False;
    }

    blob.read_at = 0;
    output.temp = "";
    done: bool = False;
    while not done {
        piece = blob_read_chunk(blob, blob.max_chunk);
        output.temp = output.temp + piece.data;
        done = piece.done;
    }

    output.content = output.temp;
    output.temp = "";
    output.committed = True;
    return True;
}
