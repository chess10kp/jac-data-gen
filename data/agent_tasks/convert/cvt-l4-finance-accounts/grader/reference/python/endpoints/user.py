from fastapi import APIRouter, HTTPException, status
from models import User, UserCreate
from beanie import PydanticObjectId
from pydantic import BaseModel, EmailStr

router = APIRouter()

class UserUpdate(BaseModel):
    nome: str | None = None
    email: EmailStr | None = None
    senha: str | None = None

# --- ROTAS ---

@router.post("/", response_model=User, status_code=status.HTTP_201_CREATED)
async def create_user(user_in: UserCreate):
    """
    Criar um novo usuário.
    
    **Parâmetros:**
    - nome: Nome completo do usuário
    - email: Email único do usuário
    - senha: Senha do usuário (será criptografada)
    
    **Retorna:** Usuário criado com ID gerado
    
    **Erros:**
    - 400: Email já cadastrado
    """
    existing = await User.find_one(User.email == user_in.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email já cadastrado")
    
    hashed_pw = f"hashed_{user_in.senha}" 
    
    new_user = User(
        nome=user_in.nome,
        email=user_in.email,
        senha_hash=hashed_pw
    )
    await new_user.create()
    return new_user

@router.get("/", response_model=list[User])
async def get_users(limit: int = 10, skip: int = 0):
    """
    Listar todos os usuários com paginação.
    
    **Parâmetros:**
    - limit: Quantidade de usuários a retornar (padrão: 10)
    - skip: Número de registros a pular (padrão: 0)
    
    **Retorna:** Lista de usuários
    """
    return await User.find_all().skip(skip).limit(limit).to_list()

@router.get("/{user_id}", response_model=User)
async def get_user_by_id(user_id: PydanticObjectId):
    """
    Obter um usuário específico pelo ID.
    
    **Parâmetros:**
    - user_id: ID do usuário (ObjectId)
    
    **Retorna:** Dados do usuário solicitado
    
    **Erros:**
    - 404: Usuário não encontrado
    """
    user = await User.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return user

@router.patch("/{user_id}", response_model=User)
async def update_user(user_id: PydanticObjectId, user_in: UserUpdate):
    """
    Atualizar dados de um usuário.
    
    **Parâmetros:**
    - user_id: ID do usuário a atualizar
    - nome: Novo nome (opcional)
    - email: Novo email (opcional)
    - senha: Nova senha (opcional, será criptografada)
    
    **Retorna:** Usuário atualizado
    
    **Erros:**
    - 404: Usuário não encontrado
    """
    user = await User.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    update_data = user_in.model_dump(exclude_unset=True)
    
    if "senha" in update_data:
        update_data["senha_hash"] = f"hashed_{update_data.pop('senha')}"
    
    await user.set(update_data)
    return user

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: PydanticObjectId):
    """
    Deletar um usuário.
    
    **Parâmetros:**
    - user_id: ID do usuário a deletar
    
    **Retorna:** 204 No Content
    
    **Erros:**
    - 404: Usuário não encontrado
    """
    user = await User.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    await user.delete()
    return None