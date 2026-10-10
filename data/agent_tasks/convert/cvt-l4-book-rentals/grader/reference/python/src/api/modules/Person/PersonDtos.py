from pydantic import BaseModel, EmailStr
from typing import Optional

class PersonCreateDto(BaseModel):
    name: str
    age: int
    email: EmailStr
    phone: Optional[str] = None
    address: Optional[str] = None

class PersonResponseDto(BaseModel):
    id: str
    name: str
    age: int
    email: EmailStr
    phone: Optional[str] = None
    address: Optional[str] = None