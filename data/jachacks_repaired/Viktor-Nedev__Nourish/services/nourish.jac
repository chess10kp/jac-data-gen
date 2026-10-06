"""
nourish.jac
========
Nourish — Autonomous Food Rescue Dispatcher
Complete backend: graph model, multi-agent walkers, and init entry point.

Architecture:
  - HubNode: session anchor — all domain nodes attach here, not to root.
             This isolates each run in a persistent graph environment.
  - BusinessNode: food-producing businesses (supermarkets, restaurants)
  - ShelterNode:  food shelters that receive rescued food
  - DonationNode: individual food rescue offers
  - VolunteerNode: volunteer drivers

Agents (walkers):
  - supply_manager:        triggered when a business uploads available food
  - demand_tracker:        aggregates and updates shelter needs
  - autonomous_dispatcher: matches donations to shelters and recruits volunteers
"""

import from datetime { datetime }

# ==================================================
# TYPED EDGES
# ==================================================

# BusinessNode -> DonationNode: the business is offering this donation
edge Offers {}

# DonationNode -> ShelterNode: this donation has been matched to a shelter
edge AllocatedTo {}

# DonationNode -> VolunteerNode: this volunteer will handle the pickup
edge AssignedVolunteer {}

# ==================================================
# NODES
# ==================================================

# Central session anchor — all domain nodes connect here (not to root).
# This ensures each run's nodes are isolated in a persistent graph.
node HubNode {
    has name:       str = "Nourish Hub";
    has session_id: str = "";
}

# A food-producing business (supermarket, restaurant, etc.)
node BusinessNode {
    has name:          str;
    has location:      str;
    has business_type: str;
    has contact:       str;

    # Node-side entry: supply_manager arrives here to register a donation
    can register_donation with supply_manager entry {
        now_str: str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S");

        if visitor.expiry_time <= now_str {
            visitor.error_message = (
                f"REJECTED: Food '{visitor.food_type}' from '{self.name}' "
                f"is already expired (expiry={visitor.expiry_time})."
            );
            print("[SupplyAgent] " + visitor.error_message);
            report {"status": "error", "message": visitor.error_message};
            return;
        }

        donation: DonationNode = DonationNode(
            food_type=visitor.food_type,
            quantity=visitor.quantity,
            expiry_time=visitor.expiry_time,
            status="pending",
            dispatched=False
        );

        # Connect business -> donation via typed Offers edge
        self +>:Offers():+> donation;

        # Anchor donation to the hub (not root) for session isolation
        visitor.hub +>:Offers():+> donation;

        visitor.created_donation = donation;

        print(
            f"[SupplyAgent] Created DonationNode: {visitor.food_type} "
            f"({visitor.quantity}kg) from '{self.name}' — expires {visitor.expiry_time}."
        );

        report {
            "status": "created",
            "business": self.name,
            "food_type": visitor.food_type,
            "quantity": visitor.quantity,
            "expiry_time": visitor.expiry_time
        };
    }
}

# A food shelter that receives rescued food
node ShelterNode {
    has name:             str;
    has location:         str;
    has current_capacity: int;
    has max_capacity:     int;
    has needed_items:     list[str];

    # Node-side entry: demand_tracker arrives here to update capacity info
    can update_demand with demand_tracker entry {
        if visitor.update_name == self.name {
            self.current_capacity = visitor.new_capacity;
            print(
                f"[DemandTracker] Updated '{self.name}': "
                f"capacity={self.current_capacity}/{self.max_capacity}, "
                f"needs={self.needed_items}."
            );
        } else {
            print(
                f"[DemandTracker] Scanned '{self.name}': "
                f"capacity={self.current_capacity}/{self.max_capacity}, "
                f"needs={self.needed_items}."
            );
        }

        visitor.shelter_states.append({
            "name": self.name,
            "location": self.location,
            "current_capacity": self.current_capacity,
            "max_capacity": self.max_capacity,
            "needed_items": self.needed_items,
            "has_space": self.current_capacity < self.max_capacity
        });

        report {
            "shelter": self.name,
            "current_capacity": self.current_capacity,
            "max_capacity": self.max_capacity,
            "needed_items": self.needed_items
        };
    }
}

