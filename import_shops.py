import csv
import json
import os
from pymongo import MongoClient, GEOSPHERE
from pathlib import Path

def import_shops():
    # MongoDB setup
    mongo_url = "mongodb://localhost:27017"
    db_name = "test"
    
    client = MongoClient(mongo_url)
    db = client[db_name]
    shops_col = db["shops"]
    
    # Clear existing shops to avoid duplicates if re-running
    shops_col.delete_many({})
    
    # Create 2dsphere index for location
    shops_col.create_index([("location", GEOSPHERE)])
    
    csv_path = Path("D:/TFG/241021_censcomercialbcn_opendata_2024_v5.csv")
    
    if not csv_path.exists():
        print(f"Error: Dataset not found at {csv_path}")
        return

    print(f"Importing shops from {csv_path}...")
    
    count = 0
    with open(csv_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        batch = []
        for row in reader:
            # Skip empty locals (Activity Code 0 usually means empty/closed)
            if row['Nom_Local'] == "SN" or row['Nom_Principal_Activitat'] == "Sense activitat":
                continue
                
            try:
                lat = float(row['Latitud'])
                lng = float(row['Longitud'])
                
                shop = {
                    "name": row['Nom_Local'],
                    "activity": row['Nom_Activitat'],
                    "category": row['Nom_Sector_Activitat'],
                    "address": row['Direccio_Unica'],
                    "neighborhood": row['Nom_Barri'],
                    "is_commercial_axis": row['SN_Eix'] == 'Si',
                    "location": {
                        "type": "Point",
                        "coordinates": [lng, lat]
                    },
                    "owner": "admin"
                }
                
                batch.append(shop)
                
                if len(batch) >= 500:
                    shops_col.insert_many(batch)
                    count += len(batch)
                    batch = []
                    print(f"  Inserted {count} shops...")
                    
            except (ValueError, TypeError):
                continue
        
        if batch:
            shops_col.insert_many(batch)
            count += len(batch)

    print(f"Finished! Total shops imported: {count}")

if __name__ == "__main__":
    import_shops()
