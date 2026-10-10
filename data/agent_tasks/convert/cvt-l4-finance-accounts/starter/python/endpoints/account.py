from fastapi import APIRouter, HTTPException, status
from models import Account, AccountCreate, User
from beanie import PydanticObjectId
from pydantic import BaseModel

router = APIRouter()

class AccountUpdate(BaseModel):
    nome: str | None = None
    tipo: str | None = None
    saldo_inicial: float | None = None

# --- ROTAS ---

@router.post("/", response_model=Account, status_code=status.HTTP_201_CREATED)
async def create_account(acc_in: AccountCreate):
    """
    Criar uma nova conta bancária.
    
    **Parâmetros:**
    - nome: Nome da conta (ex: Conta Principal, Poupança)
    - tipo: Tipo da conta (ex: Conta corrente, Poupança, Crédito)
    - saldo_inicial: Saldo inicial em reais
    - usuario_id: ID do usuário proprietário da conta
    
    **Retorna:** Conta criada com ID gerado
    
    **Erros:**
    - 404: Usuário não encontrado
    """
    user = await User.get(acc_in.usuario_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    new_acc = Account(
        nome=acc_in.nome,
        tipo=acc_in.tipo,
        saldo_inicial=acc_in.saldo_inicial,
        usuario=user # type: ignore
    )
    await new_acc.create()
    return new_acc

@router.get("/", response_model=list[Account])
async def get_accounts(limit: int = 10, skip: int = 0):
    """
    Listar todas as contas com paginação.
    
    **Parâmetros:**
    - limit: Quantidade de contas a retornar (padrão: 10)
    - skip: Número de registros a pular (padrão: 0)
    
    **Retorna:** Lista de contas
    """
    return await Account.find_all().skip(skip).limit(limit).to_list()

@router.get("/{acc_id}", response_model=Account)
async def get_account(acc_id: PydanticObjectId):
    """
    Obter uma conta específica pelo ID.
    
    **Parâmetros:**
    - acc_id: ID da conta (ObjectId)
    
    **Retorna:** Dados da conta solicitada
    
    **Erros:**
    - 404: Conta não encontrada
    """
    acc = await Account.get(acc_id)
    if not acc:
        raise HTTPException(status_code=404, detail="Conta não encontrada")
    return acc

@router.patch("/{acc_id}", response_model=Account)
async def update_account(acc_id: PydanticObjectId, acc_in: AccountUpdate):
    """
    Atualizar dados de uma conta.
    
    **Parâmetros:**
    - acc_id: ID da conta a atualizar
    - nome: Novo nome da conta (opcional)
    - tipo: Novo tipo de conta (opcional)
    - saldo_inicial: Novo saldo inicial (opcional)
    
    **Retorna:** Conta atualizada
    
    **Erros:**
    - 404: Conta não encontrada
    """
    acc = await Account.get(acc_id)
    if not acc:
        raise HTTPException(status_code=404, detail="Conta não encontrada")
    
    await acc.set(acc_in.model_dump(exclude_unset=True))
    return acc

@router.delete("/{acc_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(acc_id: PydanticObjectId):
    """
    Deletar uma conta.
    
    **Parâmetros:**
    - acc_id: ID da conta a deletar
    
    **Retorna:** 204 No Content
    
    **Erros:**
    - 404: Conta não encontrada
    """
    acc = await Account.get(acc_id)
    if not acc:
        raise HTTPException(status_code=404, detail="Conta não encontrada")
    await acc.delete()
    return None