# A single food-rescue offer created by a business.
# status lifecycle: "pending" -> "matched" -> "completed"
node DonationNode {
    has food_type:   str;
    has quantity:    int;
    has expiry_time: str;
    has status:      str = "pending";
    has dispatched:  bool = False;
}

# A volunteer driver available for pickups
node VolunteerNode {
    has name:         str;
    has vehicle_type: str;
    has location:     str;
    has contact:      str;
    has is_available: bool = True;
}

# ==================================================
# WALKER: supply_manager
# Supply Agent — triggered when a business uploads available food.
# Spawned directly ON a BusinessNode. Carries a hub reference for anchoring.
# ==================================================
walker supply_manager {
    has food_type:   str;
    has quantity:    int;
    has expiry_time: str;
    has hub:         HubNode;   # required: hub reference for donation anchoring

    has created_donation: DonationNode | None = None;
    has error_message:    str = "";

    # Walker is spawned directly ON a BusinessNode.
    # Logic lives in BusinessNode.register_donation (node-side entry).
    # No traversal needed — walker stops after node-side ability runs.
}

# ==================================================
# WALKER: demand_tracker
# Demand Agent — walks all ShelterNodes connected to the hub and aggregates needs.
# ==================================================
walker demand_tracker {
    has hub:          HubNode;   # required: hub reference for traversal
    has update_name:  str = "";
    has new_capacity: int = 0;

    has shelter_states: list[dict[str, any]] = [];

    # Start at hub, visit all ShelterNodes connected to it
    can on_hub with HubNode entry {
        print("[DemandTracker] Starting shelter scan...");
        visit [-->][?:ShelterNode];
    }

    # The actual per-shelter logic lives in ShelterNode.update_demand (node-side)
    can on_shelter with ShelterNode entry {
        # No further traversal — hub has direct edges to all shelters
    }
}

