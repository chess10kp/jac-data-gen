"""Embedding generator — creates vector embeddings for documents via OpenAI."""

import from os { environ }

glob EMBEDDING_MODEL: str = "text-embedding-3-small";
glob EMBEDDING_DIM: int = 1536;
glob MAX_CHARS: int = 32000;

"""
Generate a vector embedding for a text chunk.
Returns list of floats (embedding vector) or empty list on failure.
"""
def generate_embedding(text: str) -> list[float] {
    if text.strip() == "" {
        return [];
    }
    truncated = text[:MAX_CHARS];
    try {
        import from openai { OpenAI }
        client = OpenAI(api_key=environ.get("OPENAI_API_KEY", ""));
        resp = client.embeddings.create(input=truncated, model=EMBEDDING_MODEL);
        return resp.data[0].embedding;
    } except Exception as e {
        print(f"[Embedding] Generation failed: {e}");
        return [];
    }
}

"""
Generate embeddings for a batch of texts.
Returns list of embedding vectors (empty list for failed items).
"""
def generate_batch_embeddings(texts: list[str]) -> list[list[float]] {
    if len(texts) == 0 {
        return [];
    }
    try {
        import from openai { OpenAI }
        client = OpenAI(api_key=environ.get("OPENAI_API_KEY", ""));
        cleaned = [];
        for t in texts {
            if len(t) > MAX_CHARS {
                cleaned.append(t[:MAX_CHARS]);
            } else {
                cleaned.append(t);
            }
        }
        resp = client.embeddings.create(input=cleaned, model=EMBEDDING_MODEL);
        result = [];
        for item in resp.data {
            result.append(item.embedding);
        }
        return result;
    } except Exception as e {
        print(f"[Embedding] Batch generation failed: {e}");
        empty = [];
        for _ in texts {
            empty.append([]);
        }
        return empty;
    }
}

"""Compute cosine similarity between two embedding vectors."""
def cosine_similarity(vec_a: list[float], vec_b: list[float]) -> float {
    if len(vec_a) == 0 or len(vec_b) == 0 or len(vec_a) != len(vec_b) {
        return 0.0;
    }
    try {
        import from math { sqrt }
        dot = 0.0;
        for i in range(len(vec_a)) {
            dot += vec_a[i] * vec_b[i];
        }
        sum_a = 0.0;
        for val in vec_a {
            sum_a += val * val;
        }
        sum_b = 0.0;
        for val in vec_b {
            sum_b += val * val;
        }
        mag_a = sqrt(sum_a);
        mag_b = sqrt(sum_b);
        if mag_a == 0.0 or mag_b == 0.0 {
            return 0.0;
        }
        return dot / (mag_a * mag_b);
    } except Exception {
        return 0.0;
    }
}
