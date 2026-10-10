from pydantic import BaseModel, model_validator, Field
from typing import Optional


class BookCreateDto(BaseModel):
    title: str
    description: str
    isbn: Optional[str] = None
    author: str
    genre: Optional[str] = None
    available_copies: int = Field(0, gte=0)
    total_copies: int = Field(0, gte=0)

    @model_validator(mode="after")
    def validate_copies_quantity(self):
        assert (
            self.available_copies <= self.total_copies
        ), "Available copies cannot exceed total copies"
        return self


class BookResponseDto(BaseModel):
    id: str
    title: str
    description: str
    isbn: Optional[str] = None
    author: str
    genre: Optional[str] = None
    available_copies: int
    total_copies: int
