"""
nourish_model.jac
============
Nourish — Food Rescue Dispatcher
Graph data model: Nodes, Edges, and shared utility objects.
"""

# ---------------------------------------------------------------------------
# Hub node — single root anchor for the entire Nourish graph
# ---------------------------------------------------------------------------
node HubNode {
    has name: str = "Nourish Hub";
}

# ---------------------------------------------------------------------------
# Core domain nodes
# ---------------------------------------------------------------------------

# A food-producing business (supermarket, restaurant, etc.)
node BusinessNode {
    has name:          str;
    has location:      str;
    has business_type: str;
    has contact:       str;
}

# A food shelter that receives rescued food
node ShelterNode {
    has name:             str;
    has location:         str;
    has current_capacity: int;
    has max_capacity:     int;
    has needed_items:     list[str];
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

# ---------------------------------------------------------------------------
# Typed edges
# ---------------------------------------------------------------------------

# BusinessNode -> DonationNode: the business is offering this donation
edge Offers {}

# DonationNode -> ShelterNode: this donation has been matched to a shelter
edge AllocatedTo {}

# DonationNode -> VolunteerNode: this volunteer will handle the pickup
edge AssignedVolunteer {}

# any domain node -> HubNode: registers the entity with the hub
edge ConnectedToHub {}
