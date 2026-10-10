from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from src.api.models.BookRental import RentalStatus

class BookRentalCreateDto(BaseModel):
    book_id: str
    person_id: str
    due_date: datetime

class BookRentalUpdateDto(BaseModel):
    due_date: Optional[datetime] = None
    return_date: Optional[datetime] = None
    status: Optional[RentalStatus] = None

class BookRentalResponseDto(BaseModel):
    id: str
    book_id: str
    person_id: str
    rental_date: datetime
    due_date: datetime
    return_date: Optional[datetime] = None
    status: RentalStatus

class BookRentalDetailDto(BaseModel):
    id: str
    book_id: str
    person_id: str
    rental_date: datetime
    due_date: datetime
    return_date: Optional[datetime] = None
    status: RentalStatus
    book_title: Optional[str] = None
    person_name: Optional[str] = None
    person_email: Optional[str] = None