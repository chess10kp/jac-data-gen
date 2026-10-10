"""
High School Management System API

FastAPI application with MongoDB persistence for managing extracurricular activities
at Mergington High School.
"""

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
from contextlib import asynccontextmanager
import os
from pathlib import Path

from src.database import connect_to_mongo, close_mongo_connection
from src.models import Event, Registration, RegistrationStatus


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events
    """
    # Startup
    try:
        await connect_to_mongo()
        print("🚀 FastAPI application started with MongoDB connection")
    except Exception as e:
        print(f"❌ Failed to start application: {e}")
        raise
    
    yield
    
    # Shutdown
    await close_mongo_connection()
    print("🛑 FastAPI application shutdown")


app = FastAPI(
    title="Mergington High School API",
    description="API for viewing and signing up for extracurricular activities with MongoDB persistence",
    lifespan=lifespan
)

# Mount the static files directory
current_dir = Path(__file__).parent
app.mount("/static", StaticFiles(directory=os.path.join(Path(__file__).parent,
          "static")), name="static")


@app.get("/")
def root():
    return RedirectResponse(url="/static/index.html")


@app.get("/activities")
async def get_activities():
    """Get all approved activities/events"""
    try:
        events = await Event.find(Event.status == "approved").to_list()
        
        # Transform events to match the old format for backward compatibility
        activities = {}
        for event in events:
            # Get registrations for this event
            registrations = await Registration.find(
                Registration.event_id == str(event.id),
                Registration.status == RegistrationStatus.ACTIVE
            ).to_list()
            
            activities[event.name] = {
                "description": event.description,
                "schedule": event.schedule,
                "max_participants": event.max_participants,
                "participants": len(registrations),  # Count instead of list for backward compatibility
                "_id": str(event.id)
            }
        
        return activities
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.post("/activities/{activity_name}/signup")
async def signup_for_activity(activity_name: str, email: str):
    """Sign up a student for an activity"""
    try:
        # Find the event by name
        event = await Event.find_one(Event.name == activity_name)
        if not event:
            raise HTTPException(status_code=404, detail="Activity not found")
        
        # Check if at capacity
        active_registrations = await Registration.find(
            Registration.event_id == str(event.id),
            Registration.status == RegistrationStatus.ACTIVE
        ).count()
        
        if active_registrations >= event.max_participants:
            raise HTTPException(
                status_code=400,
                detail="Activity is at maximum capacity"
            )
        
        # Check if already registered
        existing = await Registration.find_one(
            Registration.event_id == str(event.id),
            Registration.student_id == email
        )
        
        if existing and existing.status == RegistrationStatus.ACTIVE:
            raise HTTPException(
                status_code=400,
                detail="Student is already signed up"
            )
        
        # Create new registration
        registration = Registration(
            student_id=email,
            event_id=str(event.id),
            status=RegistrationStatus.ACTIVE
        )
        await registration.insert()
        
        return {"message": f"Signed up {email} for {activity_name}"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.delete("/activities/{activity_name}/unregister")
async def unregister_from_activity(activity_name: str, email: str):
    """Unregister a student from an activity"""
    try:
        # Find the event by name
        event = await Event.find_one(Event.name == activity_name)
        if not event:
            raise HTTPException(status_code=404, detail="Activity not found")
        
        # Find the registration
        registration = await Registration.find_one(
            Registration.event_id == str(event.id),
            Registration.student_id == email,
            Registration.status == RegistrationStatus.ACTIVE
        )
        
        if not registration:
            raise HTTPException(
                status_code=400,
                detail="Student is not signed up for this activity"
            )
        
        # Mark as cancelled
        registration.status = RegistrationStatus.CANCELLED
        registration.cancelled_at = __import__('datetime').datetime.utcnow()
        await registration.save()
        
        return {"message": f"Unregistered {email} from {activity_name}"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
