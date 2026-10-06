"""Document deduplication via content hashing."""

import from hashlib { sha256 }

"""Return SHA-256 hex digest of document content for deduplication."""
def compute_content_hash(content: str) -> str {
    return sha256(content.encode("utf-8", errors="replace")).hexdigest();
}
