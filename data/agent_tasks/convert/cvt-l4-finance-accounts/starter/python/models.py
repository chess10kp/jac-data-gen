from beanie import Document, Link
from beanie.odm.fields import PydanticObjectId
from pydantic import Field, BaseModel, EmailStr
from datetime import datetime

class User(Document):
    nome: str | None = None
    email: EmailStr | None = None
    senha_hash: str | None = None
    categorias: list[Link["Category"]] = Field(default_factory=list)

    class Settings:
        name = "users"
        indexes = ["email"]

class UserCreate(BaseModel):
    nome: str
    email: EmailStr
    senha: str

class UserUpdate(BaseModel):
    nome: str | None = None
    email: EmailStr | None = None
    senha: str | None = None

class Category(Document):
    nome: str | None = None
    user: Link[User]

    class Settings:
        name = "categories"

class CategoryCreate(BaseModel):
    nome: str
    user_id: PydanticObjectId = Field(..., description="ID do usuário dessa categoria")

class Account(Document):
    nome: str | None = None
    tipo: str | None = None
    saldo_inicial: float = 0.0
    usuario: Link[User]

    class Settings:
        name = "accounts"

class AccountCreate(BaseModel):
    nome: str
    tipo: str
    saldo_inicial: float
    usuario_id: PydanticObjectId = Field(..., description="ID do usuário dessa conta")

class AccountUpdate(BaseModel):
    nome: str | None = None
    tipo: str | None = None
    saldo_inicial: float | None = None

class Transaction(Document):
    descricao: str | None = None
    valor: float = 0.0
    data: datetime = Field(default_factory=datetime.now)
    tipo: str | None = None
    conta: Link[Account]
    categoria: Link[Category]

    class Settings:
        name = "transactions"
        indexes = ["data"]

class TransactionCreate(BaseModel):
    descricao: str | None = None
    valor: float
    data: datetime | None = None
    tipo: str
    conta_id: PydanticObjectId
    categoria_id: PydanticObjectId

class TransactionUpdate(BaseModel):
    descricao: str | None = None
    valor: float | None = None
    data: datetime | None = None
    tipo: str | None = None