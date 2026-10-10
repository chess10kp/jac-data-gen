from beanie import Document, PydanticObjectId
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class Event(Document):
    id: Optional[PydanticObjectId] = Field(default=None, alias="_id")
    title: str
    image: str
    description: str
    tags: List[str]
    location: str
    creator: Optional[str] = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "title": "Hogwarts Alumni Gathering",
                "image": "https://example.com/hogwarts-gathering.jpg",
                "description": "An evening of magical talks, butterbeer, and stories from Hogwarts.",
                "tags": ["harry-potter", "hogwarts", "magic"],
                "location": "Great Hall, Hogwarts Castle",
            }
        }
    )

    class Settings:
        name = "events"


class EventUpdate(BaseModel):
    title: Optional[str] = None
    image: Optional[str] = None
    description: Optional[str] = None
    tags: Optional[List[str]] = None
    location: Optional[str] = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "title": "Hogwarts Alumni Gathering - Updated",
                "image": "https://example.com/hogwarts-gathering-updated.jpg",
                "description": "An updated description for the magical evening.",
                "tags": ["harry-potter", "hogwarts", "magic", "alumni"],
                "location": "Great Hall, Hogwarts Castle",
            }
        }
    )
