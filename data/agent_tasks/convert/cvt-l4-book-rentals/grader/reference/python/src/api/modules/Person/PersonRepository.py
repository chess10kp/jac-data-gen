from typing import List, Optional
from beanie import PydanticObjectId
from src.api.models.Person import PersonModel
from src.api.modules.Person.PersonDtos import PersonCreateDto


class PersonRepository:

    async def create(self, person_data: PersonCreateDto) -> PersonModel:
        """Create a new person"""
        person = PersonModel(**person_data.model_dump())
        return await person.insert()

    async def get_by_id(self, person_id: str) -> Optional[PersonModel]:
        """Get a person by ID"""
        return await PersonModel.get(PydanticObjectId(person_id))

    async def get_all(self, skip: int = 0, limit: int = 100) -> List[PersonModel]:
        """Get all people with pagination"""
        return await PersonModel.find().skip(skip).limit(limit).to_list()
