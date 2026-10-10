from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List
from src.api.modules.BookRental.BookRentalService import BookRentalService
from src.api.modules.BookRental.BookRentalDtos import (
    BookRentalCreateDto, BookRentalResponseDto, BookRentalDetailDto
)

router = APIRouter(prefix="/rentals", tags=["rentals"])

def get_rental_service() -> BookRentalService:
    return BookRentalService()

@router.post("/", response_model=BookRentalResponseDto)
async def create_rental(
    rental_data: BookRentalCreateDto,
    service: BookRentalService = Depends(get_rental_service)
):
    """Create a new book rental"""
    return await service.create_rental(rental_data)

@router.get("/{rental_id}", response_model=BookRentalDetailDto)
async def get_rental(
    rental_id: str,
    service: BookRentalService = Depends(get_rental_service)
):
    """Get a rental by ID with detailed information"""
    return await service.get_rental_by_id(rental_id)

@router.get("/", response_model=List[BookRentalResponseDto])
async def get_rentals(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    service: BookRentalService = Depends(get_rental_service)
):
    """Get all rentals with pagination"""
    return await service.get_all_rentals(skip, limit)

@router.put("/{rental_id}/return", response_model=BookRentalResponseDto)
async def return_book(
    rental_id: str,
    service: BookRentalService = Depends(get_rental_service)
):
    """Return a rented book"""
    return await service.return_book(rental_id)

@router.post("/notifications/check")
async def check_notifications(
    service: BookRentalService = Depends(get_rental_service)
):
    """Manually trigger notification check"""
    await service.check_and_send_notifications()
    return {"message": "Notifications checked and sent"}