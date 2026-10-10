from beanie import Document
from pydantic import EmailStr
from typing import Optional

class PersonModel(Document):
    name: str
    age: int
    email: EmailStr
    phone: Optional[str] = None
    address: Optional[str] = None
    
    class Settings:
        name = "persons"
