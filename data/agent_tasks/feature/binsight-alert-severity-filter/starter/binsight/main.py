from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from config import settings
from routers import analyses, home, recommendations, scraper

app = FastAPI(title="Binsight")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analyses.router, prefix="/api")
app.include_router(home.router, prefix="/api")
app.include_router(scraper.router, prefix="/api")
app.include_router(recommendations.router, prefix="/api")

app.mount("/uploads", StaticFiles(directory=str(settings.data_dir / "uploads")), name="uploads")
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.on_event("startup")
async def startup():
    (settings.data_dir / "analyses").mkdir(parents=True, exist_ok=True)
    (settings.data_dir / "uploads").mkdir(parents=True, exist_ok=True)


@app.get("/")
def serve_spa():
    return FileResponse("static/index.html")
