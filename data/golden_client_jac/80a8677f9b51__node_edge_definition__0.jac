"""studio - streaming chat endpoint (SSE).

`chat_stream` validates the model then delegates to `inference.stream_chat`, which
holds a single lock across load+generate so a concurrent request can't swap the
resident model mid-stream. The runtime serves the generator as `text/event-stream`,
consumed by a raw fetch reader on the client. Persistence (chat/message nodes) is
handled separately via the persistence.sv.jac walkers the client calls.

Frames: {kind:"load",load_s,model_id} once, {kind:"token",token,text} per token,
{kind:"done",text,tokens,tps,load_s,gen_s} last, {kind:"error",text} on failure.
"""

import inference;
import models;

def:pub chat_stream(
    messages: list[dict], model_id: str,
    temperature: float = 0.2, top_p: float = 0.9, max_tokens: int = 1024
) -> any {
    m = models.model_by_id(model_id);
    if not m {
        yield {"kind": "error", "text": f"unknown model_id: {model_id}"};
        return;
    }
    if not models.model_available(m) {
        yield {"kind": "error", "text": f"model not found on disk: {model_id}"};
        return;
    }
    path = str(models.model_path(m));
    # stream_chat guards load+generate in try/except and emits its own error frame.
    gen: any = inference.stream_chat(messages, model_id, path, temperature, top_p, max_tokens);
    for frame in gen {
        yield frame;
    }
}

"""Cancel the in-flight generation (*gen_id* from the stream's load frame, or the
current one when omitted). Lock-free: the streaming generator holds the model
lock, and this flag is how STOP actually frees the GPU — client-side reader
cancellation alone left the model decoding to max_tokens."""
def:pub stop_generation(gen_id: str = "") -> dict {
    return {"stopped": inference.request_cancel(gen_id)};
}
