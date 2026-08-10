"""Parse chunks and extract information on individual streams."""
def parse_chunks(chunks: Any) -> object {
    streams = [];
    for chunk in chunks {
        if (chunk["tag"] == 2) {
            streams.append(
                `dict(
                    stream_id=chunk["stream_id"],
                    name=chunk.get("name"),
                    `type=chunk.get("type"),
                    source_id=chunk.get("source_id"),
                    created_at=chunk.get("created_at"),
                    uid=chunk.get("uid"),
                    session_id=chunk.get("session_id"),
                    hostname=chunk.get("hostname"),
                    channel_count=int(chunk["channel_count"]),
                    channel_format=chunk["channel_format"],
                    nominal_srate=float(chunk["nominal_srate"])
                )
            );
        }
    }
    return streams;
}