import datetime

from odmantic import Model, ObjectId, Field
from typing import Optional
from app.database import engine

class Entry(Model):
    name: str
    entry: str
    date: Optional[datetime.datetime] = Field(default_factory=datetime.datetime.now)


async def retrieve_entries_in_database():
    entries = await engine.find(Entry)
    return entries


async def insert_entry_into_database(entry):
    new_entry = await engine.save(entry)
    return str(new_entry.id)


async def delete_entry_from_database(id):
    entries = await engine.find(Entry)
    for e in entries:
        if e.id == ObjectId(id):
            await engine.delete(e)
    return