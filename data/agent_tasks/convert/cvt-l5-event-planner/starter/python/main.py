from contextlib import asynccontextmanager
from fastapi import FastAPI
from routes.users import user_router
from routes.events import event_router
from database.connection import Settings

from fastapi.middleware.cors import CORSMiddleware

import uvicorn


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    settings = Settings()
    await settings.init_db()
    yield


app = FastAPI(lifespan=lifespan)

origins = [
    "*"
]  # Allow all origins for development purposes. In production, specify allowed origins.

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(user_router, prefix="/user")
app.include_router(event_router, prefix="/event")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
