from abc import ABC, abstractmethod
from parsers.schemas.book import BookSchema


class BaseConnector(ABC):
    @abstractmethod
    async def connect(self):
        pass

    @abstractmethod
    async def on_parse(self, data: BookSchema):
        pass

    @abstractmethod
    async def close(self):
        pass
