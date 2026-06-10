from fastapi import APIRouter, Depends, HTTPException, status, Header, WebSocket, WebSocketDisconnect
from laiagenlib.Domain.LaiaBaseModel.ModelRepository import ModelRepository
from laiagenlib.Application.LaiaBaseModel import ReadLaiaBaseModel, CreateLaiaBaseModel, DeleteLaiaBaseModel, SearchLaiaBaseModel, UpdateLaiaBaseModel
from laiagenlib.Application.LaiaUser import JWTToken
from .models import User, Wallet, Transaction, Shop
from pydantic import BaseModel, Field, SecretStr
from typing import Optional, List
import datetime
import os
import json
import asyncio
from pathlib import Path
from bson import ObjectId


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

    async def safe_create_laia_base_model(new_element, model, user_roles, repository):
        import inspect
        func = CreateLaiaBaseModel.create_laia_base_model
        sig = inspect.signature(func)
        kwargs = {
            "new_element": new_element,
            "model": model,
            "user_roles": user_roles,
            "repository": repository
        }
        if "use_access_rights" in sig.parameters:
            kwargs["use_access_rights"] = False
        return await func(**kwargs)

    async def safe_update_laia_base_model(element_id, updated_values, model, user_roles, repository):
        import inspect
        func = UpdateLaiaBaseModel.update_laia_base_model
        sig = inspect.signature(func)
        kwargs = {
            "element_id": element_id,
            "updated_values": updated_values,
            "model": model,
            "user_roles": user_roles,
            "repository": repository
        }
        if "use_access_rights" in sig.parameters:
            kwargs["use_access_rights"] = False
        return await func(**kwargs)

    @router.get("/", response_model=WalletResponse)
    async def get_wallet(user_id: str = Depends(get_current_user_id)):
        # Find wallet for user
        wallets = await SearchLaiaBaseModel.search_laia_base_model(0, 1, {"user_id": user_id}, [], Wallet, ['admin'], repository)
        if not wallets['items']:
            # Create a wallet if it doesn't exist
            wallet_data = {
                "name": f"Wallet-{user_id[:8]}",
                "address": f"W-{user_id[:8]}",
                "balance": 0.0,
                "currency": "EUR",
                "user_id": user_id,
                "owner": user_id
            }
            wallet = await safe_create_laia_base_model(wallet_data, Wallet, ['admin'], repository)
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

        await safe_update_laia_base_model(wallet_id, {"balance": new_balance}, Wallet, ['admin'], repository)

        # Create transaction
        await safe_create_laia_base_model({
            "name": f"Recarga-{request.amount}EUR",
            "user_id": user_id,
            "amount": request.amount,
            "type": "topup",
            "description": request.description,
            "created_at": datetime.datetime.utcnow().isoformat(),
            "owner": user_id
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
                "name": f"Wallet-{recipient_id[:8]}",
                "address": f"W-{recipient_id[:8]}",
                "balance": 0.0,
                "currency": "EUR",
                "user_id": recipient_id,
                "owner": recipient_id
            }
            recipient_wallet = await safe_create_laia_base_model(recipient_wallet_data, Wallet, ['admin'], repository)
        else:
            recipient_wallet = recipient_wallets['items'][0]

        # Update balances
        sender_new_balance = sender_wallet.get("balance", 0.0) - request.amount
        recipient_new_balance = recipient_wallet.get("balance", 0.0) + request.amount

        await safe_update_laia_base_model(str(sender_wallet.get('_id') or sender_wallet.get('id')), {"balance": sender_new_balance}, Wallet, ['admin'], repository)
        await safe_update_laia_base_model(str(recipient_wallet.get('_id') or recipient_wallet.get('id')), {"balance": recipient_new_balance}, Wallet, ['admin'], repository)

        # Fetch sender user info for description
        sender_user = repository.db["user"].find_one({"_id": ObjectId(user_id)})
        sender_name = sender_user.get("name", "Alguien") if sender_user else "Alguien"
        sender_email = sender_user.get("email", "") if sender_user else ""

        # Create transactions
        now = datetime.datetime.utcnow().isoformat()
        await safe_create_laia_base_model({
            "name": f"Envio-{request.amount}EUR",
            "user_id": user_id,
            "amount": -request.amount,
            "type": "send",
            "description": f"A {request.recipient_email}" if not request.description or request.description == "Transfer" else request.description,
            "counterparty": request.recipient_email,
            "created_at": now,
            "owner": user_id
        }, Transaction, ['admin'], repository)

        await safe_create_laia_base_model({
            "name": f"Recepcion-{request.amount}EUR",
            "user_id": recipient_id,
            "amount": request.amount,
            "type": "receive",
            "description": f"De {sender_name}",
            "counterparty": sender_email if sender_email else user_id,
            "created_at": now,
            "owner": recipient_id
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
        await safe_update_laia_base_model(str(wallet.get('_id') or wallet.get('id')), {"balance": new_balance}, Wallet, ['admin'], repository)

        # Create transaction
        await safe_create_laia_base_model({
            "name": f"Pago-{request.amount}EUR",
            "user_id": user_id,
            "amount": -request.amount,
            "type": "payment",
            "description": f"Pago a {request.merchant}",
            "created_at": datetime.datetime.utcnow().isoformat(),
            "owner": user_id
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

    @router.get("/api/chat/conversations/{user_id}", openapi_extra={})
    async def get_api_chat_conversations_user_id():
        return {"message": "This is an extra route!"}

    @router.get("/api/chat/history/{user_id}/{other_user_id}", openapi_extra={})
    async def get_api_chat_history_user_id_other_user_id():
        return {"message": "This is an extra route!"}

    @router.post("/api/contacts/add", openapi_extra={})
    async def post_api_contacts_add():
        return {"message": "This is an extra route!"}

    @router.get("/api/contacts/{user_id}", openapi_extra={})
    async def get_api_contacts_user_id():
        return {"message": "This is an extra route!"}

    @router.get("/api/users/search", openapi_extra={})
    async def get_api_users_search():
        return {"message": "This is an extra route!"}

    @router.post("/wallet/pay", openapi_extra={})
    async def post_wallet_pay():
        return {"message": "This is an extra route!"}

    @router.post("/wallet/send", openapi_extra={})
    async def post_wallet_send():
        return {"message": "This is an extra route!"}

    @router.get("/wallet/shops/nearby", openapi_extra={})
    async def get_wallet_shops_nearby():
        return {"message": "This is an extra route!"}

    @router.post("/wallet/topup", openapi_extra={})
    async def post_wallet_topup():
        return {"message": "This is an extra route!"}

    @router.get("/wallet/transactions", openapi_extra={})
    async def get_wallet_transactions():
        return {"message": "This is an extra route!"}

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

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    def is_user_online(self, user_id: str) -> bool:
        return user_id in self.active_connections

    async def send_personal_message(self, message: dict, receiver_id: str):
        if receiver_id in self.active_connections:
            for connection in self.active_connections[receiver_id]:
                try:
                    await connection.send_json(message)
                except Exception:
                    pass

manager = ConnectionManager()

def ChatRoutes(db):
    router = APIRouter(tags=["Chat"])

    @router.websocket("/api/ws/chat/{user_id}")
    async def websocket_endpoint(websocket: WebSocket, user_id: str):
        await manager.connect(user_id, websocket)
        try:
            while True:
                data = await websocket.receive_text()
                try:
                    message_data = json.loads(data)
                except json.JSONDecodeError:
                    continue
                
                receiver_id = message_data.get("receiver_id")
                msg_text = message_data.get("message")

                if receiver_id and msg_text:
                    payload = {
                        "sender_id": user_id,
                        "receiver_id": receiver_id,
                        "message": msg_text,
                        "timestamp": datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat(),
                    }

                    try:
                        await asyncio.to_thread(db["chat_messages"].insert_one, payload.copy())
                    except Exception as db_err:
                        print(f"Error persisting chat message: {db_err}")

                    await manager.send_personal_message(payload, receiver_id)
                    await manager.send_personal_message(payload, user_id)
        except WebSocketDisconnect:
            manager.disconnect(user_id, websocket)
        except Exception as e:
            print(f"WebSocket error for user {user_id}: {e}")
            manager.disconnect(user_id, websocket)

    @router.get("/api/chat/status/{user_id}")
    async def get_user_status(user_id: str):
        return {"user_id": user_id, "is_online": manager.is_user_online(user_id)}

    @router.get("/api/chat/history/{user_id}/{other_user_id}")
    async def get_chat_history(user_id: str, other_user_id: str):
        try:
            query = {
                "$or": [
                    {"sender_id": user_id, "receiver_id": other_user_id},
                    {"sender_id": other_user_id, "receiver_id": user_id}
                ]
            }
            cursor = db["chat_messages"].find(query).sort("timestamp", 1)
            messages = []
            for doc in cursor:
                doc["id"] = str(doc.pop("_id"))
                messages.append(doc)
            return messages
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    @router.get("/api/users/search")
    async def search_users(query: str, exclude_user_id: Optional[str] = None):
        try:
            from bson import ObjectId
            regex_query = {"$regex": query, "$options": "i"}
            search_filter = {
                "$or": [
                    {"name": regex_query},
                    {"email": regex_query}
                ]
            }
            if exclude_user_id:
                try:
                    search_filter["_id"] = {"$ne": ObjectId(exclude_user_id)}
                except Exception:
                    search_filter["_id"] = {"$ne": exclude_user_id}
            
            cursor = db["user"].find(search_filter).limit(20)
            users = []
            for doc in cursor:
                doc["id"] = str(doc.pop("_id"))
                doc.pop("password", None)
                users.append(doc)
            return users
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    class AddContactRequest(BaseModel):
        user_id: str
        email_or_name: str

    @router.post("/api/contacts/add")
    async def add_contact(request: AddContactRequest):
        try:
            from bson import ObjectId
            # Search for the user we want to add
            regex_query = {"$regex": f"^{request.email_or_name}$", "$options": "i"}
            target_user = db["user"].find_one({
                "$or": [
                    {"email": regex_query},
                    {"name": regex_query}
                ]
            })
            
            if not target_user:
                # If exact match failed, try substring match
                target_user = db["user"].find_one({
                    "$or": [
                        {"email": {"$regex": request.email_or_name, "$options": "i"}},
                        {"name": {"$regex": request.email_or_name, "$options": "i"}}
                    ]
                })

            if not target_user:
                raise HTTPException(status_code=404, detail="Usuario no encontrado")

            target_user_id = str(target_user["_id"])
            if target_user_id == request.user_id:
                raise HTTPException(status_code=400, detail="No puedes agregarte a ti mismo como contacto")

            # Create bidirectional contact entries
            existing_1 = db["contacts"].find_one({"user_id": request.user_id, "contact_id": target_user_id})
            if not existing_1:
                db["contacts"].insert_one({
                    "user_id": request.user_id,
                    "contact_id": target_user_id,
                    "created_at": datetime.datetime.utcnow().isoformat()
                })

            existing_2 = db["contacts"].find_one({"user_id": target_user_id, "contact_id": request.user_id})
            if not existing_2:
                db["contacts"].insert_one({
                    "user_id": target_user_id,
                    "contact_id": request.user_id,
                    "created_at": datetime.datetime.utcnow().isoformat()
                })

            return {"status": "success", "message": "Contacto agregado correctamente", "contact": {
                "id": target_user_id,
                "name": target_user.get("name"),
                "email": target_user.get("email")
            }}
        except HTTPException as he:
            raise he
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    @router.get("/api/contacts/{user_id}")
    async def get_contacts(user_id: str):
        try:
            from bson import ObjectId
            cursor = db["contacts"].find({"user_id": user_id})
            contacts = []
            for doc in cursor:
                contact_id = doc["contact_id"]
                try:
                    target_user = db["user"].find_one({"_id": ObjectId(contact_id)})
                except Exception:
                    target_user = db["user"].find_one({"_id": contact_id})
                
                if target_user:
                    contacts.append({
                        "id": str(target_user["_id"]),
                        "name": target_user.get("name"),
                        "email": target_user.get("email"),
                        "surnames": target_user.get("surnames"),
                        "phone": target_user.get("phone")
                    })
            return contacts
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    @router.get("/api/chat/conversations/{user_id}")
    async def get_conversations(user_id: str):
        try:
            from bson import ObjectId
            query = {
                "$or": [
                    {"sender_id": user_id},
                    {"receiver_id": user_id}
                ]
            }
            cursor = db["chat_messages"].find(query).sort("timestamp", 1)
            
            conversations_map = {}
            for doc in cursor:
                sender_id = doc.get("sender_id")
                receiver_id = doc.get("receiver_id")
                
                other_user_id = receiver_id if sender_id == user_id else sender_id
                if not other_user_id:
                    continue
                
                conversations_map[other_user_id] = {
                    "message": doc.get("message"),
                    "timestamp": doc.get("timestamp")
                }
            
            results = []
            for other_user_id, msg_info in conversations_map.items():
                try:
                    other_user = db["user"].find_one({"_id": ObjectId(other_user_id)})
                except Exception:
                    other_user = db["user"].find_one({"_id": other_user_id})
                
                if other_user:
                    results.append({
                        "contactId": other_user_id,
                        "name": other_user.get("name"),
                        "email": other_user.get("email"),
                        "last_message": msg_info["message"],
                        "timestamp": msg_info["timestamp"]
                    })
            
            results.sort(key=lambda x: x["timestamp"], reverse=True)
            return results
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    return router


def BonusRoutes(repository: ModelRepository):
    router = APIRouter(prefix="/api/bonuses", tags=["Bonuses"])

    @router.get("/templates", response_model=List[dict])
    async def get_templates():
        try:
            # Fetch available templates from DB
            cursor = repository.db["bonustemplate"].find()
            templates = list(cursor)
            if not templates:
                # Seed mock municipal templates
                seed_data = [
                    {
                        "title": "Bono Sants-Montjuïc",
                        "cost_price": 10.0,
                        "spending_value": 20.0,
                        "expiration_date": "2026-10-12T23:59:59Z",
                        "owner": "admin"
                    },
                    {
                        "title": "Bono Forn de Gràcia",
                        "cost_price": 15.0,
                        "spending_value": 25.0,
                        "expiration_date": "2026-09-30T23:59:59Z",
                        "owner": "admin"
                    },
                    {
                        "title": "Bono Huerto Urbano",
                        "cost_price": 5.0,
                        "spending_value": 12.0,
                        "expiration_date": "2026-12-31T23:59:59Z",
                        "owner": "admin"
                    }
                ]
                for item in seed_data:
                    repository.db["bonustemplate"].insert_one(item)
                cursor = repository.db["bonustemplate"].find()
                templates = list(cursor)

            for doc in templates:
                doc["id"] = str(doc.pop("_id"))
            return templates
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    @router.post("/buy/{template_id}")
    async def buy_bonus(template_id: str, user_id: str = Depends(get_current_user_id)):
        from bson import ObjectId
        import uuid

        # Retrieve the template
        try:
            template_oid = ObjectId(template_id)
            template = repository.db["bonustemplate"].find_one({"_id": template_oid})
        except Exception:
            template = repository.db["bonustemplate"].find_one({"_id": template_id})

        if not template:
            raise HTTPException(status_code=404, detail="Bono no encontrado")

        cost_price = float(template["cost_price"])

        # Fetch user's wallet
        wallet = repository.db["wallet"].find_one({"user_id": user_id})
        if not wallet:
            # Create a wallet if it doesn't exist (with 0 balance)
            wallet_data = {
                "address": f"W-{user_id[:8]}",
                "balance": 0.0,
                "currency": "EUR",
                "user_id": user_id,
                "owner": "admin"
            }
            repository.db["wallet"].insert_one(wallet_data)
            wallet = wallet_data

        current_balance = float(wallet.get("balance", 0.0))
        if current_balance < cost_price:
            raise HTTPException(status_code=400, detail="Saldo insuficiente en la billetera")

        # Update wallet balance
        new_balance = current_balance - cost_price
        repository.db["wallet"].update_one(
            {"_id": wallet["_id"]},
            {"$set": {"balance": new_balance}}
        )

        # Create user bonus entry
        qr_token = str(uuid.uuid4())
        purchased_at = datetime.datetime.utcnow().isoformat() + "Z"
        user_bonus_data = {
            "user_id": user_id,
            "bonus_template_id": str(template.get("_id") or template.get("id")),
            "status": "active",
            "qr_token": qr_token,
            "purchased_at": purchased_at,
            "owner": "admin"
        }
        repository.db["userbonus"].insert_one(user_bonus_data)

        # Create transaction log
        transaction_data = {
            "user_id": user_id,
            "amount": -cost_price,
            "type": "payment",
            "description": f"Compra de {template['title']}",
            "created_at": datetime.datetime.utcnow().isoformat(),
            "owner": "admin"
        }
        repository.db["transaction"].insert_one(transaction_data)

        return {
            "status": "success",
            "message": "Bono adquirido correctamente",
            "new_balance": new_balance,
            "qr_token": qr_token
        }

    @router.get("/my-bonuses/{target_user_id}", response_model=List[dict])
    async def get_my_bonuses(target_user_id: str, user_id: str = Depends(get_current_user_id)):
        from bson import ObjectId
        # Enforce that the user is fetching their own bonuses (or admin)
        if user_id != target_user_id:
            raise HTTPException(status_code=403, detail="No tienes permiso para ver estos bonos")

        cursor = repository.db["userbonus"].find({"user_id": target_user_id})
        user_bonuses = list(cursor)

        results = []
        for ub in user_bonuses:
            ub_id = str(ub.pop("_id"))
            template_id = ub.get("bonus_template_id")
            
            # Fetch template details to embed in the response
            try:
                template_oid = ObjectId(template_id)
                template = repository.db["bonustemplate"].find_one({"_id": template_oid})
            except Exception:
                template = repository.db["bonustemplate"].find_one({"_id": template_id})
            
            if template:
                template["id"] = str(template.pop("_id"))
                ub["template"] = template
            else:
                ub["template"] = None
                
            ub["id"] = ub_id
            results.append(ub)

        return results

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