from laiagenlib.Infrastructure.Openapi.LaiaFastApi import LaiaFastApi
from laiagenlib.Infrastructure.Openapi.LaiaFlutter import LaiaFlutter
from laiagenlib.Infrastructure.LaiaBaseModel.MongoModelRepository import MongoModelRepository
from laiagenlib.Infrastructure.Openapi.FastAPIOpenapiRepository import FastAPIOpenapiRepository
from pymongo import MongoClient
from laiagenlib.Domain.LaiaBaseModel.LaiaBaseModel import LaiaBaseModel
# from laia_ontology_sync import start_background_watcher
import os
import uvicorn
import asyncio
import time
import requests
import yaml
import json
import threading
import inspect
import subprocess
import re
from dotenv import load_dotenv
from pathlib import Path
from fastapi.middleware.cors import CORSMiddleware

def load_config():
    load_dotenv()
    env = os.getenv("APP_ENV", "dev")  # 'dev' o 'prod'
    config_path = Path(__file__).resolve().parent.parent / "config" / f"{env}.json"

    if not config_path.exists():
        raise FileNotFoundError(f"No se encontró el archivo de configuración: {config_path}")

    with open(config_path, "r") as f:
        return json.load(f)

config = load_config()

# --- MongoDB ---
mongo_client_url = config["mongo"].get("url", "mongodb://localhost:27017")
mongo_database_name = config["mongo"].get("database", "test")

# --- JWT ---
backend_jwt_secret_key = config["jwt"].get("secret_key", "mysecret")
backend_jwt_refresh_secret_key = config["jwt"].get("refresh_secret_key", "mysecretrefresh")

# --- Server ---
backend_port = int(config["server"].get("port", 8005))
base_uri_prefix = config["server"].get("base_uri_prefix", "http://localhost:8005")

# --- Fuseki ---
fuseki_config = config.get("fuseki", {})
fuseki_base_url = fuseki_config.get("base_url", "")
fuseki_user = fuseki_config.get("user", "")
fuseki_pwd = fuseki_config.get("password", "")

# --- Storage ---
storage_config = config.get("storage", {})
storage_enabled = storage_config.get("enabled", False)
minio_root_user = storage_config.get("MINIO_ROOT_USER", "admin")
minio_root_password = storage_config.get("MINIO_ROOT_PASSWORD", "SH16FHqU1Npg3iu3gguXdC8vl")
minio_data_path = storage_config.get("MINIO_DATA_PATH", "./data")   
minio_api_port = storage_config.get("MINIO_API_PORT", 9000)
minio_console_port = storage_config.get("MINIO_CONSOLE_PORT", 9001)
minio_endpoint_url = storage_config.get("MINIO_ENDPOINT_URL", f"http://localhost:{minio_api_port}")

openapi_file_name = "openapi.yaml"
backend_folder_name = "Backend"
frontend_folder_name = "frontend"

client = MongoClient(mongo_client_url)
db = client[mongo_database_name]

base_path = Path(__file__).parent / "openapi"
base_file = base_path / "base.yaml"
schemas_dir = base_path / "schemas"
paths_dir = base_path / "paths"
output_file = Path(__file__).parent / "openapi.yaml"

with open(base_file, "r") as f:
    openapi_doc = yaml.safe_load(f)

openapi_doc.setdefault("components", {})
openapi_doc["components"].setdefault("schemas", {})
openapi_doc.setdefault("paths", {})

for filename in os.listdir(schemas_dir):
    if filename.endswith((".yaml", ".yml")):
        filepath = os.path.join(schemas_dir, filename)
        with open(filepath, "r") as f:
            schema = yaml.safe_load(f)
            if isinstance(schema, dict):
                openapi_doc["components"]["schemas"].update(schema)

for filename in os.listdir(paths_dir):
    if filename.endswith((".yaml", ".yml")):
        filepath = os.path.join(paths_dir, filename)
        with open(filepath, "r") as f:
            path_def = yaml.safe_load(f)
            if isinstance(path_def, dict):
                openapi_doc["paths"].update(path_def)

with open(output_file, "w") as f:
    yaml.dump(openapi_doc, f, sort_keys=False)

openapi_path = Path(__file__).parent / openapi_file_name