# ==================================================
# WALKER: autonomous_dispatcher
# Logistics Agent — matches pending donations to shelters and recruits volunteers.
# Runs entirely from the hub in a single entry to avoid multi-entry conflicts.
# ==================================================
walker autonomous_dispatcher {
    has hub: HubNode;   # required: hub reference for traversal

    has dispatched_count: int = 0;
    has skipped_count:    int = 0;
    has dispatch_log:     list[dict[str, any]] = [];

    can on_hub with HubNode entry {
        print("[Dispatcher] Starting autonomous dispatch cycle...");

        # Collect all domain nodes from the hub (session-isolated)
        all_donations:  list[DonationNode]  = [-->][?:DonationNode];
        all_shelters:   list[ShelterNode]   = [-->][?:ShelterNode];
        all_volunteers: list[VolunteerNode] = [-->][?:VolunteerNode];

        for don in all_donations {
            # Guard: skip if already dispatched or not pending
            if don.dispatched or don.status != "pending" {
                self.skipped_count += 1;
                continue;
            }

            print(f"[Dispatcher] Processing donation: {don.food_type} ({don.quantity}kg).");

            # ----------------------------------------------------------------
            # Step 1: Find a shelter with capacity that needs this food type.
            # ----------------------------------------------------------------
            matched_shelter: ShelterNode | None = None;

            for s in all_shelters {
                if s.current_capacity < s.max_capacity {
                    if len(s.needed_items) == 0 or don.food_type in s.needed_items {
                        matched_shelter = s;
                        break;
                    }
                }
            }

            if matched_shelter is None {
                print(
                    f"[Dispatcher] No shelter available for '{don.food_type}'. "
                    f"Will retry next cycle."
                );
                self.skipped_count += 1;
                continue;
            }

            # ----------------------------------------------------------------
            # Step 2: Update donation status and create allocation edge.
            # ----------------------------------------------------------------
            don.status = "matched";
            don.dispatched = True;

            don +>:AllocatedTo():+> matched_shelter;

            # Reserve space at the shelter
            matched_shelter.current_capacity += don.quantity;

            print(
                f"[Dispatcher] Matched '{don.food_type}' ({don.quantity}kg) "
                f"-> shelter '{matched_shelter.name}'."
            );

            # ----------------------------------------------------------------
            # Step 3: Find an available volunteer and notify them.
            # ----------------------------------------------------------------
            selected_volunteer: VolunteerNode | None = None;

            for v in all_volunteers {
                if v.is_available {
                    selected_volunteer = v;
                    break;
                }
            }

            if selected_volunteer is None {
                print(
                    f"[Dispatcher] WARNING: No volunteers available for "
                    f"'{don.food_type}' pickup. Donation matched but unassigned."
                );
                self.dispatch_log.append({
                    "food_type": don.food_type,
                    "quantity": don.quantity,
                    "shelter": matched_shelter.name,
                    "volunteer": "NONE",
                    "status": "matched_no_volunteer"
                });
                self.dispatched_count += 1;
                continue;
            }

            # Mark volunteer as busy for this cycle
            selected_volunteer.is_available = False;

            # Connect donation -> volunteer via typed edge
            don +>:AssignedVolunteer():+> selected_volunteer;

            # ----------------------------------------------------------------
            # Step 4: Mock external notification (SMS/Email API call).
            # ----------------------------------------------------------------
            self.notify_volunteer(selected_volunteer, don, matched_shelter);

            self.dispatch_log.append({
                "food_type": don.food_type,
                "quantity": don.quantity,
                "shelter": matched_shelter.name,
                "volunteer": selected_volunteer.name,
                "volunteer_contact": selected_volunteer.contact,
                "status": "dispatched"
            });

            self.dispatched_count += 1;

            report {
                "event": "dispatch",
                "donation": don.food_type,
                "quantity": don.quantity,
                "shelter": matched_shelter.name,
                "volunteer": selected_volunteer.name
            };
        }

        print(
            f"\n[Dispatcher] Cycle complete: "
            f"{self.dispatched_count} dispatched, "
            f"{self.skipped_count} skipped."
        );
        report {
            "dispatched": self.dispatched_count,
            "skipped": self.skipped_count,
            "log": self.dispatch_log
        };

        disengage;
    }

    # Ability: mock external SMS/Email notification API call
    def notify_volunteer(
        volunteer: VolunteerNode,
        donation: DonationNode,
        shelter: ShelterNode
    ) -> None {
        msg: str = (
            f"\n  ╔══════════════════════════════════════════╗\n"
            f"  ║  🚚 NOURISH DISPATCH NOTIFICATION         ║\n"
            f"  ╠══════════════════════════════════════════╣\n"
            f"  ║  To:       {volunteer.name} ({volunteer.vehicle_type})\n"
            f"  ║  Contact:  {volunteer.contact}\n"
            f"  ║  Pickup:   Business location\n"
            f"  ║  Delivery: {shelter.name} @ {shelter.location}\n"
            f"  ║  Item:     {donation.food_type} — {donation.quantity}kg\n"
            f"  ║  Expires:  {donation.expiry_time}\n"
            f"  ╚══════════════════════════════════════════╝"
        );
        print("[Dispatcher] Mock API → notify_volunteer:" + msg);
    }
}

