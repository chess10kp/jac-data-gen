from typing import List, Optional
from beanie import PydanticObjectId
from src.api.models.Book import BookModel
from src.api.modules.Book.BookDtos import BookCreateDto

class BookRepository:
    
    async def create(self, book_data: BookCreateDto) -> BookModel:
        """Create a new book"""
        book = BookModel(**book_data.model_dump())
        return await book.insert()
    
    async def get_by_id(self, book_id: str) -> Optional[BookModel]:
        """Get a book by ID"""
        return await BookModel.get(PydanticObjectId(book_id))
    
    async def get_all(self, skip: int = 0, limit: int = 100) -> List[BookModel]:
        """Get all books with pagination"""
        return await BookModel.find().skip(skip).limit(limit).to_list()
                
    async def get_available_books(self) -> List[BookModel]:
        """Get books that have available copies"""
        return await BookModel.find({"available_copies": {"$gt": 0}}).to_list()
    
    async def update_available_copies(self, book_id: str, change: int) -> Optional[BookModel]:
        """Update available copies (positive to add, negative to subtract)"""
        book = await self.get_by_id(book_id)
        if not book:
            return None
        
        new_available = book.available_copies + change
        if new_available < 0:
            return None
        
        await book.update({"$set": {"available_copies": new_available}})
        return await self.get_by_id(book_id)