from typing_extensions import Annotated
from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional
from bson import ObjectId


class Book(Document):
    title: str
    author_id: ObjectId
    url: Annotated[str, Indexed(unique=True)]
    created_at: datetime = Field(default_factory=datetime.utcnow)

    description: Optional[str] = None
    language: Optional[str] = None
    original_language: Optional[str] = None
    original_name: Optional[str] = None
    cover_type: Optional[str] = None
    number_of_pages: Optional[int] = None
    publisher: Optional[str] = None
    publish_year: Optional[int] = None
    genre: Optional[str] = None
    series: Optional[str] = None
    format: Optional[str] = None
    weight_in_grams: Optional[float] = None
    isbn: Optional[str] = None
    age_restriction: Optional[str] = None
    price: Optional[float] = None

    translators: Optional[str] = None

    embedding: Optional[list[float]] = None
    model_config = {
        "arbitrary_types_allowed": True
    }

    class Settings:
        name = "books"
        indexes = [
            "author_id",
            "title",
            "genre",
            "isbn",
        ]
