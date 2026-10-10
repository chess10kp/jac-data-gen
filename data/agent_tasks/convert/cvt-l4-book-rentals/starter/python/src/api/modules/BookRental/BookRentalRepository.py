from typing import List, Optional
from beanie import PydanticObjectId
from datetime import datetime
from src.api.models.BookRental import BookRentalModel, RentalStatus
from src.api.modules.BookRental.BookRentalDtos import (
    BookRentalCreateDto,
    BookRentalUpdateDto,
)


class BookRentalRepository:

    async def create(self, rental_data: BookRentalCreateDto) -> BookRentalModel:
        """Create a new book rental"""
        rental = BookRentalModel(**rental_data.model_dump())
        return await rental.insert()

    async def update(self, rental_id: str, update_data: BookRentalUpdateDto) -> Optional[BookRentalModel]:
        """Update a rental"""
        rental = await self.get_by_id(rental_id)
        if not rental:
            return None
        
        update_dict = update_data.model_dump(exclude_unset=True)
        await rental.update({"$set": update_dict})
        return await self.get_by_id(rental_id)

    async def get_by_id(self, rental_id: str) -> Optional[BookRentalModel]:
        """Get a rental by ID"""
        return await BookRentalModel.get(PydanticObjectId(rental_id))

    async def get_all(self, skip: int = 0, limit: int = 100) -> List[BookRentalModel]:
        """Get all rentals with pagination"""
        return await BookRentalModel.find().skip(skip).limit(limit).to_list()

    async def get_by_person_id(self, person_id: str) -> List[BookRentalModel]:
        """Get all rentals for a specific person"""
        return await BookRentalModel.find({"person_id": person_id}).to_list()

    async def get_by_book_id(self, book_id: str) -> List[BookRentalModel]:
        """Get all rentals for a specific book"""
        return await BookRentalModel.find({"book_id": book_id}).to_list()

    async def get_active_rentals(self) -> List[BookRentalModel]:
        """Get all active rentals"""
        return await BookRentalModel.find({"status": RentalStatus.ACTIVE}).to_list()

    async def get_overdue_rentals(self) -> List[BookRentalModel]:
        """Get all overdue rentals"""
        return await BookRentalModel.find({"status": RentalStatus.OVERDUE}).to_list()

    async def get_rentals_overdue(self) -> List[BookRentalModel]:
        """Get rentals that are overdue by specified days"""
        cutoff_date = datetime.now()
        return await BookRentalModel.find(
            {"due_date": {"$lt": cutoff_date}, "status": RentalStatus.ACTIVE}
        ).to_list()

    async def mark_as_overdue(self, rental_ids: List[str]) -> int:
        """Mark rentals as overdue"""
        result = await BookRentalModel.find(
            {"_id": {"$in": [PydanticObjectId(rid) for rid in rental_ids]}}
        ).update({"$set": {"status": RentalStatus.OVERDUE}})
        return result.modified_count

    async def return_book(self, rental_id: str) -> Optional[BookRentalModel]:
        """Mark a rental as returned"""
        return await self.update(
            rental_id,
            BookRentalUpdateDto(
                return_date=datetime.now(), status=RentalStatus.RETURNED
            ),
        )
