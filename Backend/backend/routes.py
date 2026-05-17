from fastapi import APIRouter, Depends, HTTPException, status, Header
from laiagenlib.Domain.LaiaBaseModel.ModelRepository import ModelRepository
from laiagenlib.Application.LaiaBaseModel import ReadLaiaBaseModel, CreateLaiaBaseModel, DeleteLaiaBaseModel, SearchLaiaBaseModel, UpdateLaiaBaseModel
from laiagenlib.Application.LaiaUser import JWTToken
from .models import User, Wallet, Transaction, Shop
from pydantic import BaseModel, Field, SecretStr
from typing import Optional, List
import datetime
import os
import json
from pathlib import Path

# Load config to get JWT secret
def load_config():
    env = os.getenv("APP_ENV", "dev")
    config_path = Path(__file__).resolve().parent.parent.parent / "config" / f"{env}.json"
    with open(config_path, "r") as f:
        return json.load(f)

config = load_config()
JWT_SECRET_KEY = config["jwt"].get("secret_key", "mysecret")

class UserResponse(BaseModel):
    id: Optional[str] = Field(None, alias="_id", description='User ID')
    owner: Optional[str] = Field(None, description='User owner')
    name: str = Field(..., description='User first name', )
    surnames: Optional[str] = Field(None, description='User last name', )
    email: str = Field(..., description='User email address', )
    password: Optional[SecretStr] = Field(None, description='User password', )
    phone: Optional[str] = Field(None, description='User phone number', )

class WalletResponse(BaseModel):
    balance: float
    currency: str
    transactions: List[dict]

class TopUpRequest(BaseModel):
    amount: float
    description: Optional[str] = "Wallet Top-up"

class SendRequest(BaseModel):
    recipient_email: str
    amount: float
    description: Optional[str] = "Transfer"

class PayRequest(BaseModel):
    amount: float
    merchant: str

