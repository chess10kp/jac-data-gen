from typing import List
from src.api.modules.Book.BookRepository import BookRepository
from src.api.modules.Book.BookDtos import BookCreateDto, BookResponseDto
from src.core.exceptions import NotFoundException

class BookService:
    
    def __init__(self):
        self.repository = BookRepository()
    
    async def create_book(self, book_data: BookCreateDto) -> BookResponseDto:
        """Create a new book"""
        book = await self.repository.create(book_data)
        return BookResponseDto(
            id=str(book.id),
            title=book.title,
            description=book.description,
            isbn=book.isbn,
            author=book.author,
            genre=book.genre,
            available_copies=book.available_copies,
            total_copies=book.total_copies
        )
    
    async def get_book_by_id(self, book_id: str) -> BookResponseDto:
        """Get a book by ID"""
        book = await self.repository.get_by_id(book_id)
        if not book:
            raise NotFoundException(f"Book with ID {book_id} not found")
        
        return BookResponseDto(
            id=str(book.id),
            title=book.title,
            description=book.description,
            isbn=book.isbn,
            author=book.author,
            genre=book.genre,
            available_copies=book.available_copies,
            total_copies=book.total_copies
        )
    
    async def get_all_books(self, skip: int = 0, limit: int = 100) -> List[BookResponseDto]:
        """Get all books with pagination"""
        books = await self.repository.get_all(skip, limit)
        return [
            BookResponseDto(
                id=str(book.id),
                title=book.title,
                description=book.description,
                isbn=book.isbn,
                author=book.author,
                genre=book.genre,
                available_copies=book.available_copies,
                total_copies=book.total_copies
            ) for book in books
        ]
            
    async def get_available_books(self) -> List[BookResponseDto]:
        """Get books that have available copies"""
        books = await self.repository.get_available_books()
        return [
            BookResponseDto(
                id=str(book.id),
                title=book.title,
                description=book.description,
                isbn=book.isbn,
                author=book.author,
                genre=book.genre,
                available_copies=book.available_copies,
                total_copies=book.total_copies
            ) for book in books
        ]
    
    async def check_availability(self, book_id: str) -> bool:
        """Check if a book is available for rental"""
        book = await self.repository.get_by_id(book_id)
        if not book:
            return False
        return book.available_copies > 0