"""
supply_agent.jac
===========
Nourish — Supply Agent (supply_manager walker)

Triggered when a business uploads available food.
Lands on a BusinessNode, validates the payload, and spawns a DonationNode
connected to that business via an Offers edge.
"""

import from datetime { datetime }

import from services.nourish_model {
    BusinessNode, DonationNode, Offers
}

# ---------------------------------------------------------------------------
# Supply Manager Walker
# ---------------------------------------------------------------------------
walker supply_manager {
    # Payload fields passed in when spawning this walker on a BusinessNode
    has food_type:   str;
    has quantity:    int;
    has expiry_time: str;   # ISO-8601 string, e.g. "2025-12-31T18:00:00"

    # Result fields — readable after the walker completes
    has created_donation: DonationNode | None = None;
    has error_message:    str = "";

    can process_business with BusinessNode entry {
        # "here" is the BusinessNode this walker landed on
        biz: BusinessNode = here;

        # ----------------------------------------------------------------
        # Step 1: Validate that the food is not already expired.
        # Simple lexicographic comparison works for zero-padded ISO-8601.
        # ----------------------------------------------------------------
        now_str: str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S");

        if self.expiry_time <= now_str {
            self.error_message = (
                f"REJECTED: Food '{self.food_type}' from '{biz.name}' "
                f"is already expired (expiry={self.expiry_time})."
            );
            print("[SupplyAgent] " + self.error_message);
            report {"status": "error", "message": self.error_message};
            disengage;
        }

        # ----------------------------------------------------------------
        # Step 2: Create the DonationNode and connect it to the business.
        # ----------------------------------------------------------------
        donation: DonationNode = DonationNode(
            food_type=self.food_type,
            quantity=self.quantity,
            expiry_time=self.expiry_time,
            status="pending",
            dispatched=False
        );

        # Attach donation to the business via a typed Offers edge
        biz +>:Offers():+> donation;

        # Also anchor the donation to root so walkers can discover it
        root ++> donation;

        self.created_donation = donation;

        print(
            f"[SupplyAgent] Created DonationNode: {self.food_type} "
            f"({self.quantity}kg) from '{biz.name}' — expires {self.expiry_time}."
        );

        report {
            "status": "created",
            "business": biz.name,
            "food_type": self.food_type,
            "quantity": self.quantity,
            "expiry_time": self.expiry_time
        };

        disengage;
    }
}
