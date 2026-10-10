"""FastAPI + Beanie demo REST API for DocumentDB.

Run locally with scripts/run-app.sh, or directly:

    MONGO_URI="mongodb://user:pass@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true&directConnection=true" \
        python main.py

Endpoints:
    GET    /health          -> liveness/readiness (checks the gateway ping)
    POST   /books           -> create a book
    GET    /books           -> list books (optional ?author= filter)
    GET    /books/{id}       -> fetch one book by id (see _id known issue)
    PATCH  /books/{id}       -> update a book
    DELETE /books/{id}       -> delete a book
    GET    /stats/genres    -> aggregation: count of books per genre
"""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import List, Optional

from beanie import PydanticObjectId
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

import db
from models.book import Book

PORT = int(os.environ.get("PORT", "3000"))


@asynccontextmanager
async def lifespan(_app: FastAPI):
    await db.init([Book])
    print("Connected to DocumentDB via Beanie")
    yield
    await db.close()


app = FastAPI(title="DocumentDB Beanie demo", lifespan=lifespan)


class BookCreate(BaseModel):
    title: str
    author: str
    genres: List[str] = []
    pages: Optional[int] = None
    published: Optional[datetime] = None
    in_stock: bool = True
    rating: Optional[float] = None


class BookUpdate(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    genres: Optional[List[str]] = None
    pages: Optional[int] = None
    published: Optional[datetime] = None
    in_stock: Optional[bool] = None
    rating: Optional[float] = None


@app.get("/health")
async def health():
    """Return 200 only when the gateway responds to a ping."""
    try:
        if await db.ping():
            return {"status": "healthy", "db": "connected"}
    except Exception as exc:  # noqa: BLE001 - report any connection error as unhealthy
        return JSONResponse(status_code=503, content={"status": "unhealthy", "db": str(exc)})
    return JSONResponse(status_code=503, content={"status": "unhealthy", "db": "disconnected"})


@app.post("/books", status_code=201)
async def create_book(payload: BookCreate):
    book = Book(**payload.model_dump())
    await book.insert()
    return book


@app.get("/books")
async def list_books(author: Optional[str] = None):
    query = {"author": author} if author else {}
    books = await Book.find(query).sort("-created_at").limit(100).to_list()
    return {"count": len(books), "books": books}


@app.get("/books/{book_id}")
async def get_book(book_id: PydanticObjectId):
    book = await Book.get(book_id)
    if book is None:
        raise HTTPException(status_code=404, detail="not found")
    return book


@app.patch("/books/{book_id}")
async def update_book(book_id: PydanticObjectId, payload: BookUpdate):
    book = await Book.get(book_id)
    if book is None:
        raise HTTPException(status_code=404, detail="not found")
    changes = payload.model_dump(exclude_unset=True)
    if changes:
        changes["updated_at"] = datetime.now(timezone.utc)
        await book.set(changes)
    return book


@app.delete("/books/{book_id}", status_code=204)
async def delete_book(book_id: PydanticObjectId):
    book = await Book.get(book_id)
    if book is None:
        raise HTTPException(status_code=404, detail="not found")
    await book.delete()
    return None


@app.get("/stats/genres")
async def genre_stats():
    pipeline = [
        {"$unwind": "$genres"},
        {"$group": {"_id": "$genres", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
    ]
    return await Book.aggregate(pipeline).to_list()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=PORT)
