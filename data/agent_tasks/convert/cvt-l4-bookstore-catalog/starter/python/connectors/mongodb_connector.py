from typing import Optional, List
from bson import ObjectId

from connectors.base_connector import BaseConnector
from parsers.schemas.book import BookSchema
from db.mongodb.client import init_db
from db.mongodb.models import Author, Book

from langchain_openai.embeddings import OpenAIEmbeddings

from logger import create_scoped_logger

logger = create_scoped_logger("MongoDBConnector")


class MongoDBConnector(BaseConnector):
    def __init__(self,
                 mongo_url: str,
                 mongo_db_name: str,
                 openai_api_key: str,
                 embedding_model: str = "text-embedding-3-small",
                 make_embeddings: bool = True
                 ):
        self.embeddings = None
        self.make_embeddings = make_embeddings
        self.embedding_model = embedding_model
        self.mongo_url = mongo_url
        self.mongo_db_name = mongo_db_name
        self.openai_api_key = openai_api_key

    async def connect(self):
        logger.info("Connecting to MongoDB...")
        await init_db(
            mongo_url=self.mongo_url,
            mongo_db_name=self.mongo_db_name
        )
        logger.info("Connected to MongoDB")

        logger.info("Setting up OpenAI Embeddings...")
        self.embeddings = OpenAIEmbeddings(
            api_key=self.openai_api_key,
            model=self.embedding_model,
        )
        logger.info("OpenAI Embeddings set up successfully")


    async def on_parse(self, data: BookSchema) -> None:
        if data.count_in_complect > 1:
            logger.info(f"Skipping book '{data.book_title}' as it is part of a complect ({data.count_in_complect})")
            return

        author_id = await self._save_author(data)
        if author_id is None:
            logger.error("Aborting: author_id is None; book will not be saved")
            return

        book_id = await self._save_book(data, author_id)
        if book_id is None:
            logger.error("Book was not saved due to previous errors")
            return

        logger.info(f"Data saved: Author ID: {author_id}, Book ID: {book_id}")

    async def _save_author(self, data: BookSchema) -> Optional[ObjectId]:
        try:
            author = await Author.find_one(Author.name == data.author_name)
            if author:
                logger.info("Author already exists")
                return author.id

            author = Author(name=data.author_name)
            await author.save()
            logger.info("Author saved successfully")
            return author.id
        except Exception as e:
            logger.exception(f"Error saving author: {e}")
            return None

    async def _save_book(self, data: BookSchema, author_id: ObjectId) -> Optional[ObjectId]:
        try:
            book = await Book.find_one(Book.url == data.url)
            if book:
                logger.info("Book already exists, refreshing...")
                self._apply_book_fields(book, data, author_id)

                if self.make_embeddings and not book.embedding:
                    book.embedding = self._create_embeddings(data)

                await book.save()
                logger.info("Book updated successfully")
                return book.id

            book = Book(
                **self._book_payload(data, author_id),
                embedding=self._create_embeddings(data),
            )
            await book.save()
            logger.info("Book saved successfully")
            return book.id
        except Exception as e:
            logger.exception(f"Error saving book: {e}")
            return None

    def _create_embeddings(self, data: BookSchema) -> Optional[list[float]]:
        if not self.make_embeddings or not self.embeddings:
            return None
        try:
            prepared = self._prepare_for_embedding(data)
            vectors = self.embeddings.embed_documents([prepared])
            logger.info("Embeddings created successfully")
            return vectors[0] if vectors else None
        except Exception as e:
            logger.exception(f"Error creating embeddings: {e}")
            return None

    # helpers
    def _apply_book_fields(self, book: Book, data: BookSchema, author_id: ObjectId) -> None:
        book.title = data.book_title
        book.author_id = author_id
        book.description = data.description
        book.language = data.language
        book.original_language = data.original_language
        book.original_name = data.original_name
        book.cover_type = data.cover_type
        book.number_of_pages = data.number_of_pages
        book.publisher = data.publisher
        book.publish_year = data.publish_year
        book.genre = data.genre
        book.series = data.series
        book.format = data.format
        book.weight_in_grams = data.weight_in_grams
        book.isbn = data.isbn
        book.age_restriction = data.age_restriction
        book.price = data.price
        book.translators = data.translators

    def _book_payload(self, data: BookSchema, author_id: ObjectId) -> dict:
        return dict(
            title=data.book_title,
            author_id=author_id,
            url=data.url,
            description=data.description,
            language=data.language,
            original_language=data.original_language,
            original_name=data.original_name,
            cover_type=data.cover_type,
            number_of_pages=data.number_of_pages,
            publisher=data.publisher,
            publish_year=data.publish_year,
            genre=data.genre,
            series=data.series,
            format=data.format,
            weight_in_grams=data.weight_in_grams,
            isbn=data.isbn,
            age_restriction=data.age_restriction,
            price=data.price,
            translators=data.translators,
        )

    def _prepare_for_embedding(self, data: BookSchema):
        logger.info("Preparing data for embedding...")
        query = ""

        if data.book_title:
            query += f"Title: {data.book_title}\n"
        if data.original_name:
            query += f"Original Name: {data.original_name}\n"

        if data.author_name:
            query += f"Author: {data.author_name}\n"

        if data.description:
            query += f"Description: {data.description}\n"

        return query.strip()

    async def close(self):
        logger.info("Closing MongoDB connection...")
        # Close MongoDB connection
        logger.info("MongoDB connection closed")
