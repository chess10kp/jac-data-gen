"""Embedding computation and similarity services for Trace."""

import from math { sqrt }

def cosine_similarity(a: list[float], b: list[float]) -> float {
    if len(a) != len(b) or len(a) == 0 {
        return 0.0;
    }
    dot = 0.0;
    norm_a = 0.0;
    norm_b = 0.0;
    for i in range(len(a)) {
        dot += a[i] * b[i];
        norm_a += a[i] * a[i];
        norm_b += b[i] * b[i];
    }
    denom = sqrt(norm_a) * sqrt(norm_b);
    if denom == 0.0 {
        return 0.0;
    }
    return dot / denom;
}

def compute_text_embedding(text: str) -> list[float]
    by llm(
        reason="Generate a dense vector embedding for the given text that captures its semantic meaning. Return a list of 32 float values between -1 and 1."
    );
