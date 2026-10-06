"""
nourish_api.jac
==========
Nourish — REST-style API endpoints for the frontend dashboard.
Uses def:priv so each authenticated user has their own isolated graph.
"""

import from datetime { datetime }

# ==================================================
# GRAPH MODEL
# ==================================================

edge Offers {}
edge AllocatedTo {}
edge AssignedVolunteer {}

node NourishHub {
    has name: str = "Nourish Hub";
}

node Business {
    has name:          str;
    has location:      str;
    has business_type: str;
    has contact:       str;
}

node Shelter {
    has name:             str;
    has location:         str;
    has current_capacity: int;
    has max_capacity:     int;
    has needed_items:     list[str];
}

node Donation {
    has food_type:     str;
    has quantity:      int;
    has expiry_time:   str;
    has business_name: str;
    has status:        str = "pending";
    has dispatched:    bool = False;
    has shelter_name:  str = "";
    has volunteer_name: str = "";
}

node Volunteer {
    has name:         str;
    has vehicle_type: str;
    has location:     str;
    has contact:      str;
    has is_available: bool = True;
}

# ==================================================
# RETURN TYPES (obj = plain in-memory, auto-serialized)
# ==================================================

obj DashboardStats {
    has businesses:          int;
    has shelters:            int;
    has pending_donations:   int;
    has matched_donations:   int;
    has volunteers_available: int;
    has total_kg_rescued:    int;
}

obj DonationInfo {
    has id:             str;
    has food_type:      str;
    has quantity:       int;
    has expiry_time:    str;
    has status:         str;
    has business_name:  str;
    has shelter_name:   str;
    has volunteer_name: str;
}

obj ShelterInfo {
    has id:               str;
    has name:             str;
    has location:         str;
    has current_capacity: int;
    has max_capacity:     int;
    has needed_items:     list[str];
    has pct_full:         int;
}

obj DispatchResult {
    has dispatched: int;
    has skipped:    int;
    has log:        list[str];
}

obj VolunteerInfo {
    has id:           str;
    has name:         str;
    has vehicle_type: str;
    has location:     str;
    has contact:      str;
    has is_available: bool;
}

# ==================================================
# INTERNAL HELPERS
# ==================================================

def get_hub() -> NourishHub | None {
    hubs: list[NourishHub] = [root -->][?:NourishHub];
    if len(hubs) > 0 {
        return hubs[0];
    }
    return None;
}

def ensure_ecosystem() -> NourishHub {
    # Get existing hub or create a fresh Nourish ecosystem
    existing: NourishHub | None = get_hub();
    if existing is not None {
        return existing;
    }

    hub: NourishHub = NourishHub(name="Nourish Hub");
    root ++> hub;

    # 2 businesses
    biz1: Business = Business(
        name="FreshMart Supermarket",
        location="12 Market St, Downtown",
        business_type="supermarket",
        contact="freshmart@nourish.app"
    );
    biz2: Business = Business(
        name="The Green Bistro",
        location="45 Oak Ave, Midtown",
        business_type="restaurant",
        contact="greenbistro@nourish.app"
    );
    hub ++> biz1;
    hub ++> biz2;

    # 2 shelters
    s1: Shelter = Shelter(
        name="Hope Community Shelter",
        location="88 Elm Rd, Eastside",
        current_capacity=20,
        max_capacity=100,
        needed_items=["vegetables", "bread", "dairy"]
    );
    s2: Shelter = Shelter(
        name="Sunrise Food Bank",
        location="3 Pine Blvd, Westside",
        current_capacity=50,
        max_capacity=200,
        needed_items=["canned goods", "rice", "vegetables", "bread"]
    );
    hub ++> s1;
    hub ++> s2;

    # 2 volunteers
    v1: Volunteer = Volunteer(
        name="Alex Rivera",
        vehicle_type="van",
        location="22 Cedar Lane, Central",
        contact="+1-555-0101",
        is_available=True
    );
    v2: Volunteer = Volunteer(
        name="Sam Chen",
        vehicle_type="car",
        location="7 Birch St, Northside",
        contact="+1-555-0202",
        is_available=True
    );
    hub ++> v1;
    hub ++> v2;

    return hub;
}

# ==================================================
# PUBLIC ENDPOINTS
# ==================================================

def:pub get_dashboard() -> DashboardStats {
    # Return aggregate stats for the dashboard
    hub: NourishHub = ensure_ecosystem();

    businesses:  list[Business]  = [hub -->][?:Business];
    shelters:    list[Shelter]   = [hub -->][?:Shelter];
    donations:   list[Donation]  = [hub -->][?:Donation];
    volunteers:  list[Volunteer] = [hub -->][?:Volunteer];

    pending:  int = 0;
    matched:  int = 0;
    total_kg: int = 0;

    for d in donations {
        if d.status == "pending" { pending += 1; }
        if d.status == "matched" {
            matched += 1;
            total_kg += d.quantity;
        }
    }

    avail: int = 0;
    for v in volunteers {
        if v.is_available { avail += 1; }
    }

    return DashboardStats(
        businesses=len(businesses),
        shelters=len(shelters),
        pending_donations=pending,
        matched_donations=matched,
        volunteers_available=avail,
        total_kg_rescued=total_kg
    );
}

