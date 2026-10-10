from typing import List
from datetime import datetime
from src.api.modules.BookRental.BookRentalRepository import BookRentalRepository
from src.api.modules.BookRental.BookRentalDtos import (
    BookRentalCreateDto,
    BookRentalResponseDto,
    BookRentalDetailDto,
)
from src.api.modules.Book.BookRepository import BookRepository
from src.api.modules.Person.PersonRepository import PersonRepository
from src.core.exceptions import NotFoundException, ConflictException
from src.core.message_brokers.rabbitmq import RabbitMQQueue


class BookRentalService:

    def __init__(self):
        self.repository = BookRentalRepository()
        self.book_repository = BookRepository()
        self.person_repository = PersonRepository()
        self.notification_queue = RabbitMQQueue("book_rental_notifications")

    async def create_rental(
        self, rental_data: BookRentalCreateDto
    ) -> BookRentalResponseDto:
        """Create a new book rental"""
        # Check if book exists and is available
        book = await self.book_repository.get_by_id(rental_data.book_id)
        if not book:
            raise NotFoundException(f"Book with ID {rental_data.book_id} not found")

        if book.available_copies <= 0:
            raise ConflictException(f"Book '{book.title}' is not available for rental")

        # Check if person exists
        person = await self.person_repository.get_by_id(rental_data.person_id)
        if not person:
            raise NotFoundException(f"Person with ID {rental_data.person_id} not found")

        # Create rental
        rental = await self.repository.create(rental_data)

        # Update book availability
        await self.book_repository.update_available_copies(rental_data.book_id, -1)

        return BookRentalResponseDto(
            id=str(rental.id),
            book_id=rental.book_id,
            person_id=rental.person_id,
            rental_date=rental.rental_date,
            due_date=rental.due_date,
            return_date=rental.return_date,
            status=rental.status,
        )

    async def get_rental_by_id(self, rental_id: str) -> BookRentalDetailDto:
        """Get a rental by ID with detailed information"""
        rental = await self.repository.get_by_id(rental_id)
        if not rental:
            raise NotFoundException(f"Rental with ID {rental_id} not found")

        # Get book and person details
        book = await self.book_repository.get_by_id(rental.book_id)
        person = await self.person_repository.get_by_id(rental.person_id)

        return BookRentalDetailDto(
            id=str(rental.id),
            book_id=rental.book_id,
            person_id=rental.person_id,
            rental_date=rental.rental_date,
            due_date=rental.due_date,
            return_date=rental.return_date,
            status=rental.status,
            book_title=book.title if book else None,
            person_name=person.name if person else None,
            person_email=person.email if person else None,
        )

    async def get_all_rentals(
        self, skip: int = 0, limit: int = 100
    ) -> List[BookRentalResponseDto]:
        """Get all rentals with pagination"""
        rentals = await self.repository.get_all(skip, limit)
        return [
            BookRentalResponseDto(
                id=str(rental.id),
                book_id=rental.book_id,
                person_id=rental.person_id,
                rental_date=rental.rental_date,
                due_date=rental.due_date,
                return_date=rental.return_date,
                status=rental.status,
            )
            for rental in rentals
        ]

    async def return_book(self, rental_id: str) -> BookRentalResponseDto:
        """Return a rented book"""
        rental = await self.repository.get_by_id(rental_id)
        if not rental:
            raise NotFoundException(f"Rental with ID {rental_id} not found")

        returned_rental = await self.repository.return_book(rental_id)

        await self.book_repository.update_available_copies(rental.book_id, 1)

        return BookRentalResponseDto(
            id=str(returned_rental.id),
            book_id=returned_rental.book_id,
            person_id=returned_rental.person_id,
            rental_date=returned_rental.rental_date,
            due_date=returned_rental.due_date,
            return_date=returned_rental.return_date,
            status=returned_rental.status,
        )

    async def send_notification(
        self, rental: BookRentalDetailDto, notification_type: str
    ):
        """Send notification message to queue"""
        message = {
            "type": notification_type,
            "rental_id": rental.id,
            "book_title": rental.book_title,
            "person_name": rental.person_name,
            "person_email": rental.person_email,
            "due_date": rental.due_date.isoformat(),
            "rental_date": rental.rental_date.isoformat(),
            "timestamp": datetime.now().isoformat(),
        }

        self.notification_queue.publish(message)

    async def check_and_send_notifications(self):
        """Check for rentals that need notifications and send them"""
        rentals_overdue = await self.repository.get_rentals_overdue()
        for rental in rentals_overdue:
            rental_detail = await self.get_rental_by_id(str(rental.id))
            await self.send_notification(rental_detail, "overdue")

        overdue_ids = [str(rental.id) for rental in rentals_overdue]
        if overdue_ids:
            await self.repository.mark_as_overdue(overdue_ids)
