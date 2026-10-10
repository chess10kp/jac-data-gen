from motor.motor_asyncio import AsyncIOMotorClient
from odmantic import AIOEngine


connection_details = "mongodb://mongodb:27017"

client = AsyncIOMotorClient(connection_details)
engine = AIOEngine(client, database="guestbook")