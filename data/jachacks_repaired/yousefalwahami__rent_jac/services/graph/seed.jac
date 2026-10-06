"""Seed walker: creates demo property structure and vendors."""

import from services.graph.models {
    Property, Unit, Vendor,
    HasUnit, Services
}


walker seed_graph {
    can create with Root entry {
        existing = [-->][?:Property];
        if existing {
            report {"status": "already_seeded", "properties": len(existing)};
            disengage;
        }

        # Property
        prop = Property(
            name="Palm Court Apartments",
            address="123 University Ave",
            city="Ann Arbor",
            state="MI",
            zip_code="48104"
        );
        here ++> prop;

        # Units
        prop +>: HasUnit :+> Unit(number="1A", bedrooms=1, bathrooms=1, sq_ft=650);
        prop +>: HasUnit :+> Unit(number="2A", bedrooms=2, bathrooms=1, sq_ft=900);
        prop +>: HasUnit :+> Unit(number="3B", bedrooms=2, bathrooms=2, sq_ft=1100);
        prop +>: HasUnit :+> Unit(number="4B", bedrooms=1, bathrooms=1, sq_ft=700);

        # Vendors
        prop +>: Services(jobs_completed=5, total_spent=890.0) :+> Vendor(
            name="Mike's HVAC", category="hvac",
            phone="+17345550201", email="mike@mikeshvac.com",
            rating=4.7, avg_cost=180.0
        );
        prop +>: Services(jobs_completed=3, total_spent=520.0) :+> Vendor(
            name="Quick Flow Plumbing", category="plumbing",
            phone="+17345550202", email="info@quickflow.com",
            rating=4.5, avg_cost=150.0
        );
        prop +>: Services(jobs_completed=2, total_spent=340.0) :+> Vendor(
            name="Spark Electric Co", category="electrical",
            phone="+17345550203", email="jobs@sparkelectric.com",
            rating=4.8, avg_cost=200.0
        );

        report {
            "status": "seeded",
            "property": "Palm Court Apartments",
            "units": 4, "vendors": 3
        };
    }
}
