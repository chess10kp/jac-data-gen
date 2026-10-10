"""Example Beanie document model used by the demo API.

Mirrors the Mongoose ``Book`` schema in the sibling playground so the two demos
are directly comparable. Note there is intentionally **no index collation**:
DocumentDB does not implement collation indexes.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional

from beanie import Document
from pydantic import Field
from pymongo import ASCENDING, IndexModel


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Book(Document):
    title: str
    author: str
    genres: List[str] = Field(default_factory=list)
    pages: Optional[int] = None
    published: Optional[datetime] = None
    in_stock: bool = True
    rating: Optional[float] = None
    created_at: datetime = Field(default_factory=_utcnow)
    updated_at: datetime = Field(default_factory=_utcnow)

    class Settings:
        name = "books"
        # Compound index: exercises DocumentDB index creation via Beanie.
        # No `collation` option here; DocumentDB does not implement it.
        indexes = [
            IndexModel([("author", ASCENDING), ("title", ASCENDING)]),
        ]
