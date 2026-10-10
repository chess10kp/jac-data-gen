"""
Database models for the High School Management System

Uses Beanie ODM (Object Document Mapper) for MongoDB
"""

from beanie import Document, Indexed, before_event, Insert, Replace
from pydantic import Field, EmailStr
from datetime import datetime
from enum import Enum
from typing import List, Optional


class UserRole(str, Enum):
    """User roles in the system"""
    STUDENT = "student"
    COORDINATOR = "coordinator"
    ADMIN = "admin"


class EventStatus(str, Enum):
    """Status of an event"""
    DRAFT = "draft"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ClubStatus(str, Enum):
    """Status of a club"""
    DRAFT = "draft"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class RegistrationStatus(str, Enum):
    """Status of a registration"""
    ACTIVE = "active"
    CANCELLED = "cancelled"


class User(Document):
    """User model for students, coordinators, and admins"""
    email: Indexed(EmailStr, unique=True)  # Index for email lookup
    username: Indexed(str, unique=True)  # Index for username lookup
    password_hash: str
    full_name: str
    role: UserRole = UserRole.STUDENT
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "users"
        indexes = [
            ["email"],
            ["username"],
            ["role"],
        ]
    
    @before_event([Replace])
    async def update_timestamp(self):
        self.updated_at = datetime.utcnow()


class Club(Document):
    """Club model for extracurricular clubs"""
    name: Indexed(str, unique=True)  # Index for name lookup
    description: str
    coordinator_id: str  # User ID of the coordinator
    status: ClubStatus = ClubStatus.PENDING
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "clubs"
        indexes = [
            ["name"],
            ["status"],
            ["coordinator_id"],
        ]
    
    @before_event([Replace])
    async def update_timestamp(self):
        self.updated_at = datetime.utcnow()


class Event(Document):
    """Event model for activities/events"""
    name: Indexed(str)  # Index for name lookup
    description: str
    club_id: str  # Reference to Club
    coordinator_id: str  # User ID of the coordinator
    schedule: str  # Text description of when (e.g., "Fridays, 3:30 PM - 5:00 PM")
    max_participants: int
    registration_deadline: Optional[datetime] = None
    status: EventStatus = EventStatus.PENDING
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "events"
        indexes = [
            ["name"],
            ["status"],
            ["coordinator_id"],
            ["club_id"],
        ]
    
    @before_event([Replace])
    async def update_timestamp(self):
        self.updated_at = datetime.utcnow()


class Registration(Document):
    """Registration model for student registrations to events"""
    student_id: str  # User ID
    event_id: str  # Event ID
    status: RegistrationStatus = RegistrationStatus.ACTIVE
    registered_at: datetime = Field(default_factory=datetime.utcnow)
    cancelled_at: Optional[datetime] = None
    
    class Settings:
        name = "registrations"
        indexes = [
            ["student_id"],
            ["event_id"],
            ["status"],
            # Compound index to prevent duplicates
            [("student_id", 1), ("event_id", 1)],
        ]
