from beanie import Document
from pydantic import Field
from datetime import datetime
from typing import Optional
from enum import Enum

class RentalStatus(str, Enum):
    ACTIVE = "active"
    RETURNED = "returned"
    OVERDUE = "overdue"

class BookRentalModel(Document):
    book_id: str
    person_id: str
    rental_date: datetime = Field(default_factory=datetime.now)
    due_date: datetime
    return_date: Optional[datetime] = None
    status: RentalStatus = RentalStatus.ACTIVE
    
    class Settings:
        name = "book_rentals"