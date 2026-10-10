from typing import Optional
from pydantic import BaseModel, Field


class BookSchema(BaseModel):
    url : str = Field(..., description="The URL of the book page")

    book_title  : Optional[str] = Field(None, description="The title of the book")
    author_name : Optional[str] = Field(None, description="The name of the author")
    description : Optional[str] = Field(None, description="A brief description of the book")

    language          : Optional[str] = Field(None, description="The language of the book")
    original_language : Optional[str] = Field(None, description="The original language of the book")
    original_name     : Optional[str] = Field(None, description="The original name of the book")

    cover_type       : Optional[str] = Field(None, description="The cover type of the book")
    number_of_pages  : Optional[int] = Field(None, description="The number of pages in the book")

    publisher    : Optional[str] = Field(None, description="The publisher of the book")
    publish_year : Optional[int] = Field(None, description="The year the book was published")

    genre  : Optional[str] = Field(None, description="The genre of the book")
    series : Optional[str] = Field(None, description="The series the book belongs to")

    format           : Optional[str]   = Field(None, description="The format of the book")
    weight_in_grams  : Optional[float] = Field(None, description="The weight of the book in grams")

    isbn              : Optional[str]   = Field(None, description="The ISBN of the book")
    count_in_complect : Optional[int]   = Field(None, description="The count of books in the complect")
    age_restriction   : Optional[str]   = Field(None, description="The age restriction for the book")
    price             : Optional[float] = Field(None, description="The price of the book")
    translators       : Optional[str]   = Field(None, description="The translators of the book")