async def get_current_user_id(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    token = authorization.split(" ")[1]
    try:
        payload = JWTToken.verify_jwt_token(token, JWT_SECRET_KEY)
        return payload.get("user_id")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

def ExtraRoutes(repository: ModelRepository=None):
    router = APIRouter(prefix="/wallet", tags=["Wallet"])

    @router.get("/", response_model=WalletResponse)
    async def get_wallet(user_id: str = Depends(get_current_user_id)):
        # Find wallet for user
        wallets = await SearchLaiaBaseModel.search_laia_base_model(0, 1, {"user_id": user_id}, [], Wallet, ['admin'], repository)
        if not wallets['items']:
            # Create a wallet if it doesn't exist
            wallet_data = {
                "address": f"W-{user_id[:8]}",
                "balance": 0.0,
                "currency": "EUR",
                "user_id": user_id,
                "owner": "admin"
            }
            wallet = await CreateLaiaBaseModel.create_laia_base_model(wallet_data, Wallet, ['admin'], repository)
        else:
            wallet = wallets['items'][0]

        # Get last 10 transactions
        transactions = await SearchLaiaBaseModel.search_laia_base_model(0, 10, {"user_id": user_id}, {"created_at": -1}, Transaction, ['admin'], repository)
        
        return {
            "balance": wallet.get("balance", 0.0),
            "currency": wallet.get("currency", "EUR"),
            "transactions": transactions.get('items', [])
        }

    @router.post("/topup")
    async def topup(request: TopUpRequest, user_id: str = Depends(get_current_user_id)):
        if request.amount <= 0:
            raise HTTPException(status_code=400, detail="Amount must be positive")

        wallets = await SearchLaiaBaseModel.search_laia_base_model(0, 1, {"user_id": user_id}, [], Wallet, ['admin'], repository)
        if not wallets['items']:
             raise HTTPException(status_code=404, detail="Wallet not found")
        
        wallet = wallets['items'][0]
        wallet_id = str(wallet.get('_id') or wallet.get('id'))
        new_balance = wallet.get("balance", 0.0) + request.amount

        await UpdateLaiaBaseModel.update_laia_base_model(wallet_id, {"balance": new_balance}, Wallet, ['admin'], repository)

        # Create transaction
        await CreateLaiaBaseModel.create_laia_base_model({
            "user_id": user_id,
            "amount": request.amount,
            "type": "topup",
            "description": request.description,
            "created_at": datetime.datetime.utcnow().isoformat(),
            "owner": "admin"
        }, Transaction, ['admin'], repository)

        return {"new_balance": new_balance}

    @router.post("/send")
    async def send_money(request: SendRequest, user_id: str = Depends(get_current_user_id)):
        if request.amount <= 0:
            raise HTTPException(status_code=400, detail="Amount must be positive")

        # Get sender wallet
        sender_wallets = await SearchLaiaBaseModel.search_laia_base_model(0, 1, {"user_id": user_id}, [], Wallet, ['admin'], repository)
        if not sender_wallets['items']:
            raise HTTPException(status_code=404, detail="Sender wallet not found")
        
        sender_wallet = sender_wallets['items'][0]
        if sender_wallet.get("balance", 0.0) < request.amount:
            raise HTTPException(status_code=400, detail="Insufficient balance")

        # Get recipient
        recipients = await SearchLaiaBaseModel.search_laia_base_model(0, 1, {"email": request.recipient_email}, [], User, ['admin'], repository)
        if not recipients['items']:
            raise HTTPException(status_code=404, detail="Recipient user not found")
        
        recipient_user = recipients['items'][0]
        recipient_id = str(recipient_user.get('_id') or recipient_user.get('id'))

        # Get recipient wallet
        recipient_wallets = await SearchLaiaBaseModel.search_laia_base_model(0, 1, {"user_id": recipient_id}, [], Wallet, ['admin'], repository)
        if not recipient_wallets['items']:
            # Create recipient wallet if missing
            recipient_wallet_data = {
                "address": f"W-{recipient_id[:8]}",
                "balance": 0.0,
                "currency": "USD",
                "user_id": recipient_id,
                "owner": "admin"
            }
            recipient_wallet = await CreateLaiaBaseModel.create_laia_base_model(recipient_wallet_data, Wallet, ['admin'], repository)
        else:
            recipient_wallet = recipient_wallets['items'][0]

        # Update balances
        sender_new_balance = sender_wallet.get("balance", 0.0) - request.amount
        recipient_new_balance = recipient_wallet.get("balance", 0.0) + request.amount

        await UpdateLaiaBaseModel.update_laia_base_model(str(sender_wallet.get('_id') or sender_wallet.get('id')), {"balance": sender_new_balance}, Wallet, ['admin'], repository)
        await UpdateLaiaBaseModel.update_laia_base_model(str(recipient_wallet.get('_id') or recipient_wallet.get('id')), {"balance": recipient_new_balance}, Wallet, ['admin'], repository)

        # Create transactions
        now = datetime.datetime.utcnow().isoformat()
        await CreateLaiaBaseModel.create_laia_base_model({
            "user_id": user_id,
            "amount": -request.amount,
            "type": "send",
            "description": request.description,
            "counterparty": request.recipient_email,
            "created_at": now,
            "owner": "admin"
        }, Transaction, ['admin'], repository)

        await CreateLaiaBaseModel.create_laia_base_model({
            "user_id": recipient_id,
            "amount": request.amount,
            "type": "receive",
            "description": f"From {user_id}", # Could be sender email
            "counterparty": user_id,
            "created_at": now,
            "owner": "admin"
        }, Transaction, ['admin'], repository)

        return {"new_balance": sender_new_balance}

    @router.post("/pay")
    async def pay(request: PayRequest, user_id: str = Depends(get_current_user_id)):
        if request.amount <= 0:
            raise HTTPException(status_code=400, detail="Amount must be positive")

        wallets = await SearchLaiaBaseModel.search_laia_base_model(0, 1, {"user_id": user_id}, [], Wallet, ['admin'], repository)
        if not wallets['items']:
             raise HTTPException(status_code=404, detail="Wallet not found")
        
        wallet = wallets['items'][0]
        if wallet.get("balance", 0.0) < request.amount:
            raise HTTPException(status_code=400, detail="Insufficient balance")

        new_balance = wallet.get("balance", 0.0) - request.amount
        await UpdateLaiaBaseModel.update_laia_base_model(str(wallet.get('_id') or wallet.get('id')), {"balance": new_balance}, Wallet, ['admin'], repository)

        # Create transaction
        await CreateLaiaBaseModel.create_laia_base_model({
            "user_id": user_id,
            "amount": -request.amount,
            "type": "payment",
            "description": f"Payment to {request.merchant}",
            "created_at": datetime.datetime.utcnow().isoformat(),
            "owner": "admin"
        }, Transaction, ['admin'], repository)

        return {"new_balance": new_balance}

    @router.get("/transactions")
    async def get_transactions(limit: int = 20, offset: int = 0, user_id: str = Depends(get_current_user_id)):
        transactions = await SearchLaiaBaseModel.search_laia_base_model(offset, limit, {"user_id": user_id}, {"created_at": -1}, Transaction, ['admin'], repository)
        return transactions.get('items', [])

    # Shops nearby route
    @router.get("/shops/nearby")
    async def get_nearby_shops(lat: float, lng: float, radius: float = 100, limit: int = 40):
        print(f"--- FETCHING SHOPS: lat={lat}, lng={lng}, radius={radius}, limit={limit} ---")
        
        # Clamp limit between 1 and 50 to protect memory
        max_limit = min(max(1, limit), 50)
        
        filters = {
            "location": {
                "$geoWithin": {
                    "$centerSphere": [
                        [lng, lat], 
                        radius / 6378137.0
                    ]
                }
            }
        }
        
        try:
            # Sync Pymongo calls (since motor is not installed)
            cursor = repository.db["shops"].find(filters).limit(max_limit)
            items = []
            for doc in cursor:
                # Convert MongoDB _id to string for JSON compatibility
                doc["id"] = str(doc.pop("_id"))
                items.append(doc)
            
            # Return only actual nearby shops without global fallback
            print(f"--- SUCCESS: Found {len(items)} shops ---")
            return items
        except Exception as e:
            print(f"--- DATABASE ERROR: {e} ---")
            return []

    return router

def get_user_router(repository: ModelRepository):
    router = APIRouter(prefix="/users", tags=["User"])

    @router.post("/register", response_model=UserResponse)
    async def create_user(user: User):
        # Convertir el modelo Pydantic a dict
        user_data = user.model_dump()

        # Filtrar campos vacíos o None, especialmente id
        filtered_data = {}
        for key, value in user_data.items():
            if value is not None and value != '' and value != []:
                # Si es password y es SecretStr, extraer el valor y cifrarlo
                if key == 'password' and hasattr(value, 'get_secret_value'):
                    plain_password = value.get_secret_value()
                    filtered_data[key] = bcrypt.hashpw(plain_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                else:
                    filtered_data[key] = value

        # Asegurarse de que no se envíe id, pero asignar owner por defecto
        filtered_data.pop('id', None)
        if 'owner' not in filtered_data or filtered_data['owner'] is None or filtered_data['owner'] == '':
            filtered_data['owner'] = 'admin'

        # Crear el usuario con los datos filtrados
        result = await CreateLaiaBaseModel.create_laia_base_model(filtered_data, User, ['admin'], repository)
        
        # Extraer los datos limpiamente para evitar referencias circulares
        safe_user_data = dict(result) if isinstance(result, dict) else result.model_dump(by_alias=True)
        
        return UserResponse(
            id=str(safe_user_data.get('_id', '')),
            owner=safe_user_data.get('owner', 'admin'),
            name=safe_user_data.get('name', ''),
            surnames=safe_user_data.get('surnames', None),
            email=safe_user_data.get('email', ''),
            phone=safe_user_data.get('phone', None)
        )

    @router.get("/", response_model=list[UserResponse])
    async def get_all_users():
        users = await SearchLaiaBaseModel.search_laia_base_model(0, 1000, {}, [], User, ['admin'], repository)
        return users.get('items', [])

    return router
                    
""" 
**************************************************************************
Instructions to develop new routes
**************************************************************************

- Import models from the models file with: 
from .models import modelName1, modelName2

- To operate with the crud operations on the models here are examples of the usage:
await CreateLaiaBaseModel.create_laia_base_model(dict(element), modelName1, user_roles, repository)
await UpdateLaiaBaseModel.update_laia_base_model(element_id, values, modelName1, user_roles, repository)
await ReadLaiaBaseModel.read_laia_base_model(element_id, modelName1, user_roles, repository)
await DeleteLaiaBaseModel.delete_laia_base_model(element_id, modelName1, user_roles, repository)
await SearchLaiaBaseModel.search_laia_base_model(skip, limit, filters, orders, modelName1, user_roles, repository)
"""