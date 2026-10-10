from beanie import Document
from typing import Optional


class BookModel(Document):
    title: str
    description: str
    isbn: Optional[str] = None
    author: str
    genre: Optional[str] = None
    available_copies: int = 1
    total_copies: int = 1

    class Settings:
        name = "books"