laia_config_path = Path(__file__).parent.parent / "laia.json"
with open(laia_config_path, "r", encoding="utf-8") as f:
    laia_config = json.load(f)


def build_laia_fastapi_kwargs():
    supported_params = set()
    try:
        supported_params.update(inspect.signature(LaiaFastApi).parameters.keys())
    except Exception:
        pass
    try:
        supported_params.update(inspect.signature(LaiaFastApi.__init__).parameters.keys())
    except Exception:
        pass

    kwargs = {
        "openapi": openapi_path,
        "backend_folder_name": backend_folder_name,
        "db": db,
        "repository": MongoModelRepository,
        "repositoryAPI": FastAPIOpenapiRepository,
        "jwtSecretKey": backend_jwt_secret_key,
    }

    if "jwtRefreshSecretKey" in supported_params:
        kwargs["jwtRefreshSecretKey"] = backend_jwt_refresh_secret_key
    if "use_ontology" in supported_params:
        kwargs["use_ontology"] = laia_config.get("use_ontology", False)
    if "use_access_rights" in supported_params:
        kwargs["use_access_rights"] = laia_config.get("use_access_rights", False)
    if "add_storage" in supported_params:
        kwargs["add_storage"] = storage_enabled

    return kwargs

def kill_port_owner(port: int):
    try:
        output = subprocess.check_output(f"netstat -ano | findstr :{port}", shell=True).decode()
        pids = set()
        for line in output.strip().split("\n"):
            parts = re.split(r'\s+', line.strip())
            if len(parts) >= 5 and parts[1].endswith(f":{port}"):
                pids.add(parts[-1])
        for pid in pids:
            if pid and pid != "0" and int(pid) != os.getpid():
                print(f"Auto-cleanup: Killing process {pid} using port {port}...")
                subprocess.run(f"taskkill /F /PID {pid}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

async def main():
    kill_port_owner(backend_port)
    app_instance = await LaiaFastApi(**build_laia_fastapi_kwargs())

    app = app_instance.api

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    from backend.routes import ExtraRoutes, ChatRoutes, BonusRoutes
    app.include_router(ExtraRoutes(app_instance.repository_instance))
    app.include_router(ChatRoutes(db))
    app.include_router(BonusRoutes(app_instance.repository_instance))

#    from backend.routes import get_user_router
#    app.include_router(get_user_router(app_instance.repository_instance))

    print("Registered routes:")
    for r in app.routes:
        print(f" - {getattr(r, 'path', '')} ({getattr(r, 'methods', '')})")

    import importlib.util
    import sys
    models_path = Path(__file__).parent / "backend" / "models.py"
    if models_path.exists():
        spec = importlib.util.spec_from_file_location("models", str(models_path))
        models = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(models)
        sys.modules["models"] = models

        for attr in dir(models):
            model_class = getattr(models, attr)
            if hasattr(model_class, "model_rebuild"):
                try:
                    model_class.model_rebuild()
                except Exception:
                    pass  
    else:
        print(f"❌ models.py not found at {models_path}")

    config = uvicorn.Config(app, host="0.0.0.0", port=backend_port)
    server = uvicorn.Server(config)

    await server.serve()

def run_server():
    asyncio.run(main())

MAX_RETRIES = 30
RETRY_INTERVAL = 1

if __name__ == "__main__":

    server_thread = threading.Thread(target=run_server, daemon=True)
    server_thread.start()

    ontology_enabled = laia_config.get("use_ontology", False)

    # if ontology_enabled:
    #     start_background_watcher(...)
    
    # Wait until Uvicorn actually starts serving before fetching OpenAPI
    time.sleep(5)

    try:
        response = requests.get(f"http://localhost:{backend_port}/openapi.json")
        if response.status_code == 200:
            openapi_yaml = yaml.dump(json.loads(response.text), default_flow_style=False)
            with open(openapi_path, "wb") as f: 
                f.write(openapi_yaml.encode("utf-8"))
            print("OpenAPI YAML file saved.")
        else:
            print(f"❌ Failed to retrieve OpenAPI YAML file: {response.status_code}")
    except Exception as e:
        print(f"❌ Error connecting to server: {e}")

    print("Server launched, waiting for interruption...", flush=True)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Stopping server...", flush=True)
        os._exit(0)