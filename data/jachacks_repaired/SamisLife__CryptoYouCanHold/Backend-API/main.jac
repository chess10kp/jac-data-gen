import json;
import os;
import time;
import fastapi;
import uvicorn;
import from byllm.lib { Model }

glob DB_FILE = "db.json";
glob app = fastapi.FastAPI(title="Physical Crypto API");

# ==========================================
# 1. NATIVE GEMINI AI INTEGRATION
# ==========================================
glob llm = Model(model_name="gemini/gemini-2.5-flash");

# NEW: We define the exact structure we want Gemini to guarantee!
obj RiskAssessment {
    has score: int;
    has reason: str;
}

# Notice it now returns the strictly typed RiskAssessment object
def assess_fraud_risk(history: list) -> RiskAssessment by llm();
sem assess_fraud_risk = "Analyze the transaction history list and return a RiskAssessment with an integer 'score' (0-100) and a string 'reason' for the fraud risk. 0 is perfectly safe, 100 is highly suspicious. Rapid successive transfers or lack of history increases risk.";


# ==========================================
# 2. DB HELPERS 
# ==========================================
def load_db() -> dict {
    if not os.path.exists(DB_FILE) {
        return {"coins": {}, "wallets": {"wallet_person_1": {"BTC": 2.45, "ETH": 14.2}, "wallet_person_2": {"BTC": 0.0, "ETH": 0.0}}, "history": {}};
    }
    with open(DB_FILE, "r") as f {
        try {
            db = json.load(f);
            if "history" not in db { db["history"] = {}; }
            for coin_id in db["coins"] {
                if "pending_transfer_to" not in db["coins"][coin_id] {
                    db["coins"][coin_id]["pending_transfer_to"] = None;
                }
            }
            return db;
        } except Exception as e { return {"coins": {}, "wallets": {"wallet_person_1": {"BTC": 2.45, "ETH": 14.2}, "wallet_person_2": {"BTC": 0.0, "ETH": 0.0}}, "history": {}}; }
    }
}

def save_db(data: dict) {
    with open(DB_FILE, "w") as f { json.dump(data, f, indent=4); }
}

# ==========================================
# 3. ENDPOINTS
# ==========================================
@app.post("/coins/", status_code=201)
def create_coin(payload: dict = fastapi.Body()) -> dict {
    db = load_db();
    coin_id = payload["coin_id"];
    wallet_id = payload["wallet_id"];
    symbol = payload["symbol"];
    amount = payload["amount"];
    
    if coin_id in db["coins"] { raise fastapi.HTTPException(status_code=400, detail="Coin ID already exists."); }
    
    wallet_data = db["wallets"].get(wallet_id, {});
    if symbol not in wallet_data { wallet_data[symbol] = 0.0; }
    wallet_data[symbol] -= amount;
    db["wallets"][wallet_id] = wallet_data;

    db["coins"][coin_id] = {
        "coin_id": coin_id, "wallet_id": wallet_id, "asset_name": payload["asset_name"],
        "symbol": symbol, "amount": amount, "disabled": False, "transferrable": False,
        "transfer_start_timestamp": None, "pending_transfer_to": None
    };
    save_db(db);
    return {"message": "Hardware coin initialized", "coin": db["coins"][coin_id]};
}

@app.get("/coins/{coin_id}")
def get_coin(coin_id: str) -> dict {
    db = load_db();
    if coin_id not in db["coins"] { raise fastapi.HTTPException(status_code=404, detail="Coin not found."); }
    return db["coins"][coin_id];
}

@app.delete("/coins/{coin_id}")
def delete_coin(coin_id: str) -> dict {
    db = load_db();
    if coin_id not in db["coins"] {
        raise fastapi.HTTPException(status_code=404, detail="Coin not found.");
    }
    
    deleted_coin = db["coins"].pop(coin_id);
    
    wallet_data = db["wallets"].get(deleted_coin["wallet_id"], {});
    if deleted_coin["symbol"] not in wallet_data {
        wallet_data[deleted_coin["symbol"]] = 0.0;
    }
        
    wallet_data[deleted_coin["symbol"]] += deleted_coin["amount"];
    db["wallets"][deleted_coin["wallet_id"]] = wallet_data;
    
    save_db(db);
    return {"message": "Coin deleted, funds refunded"};
}

