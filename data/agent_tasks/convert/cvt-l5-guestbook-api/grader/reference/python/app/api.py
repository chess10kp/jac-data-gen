from fastapi import FastAPI
from app.model import Entry, retrieve_entries_in_database, insert_entry_into_database, delete_entry_from_database

router = FastAPI()

@router.get("/")
async def welcome():
    return {
        "message": "Welcome to the FastAPI + Okteto series in development mode!"
    }

@router.get("/entries")
async def retrieve_entries():
    entries = await retrieve_entries_in_database()
    return {
        "entries": entries
    }

@router.post("/entry")
async def add_entry(data: Entry):
    new_entry = await insert_entry_into_database(data)
    return {
        "message": "New entry added with ID: {}".format(new_entry)
    }

@router.delete("/entry/{id}")
async def delete_entry(id: str):
    await delete_entry_from_database(id)
    return {
        "message": "Entry deleted successfully"
    }
