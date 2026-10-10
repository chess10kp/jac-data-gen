from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional, List
from models.events import Event
from beanie import Document


class User(Document):
    email: EmailStr
    password: str
    events: Optional[List[Event]] = []

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "email": "user@example.com",
                "username": "example name",
                "events": [],
            }
        }
    )

    class Settings:
        name = "users"


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
