"""
Database configuration and connection management
"""

from motor.motor_asyncio import AsyncClient, AsyncDatabase
from beanie import init_beanie
from pydantic_settings import BaseSettings
from pathlib import Path
import os
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


class Settings(BaseSettings):
    """Application settings from environment variables"""
    mongodb_url: str = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    database_name: str = os.getenv("DATABASE_NAME", "mergington_school")
    environment: str = os.getenv("ENVIRONMENT", "development")

    class Config:
        env_file = ".env"


settings = Settings()

# MongoDB client instance
client: AsyncClient = None
db: AsyncDatabase = None


async def connect_to_mongo():
    """Initialize MongoDB connection"""
    global client, db
    try:
        client = AsyncClient(settings.mongodb_url)
        db = client[settings.database_name]
        
        # Import models to ensure indexes are created
        from .models import User, Club, Event, Registration
        
        # Initialize Beanie with models
        await init_beanie(
            database=db,
            models=[User, Club, Event, Registration]
        )
        print(f"✅ Connected to MongoDB: {settings.database_name}")
    except Exception as e:
        print(f"❌ Failed to connect to MongoDB: {e}")
        raise


async def close_mongo_connection():
    """Close MongoDB connection"""
    global client
    if client:
        client.close()
        print("✅ Closed MongoDB connection")


def get_database():
    """Get the database instance"""
    return db