# ==================================================
# ENTRY POINT — bootstraps the mock Nourish ecosystem and runs a sample flow
# ==================================================
with entry {
    print("\n╔══════════════════════════════════════════════╗");
    print("║   🌱 NOURISH — Food Rescue Dispatcher Init   ║");
    print("╚══════════════════════════════════════════════╝\n");

    # ----------------------------------------------------------------
    # 1. Create a fresh HubNode as the session anchor.
    #    All domain nodes attach to the hub, NOT to root.
    #    This isolates each run in a persistent graph environment.
    # ----------------------------------------------------------------
    hub: HubNode = HubNode(
        name="Nourish Hub",
        session_id=datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    );
    root ++> hub;

    # ----------------------------------------------------------------
    # 2. Create 2 BusinessNodes
    # ----------------------------------------------------------------
    biz1: BusinessNode = BusinessNode(
        name="FreshMart Supermarket",
        location="12 Market St, Downtown",
        business_type="supermarket",
        contact="freshmart@example.com"
    );
    biz2: BusinessNode = BusinessNode(
        name="The Green Bistro",
        location="45 Oak Ave, Midtown",
        business_type="restaurant",
        contact="greenbistro@example.com"
    );
    hub ++> biz1;
    hub ++> biz2;
    print("[Init] Created 2 businesses: FreshMart Supermarket, The Green Bistro.");

    # ----------------------------------------------------------------
    # 3. Create 2 ShelterNodes
    # ----------------------------------------------------------------
    shelter1: ShelterNode = ShelterNode(
        name="Hope Community Shelter",
        location="88 Elm Rd, Eastside",
        current_capacity=20,
        max_capacity=100,
        needed_items=["vegetables", "bread", "dairy"]
    );
    shelter2: ShelterNode = ShelterNode(
        name="Sunrise Food Bank",
        location="3 Pine Blvd, Westside",
        current_capacity=50,
        max_capacity=200,
        needed_items=["canned goods", "rice", "vegetables", "bread"]
    );
    hub ++> shelter1;
    hub ++> shelter2;
    print("[Init] Created 2 shelters: Hope Community Shelter, Sunrise Food Bank.");

    # ----------------------------------------------------------------
    # 4. Create 2 VolunteerNodes
    # ----------------------------------------------------------------
    vol1: VolunteerNode = VolunteerNode(
        name="Alex Rivera",
        vehicle_type="van",
        location="22 Cedar Lane, Central",
        contact="+1-555-0101",
        is_available=True
    );
    vol2: VolunteerNode = VolunteerNode(
        name="Sam Chen",
        vehicle_type="car",
        location="7 Birch St, Northside",
        contact="+1-555-0202",
        is_available=True
    );
    hub ++> vol1;
    hub ++> vol2;
    print("[Init] Created 2 volunteers: Alex Rivera, Sam Chen.\n");

    # ----------------------------------------------------------------
    # 5. Phase 1: Supply Agent — businesses upload food donations
    # ----------------------------------------------------------------
    print("── Phase 1: Supply Agent ─────────────────────────────");

    # FreshMart uploads vegetables (valid, future expiry)
    biz1 spawn supply_manager(
        food_type="vegetables",
        quantity=50,
        expiry_time="2099-12-31T18:00:00",
        hub=hub
    );

    # Green Bistro uploads bread (valid, future expiry)
    biz2 spawn supply_manager(
        food_type="bread",
        quantity=30,
        expiry_time="2099-12-31T20:00:00",
        hub=hub
    );

    # Test: expired food from FreshMart (should be rejected)
    biz1 spawn supply_manager(
        food_type="old salad",
        quantity=5,
        expiry_time="2000-01-01T00:00:00",
        hub=hub
    );

    # ----------------------------------------------------------------
    # 6. Phase 2: Demand Tracker — scan and update shelter needs
    # ----------------------------------------------------------------
    print("\n── Phase 2: Demand Tracker ───────────────────────────");
    hub spawn demand_tracker(
        hub=hub,
        update_name="Hope Community Shelter",
        new_capacity=25
    );

    # ----------------------------------------------------------------
    # 7. Phase 3: Autonomous Dispatcher — match donations to shelters
    # ----------------------------------------------------------------
    print("\n── Phase 3: Autonomous Dispatcher ────────────────────");
    hub spawn autonomous_dispatcher(hub=hub);

    print("\n╔══════════════════════════════════════════════╗");
    print("║   ✅ NOURISH Init Complete                    ║");
    print("╚══════════════════════════════════════════════╝\n");
}
