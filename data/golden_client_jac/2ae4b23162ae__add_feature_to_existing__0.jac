def fetch_users -> list {
    return [];
}

def fetch_orders -> list {
    return [];
}

def fetch_inventory -> list {
    return [];
}

# New parallel data source
def fetch_shipments -> list {
    return [];
}

def process_local_data {
    # Process local data here
}

with entry {
    future1 = flow fetch_users();
    future2 = flow fetch_orders();
    future3 = flow fetch_inventory();
    future4 = flow fetch_shipments();

    process_local_data();

    users = wait future1;
    orders = wait future2;
    inventory = wait future3;
    shipments = wait future4;
}