@app.put("/coins/{coin_id}/status")
def toggle_status(coin_id: str, disabled: bool) -> dict {
    db = load_db();
    if coin_id not in db["coins"] {
        raise fastapi.HTTPException(status_code=404, detail="Coin not found.");
    }
    
    db["coins"][coin_id]["disabled"] = disabled;
    if disabled {
        db["coins"][coin_id]["transferrable"] = False;
        db["coins"][coin_id]["transfer_start_timestamp"] = None;
    }
        
    save_db(db);
    state = "Disabled" if disabled else "Active";
    return {"message": f"Coin is now {state}"};
}

@app.put("/coins/{coin_id}/transfer_mode")
def unlock_transfer_mode(coin_id: str) -> dict {
    db = load_db();
    if coin_id not in db["coins"] { raise fastapi.HTTPException(status_code=404, detail="Coin not found."); }
    if db["coins"][coin_id].get("disabled") { raise fastapi.HTTPException(status_code=403, detail="Cannot unlock disabled coin."); }
    db["coins"][coin_id]["transferrable"] = True;
    db["coins"][coin_id]["transfer_start_timestamp"] = time.time();
    save_db(db);
    return {"message": "Transfer mode unlocked."};
}

# ===== HARDWARE STEP 1: THE TAP =====
@app.post("/coins/tap")
def tap_coin(payload: dict = fastapi.Body()) -> dict {
    db = load_db();
    coin_id = payload["coin_id"];
    dest = payload["destination_wallet"];
    
    if coin_id not in db["coins"] { raise fastapi.HTTPException(status_code=404, detail="Invalid physical coin."); }
    coin_data = db["coins"][coin_id];
    
    if coin_data.get("disabled") or not coin_data.get("transferrable") { raise fastapi.HTTPException(status_code=403, detail="Coin locked."); }
    
    coin_data["pending_transfer_to"] = dest;
    save_db(db);
    return {"status": "PENDING_CONFIRMATION"};
}

# ===== IPHONE STEP 2: THE CONFIRMATION =====
@app.post("/coins/transfer/confirm")
def confirm_transfer(payload: dict = fastapi.Body()) -> dict {
    db = load_db();
    coin_id = payload["coin_id"];
    coin_data = db["coins"][coin_id];
    destination_wallet = coin_data["pending_transfer_to"];
    
    if not destination_wallet { raise fastapi.HTTPException(status_code=400, detail="No pending transfer."); }
    
    if destination_wallet not in db["history"] { db["history"][destination_wallet] = []; }
    db["history"][destination_wallet].append({
        "action": "RECEIVED_PHYSICAL_COIN", "symbol": coin_data["symbol"],
        "amount": coin_data["amount"], "from_wallet": coin_data["wallet_id"], "timestamp": time.time()
    });
    
    coin_data["wallet_id"] = destination_wallet;
    coin_data["transferrable"] = False;
    coin_data["transfer_start_timestamp"] = None;
    coin_data["pending_transfer_to"] = None;
    
    db["coins"][coin_id] = coin_data;
    save_db(db);
    return {"status": "SUCCESS"};
}

# ===== IPHONE STEP 2: THE CANCEL =====
@app.post("/coins/transfer/cancel")
def cancel_transfer(payload: dict = fastapi.Body()) -> dict {
    db = load_db();
    coin_id = payload["coin_id"];
    db["coins"][coin_id]["pending_transfer_to"] = None;
    save_db(db);
    return {"status": "CANCELLED"};
}

@app.get("/coins/wallet/{wallet_id}")
def get_wallet_coins(wallet_id: str) -> list {
    db = load_db();
    res = [];
    for coin_id in db["coins"] {
        if db["coins"][coin_id].get("wallet_id") == wallet_id { res.append(db["coins"][coin_id]); }
    }
    return res;
}

@app.get("/wallets/{wallet_id}")
def get_wallet_balances(wallet_id: str) -> dict {
    db = load_db();
    return db["wallets"].get(wallet_id, {"BTC": 0.0, "ETH": 0.0});
}

@app.get("/wallets/{wallet_id}/risk")
def get_wallet_risk(wallet_id: str) -> dict {
    db = load_db();
    history = db["history"].get(wallet_id, []);
    
    if len(history) == 0 { 
        return {"score": 50, "reason": "New or inactive wallet with no prior transaction history. Proceed with caution."}; 
    }
    
    # NEW: Call Gemini, get the strictly typed object, and convert it back to a standard dictionary for FastAPI to send to your iPhone
    ai_result = assess_fraud_risk(history);
    return {"score": ai_result.score, "reason": ai_result.reason};
}

with entry { uvicorn.run(app, host="0.0.0.0", port=8000); }