def:pub get_donations() -> list[DonationInfo] {
    # Return all donations with enriched info
    hub: NourishHub = ensure_ecosystem();
    donations: list[Donation] = [hub -->][?:Donation];

    result: list[DonationInfo] = [];
    for d in donations {
        result.append(DonationInfo(
            id=jid(d),
            food_type=d.food_type,
            quantity=d.quantity,
            expiry_time=d.expiry_time,
            status=d.status,
            business_name=d.business_name,
            shelter_name=d.shelter_name,
            volunteer_name=d.volunteer_name
        ));
    }
    return result;
}

def:pub get_shelters() -> list[ShelterInfo] {
    # Return all shelters with capacity info
    hub: NourishHub = ensure_ecosystem();
    shelters: list[Shelter] = [hub -->][?:Shelter];

    result: list[ShelterInfo] = [];
    for s in shelters {
        pct: int = 0;
        if s.max_capacity > 0 {
            pct = int((s.current_capacity / s.max_capacity) * 100);
        }
        result.append(ShelterInfo(
            id=jid(s),
            name=s.name,
            location=s.location,
            current_capacity=s.current_capacity,
            max_capacity=s.max_capacity,
            needed_items=s.needed_items,
            pct_full=pct
        ));
    }
    return result;
}

def:pub add_donation(food_type: str, quantity: int, expiry_time: str, business_name: str) -> DonationInfo {
    # Add a new donation from a business
    hub: NourishHub = ensure_ecosystem();

    now_str: str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S");
    status: str = "pending";
    if expiry_time <= now_str {
        status = "expired";
    }

    d: Donation = Donation(
        food_type=food_type,
        quantity=quantity,
        expiry_time=expiry_time,
        business_name=business_name,
        status=status,
        dispatched=False,
        shelter_name="",
        volunteer_name=""
    );
    hub ++> d;

    return DonationInfo(
        id=jid(d),
        food_type=d.food_type,
        quantity=d.quantity,
        expiry_time=d.expiry_time,
        status=d.status,
        business_name=d.business_name,
        shelter_name="",
        volunteer_name=""
    );
}

def:pub run_dispatch() -> DispatchResult {
    # Run one dispatch cycle: match pending donations to shelters and volunteers
    hub: NourishHub = ensure_ecosystem();

    donations:  list[Donation]  = [hub -->][?:Donation];
    shelters:   list[Shelter]   = [hub -->][?:Shelter];
    volunteers: list[Volunteer] = [hub -->][?:Volunteer];

    dispatched: int = 0;
    skipped:    int = 0;
    log:        list[str] = [];

    for don in donations {
        if don.dispatched or don.status != "pending" {
            skipped += 1;
            continue;
        }

        # Find a shelter with capacity that needs this food type
        matched_shelter: Shelter | None = None;
        for s in shelters {
            if s.current_capacity < s.max_capacity {
                if len(s.needed_items) == 0 or don.food_type in s.needed_items {
                    matched_shelter = s;
                    break;
                }
            }
        }

        if matched_shelter is None {
            log.append("⚠ No shelter for: " + don.food_type);
            skipped += 1;
            continue;
        }

        # Find an available volunteer
        selected_vol: Volunteer | None = None;
        for v in volunteers {
            if v.is_available {
                selected_vol = v;
                break;
            }
        }

        # Update donation
        don.status = "matched";
        don.dispatched = True;
        don.shelter_name = matched_shelter.name;
        matched_shelter.current_capacity += don.quantity;

        if selected_vol is not None {
            selected_vol.is_available = False;
            don.volunteer_name = selected_vol.name;
            don +>:AssignedVolunteer():+> selected_vol;
            log.append(
                "[Dispatch] " + don.food_type + " (" + str(don.quantity) + "kg) matched to "
                + matched_shelter.name + " — assigned to " + selected_vol.name
            );
        } else {
            log.append(
                "[Dispatch] " + don.food_type + " (" + str(don.quantity) + "kg) matched to "
                + matched_shelter.name + " — no volunteer available"
            );
        }

        don +>:AllocatedTo():+> matched_shelter;
        dispatched += 1;
    }

    return DispatchResult(dispatched=dispatched, skipped=skipped, log=log);
}

def:pub get_volunteers() -> list[VolunteerInfo] {
    # Return all volunteers with availability status
    hub: NourishHub = ensure_ecosystem();
    volunteers: list[Volunteer] = [hub -->][?:Volunteer];

    result: list[VolunteerInfo] = [];
    for v in volunteers {
        result.append(VolunteerInfo(
            id=jid(v),
            name=v.name,
            vehicle_type=v.vehicle_type,
            location=v.location,
            contact=v.contact,
            is_available=v.is_available
        ));
    }
    return result;
}

def:pub reset_ecosystem() -> DashboardStats {
    # Delete the current hub and recreate a fresh ecosystem
    existing: NourishHub | None = get_hub();
    if existing is not None {
        del existing;
    }
    hub: NourishHub = ensure_ecosystem();
    return get_dashboard();
}
