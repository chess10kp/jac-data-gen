from fastapi import APIRouter, Body, HTTPException, status, Depends
from models.events import Event, EventUpdate
from typing import List
from beanie import PydanticObjectId
from database.connection import Database
from auth.authenticate import authenticate

event_router = APIRouter(tags=["Events"])

event_database = Database(Event)


@event_router.get("/", response_model=List[Event])
async def get_all_events() -> List[Event]:
    events = await event_database.get_all()
    return events


@event_router.get("/{event_id}", response_model=Event)
async def get_event_by_id(event_id: PydanticObjectId) -> Event:
    event = await event_database.get(event_id)
    if event:
        return event

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Event with supplied ID does not exist",
    )


@event_router.post("/new")
async def create_event(
    event: Event = Body(...), user: str = Depends(authenticate)
) -> dict:
    event.creator = user
    await event_database.save(event)
    return {"message": "Event created successfully", "id": str(event.id)}


@event_router.delete("/{event_id}")
async def delete_event(
    event_id: PydanticObjectId, user: str = Depends(authenticate)
) -> dict:
    event = await event_database.get(event_id)

    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event with supplied ID does not exist",
        )

    if event.creator != user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Operation not allowed"
        )

    await event_database.delete(event_id)

    return {"message": "Event deleted successfully"}


@event_router.delete("/")
async def delete_all_events(user: str = Depends(authenticate)) -> dict:
    events = await event_database.get_all()

    for event in events:
        await event_database.delete(event.id)

    return {"message": "All events deleted successfully"}


@event_router.put("/edit/{event_id}", response_model=Event)
async def update_event(
    event_id: PydanticObjectId,
    event_update: EventUpdate = Body(...),
    user: str = Depends(authenticate),
) -> Event:
    event = await event_database.get(event_id)

    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event with supplied ID does not exist",
        )

    if event.creator != user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Operation not allowed"
        )

    updated_event = await event_database.update(event_id, event_update)

    return updated_event
