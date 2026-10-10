from typing import List
from src.api.modules.Person.PersonRepository import PersonRepository
from src.api.modules.Person.PersonDtos import (
    PersonCreateDto,
    PersonResponseDto,
)
from src.core.exceptions import NotFoundException


class PersonService:

    def __init__(self):
        self.repository = PersonRepository()

    async def create_person(self, person_data: PersonCreateDto) -> PersonResponseDto:
        """Create a new person"""
        person = await self.repository.create(person_data)
        return PersonResponseDto(
            id=str(person.id),
            name=person.name,
            age=person.age,
            email=person.email,
            phone=person.phone,
            address=person.address,
        )

    async def get_person_by_id(self, person_id: str) -> PersonResponseDto:
        """Get a person by ID"""
        person = await self.repository.get_by_id(person_id)
        if not person:
            raise NotFoundException(f"Person with ID {person_id} not found")

        return PersonResponseDto(
            id=str(person.id),
            name=person.name,
            age=person.age,
            email=person.email,
            phone=person.phone,
            address=person.address,
        )

    async def get_all(
        self, skip: int = 0, limit: int = 100
    ) -> List[PersonResponseDto]:
        """Get all persons with pagination"""
        persons = await self.repository.get_all(skip, limit)
        return [
            PersonResponseDto(
                id=str(person.id),
                name=person.name,
                age=person.age,
                email=person.email,
                phone=person.phone,
                address=person.address,
            )
            for person in persons
        ]
