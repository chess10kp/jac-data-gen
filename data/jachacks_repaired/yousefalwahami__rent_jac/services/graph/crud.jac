"""CRUD walkers: read-only graph queries for the dashboard."""

import from services.graph.models {
    Property, Unit, Lease, Tenant, Ticket, Vendor,
    HasUnit, HasLease, HasTenant, HasTicket, Services
}
import from services.graph.localdb { check_db_health }


walker list_properties {
    can list_all with Root entry {
        properties = [-->][?:Property];
        result = [];
        for p in properties {
            units = [p ->: HasUnit :->];
            result.append({
                "id": jid(p),
                "name": p.name,
                "address": p.address,
                "city": p.city,
                "state": p.state,
                "unit_count": len(units)
            });
        }
        report result;
    }
}


walker list_units {
    can start with Root entry {
        visit [-->][?:Property];
    }

    can gather with Property entry {
        units = [->: HasUnit :->];
        for u in units {
            leases = [u ->: HasLease :->];
            lease = leases[0] if leases else None;
            tenant: any = None;
            if lease {
                tenants = [lease ->: HasTenant :->];
                tenant = tenants[0] if tenants else None;
            }
            tickets = [u ->: HasTicket :->];
            open_tickets = [t for t in tickets if t.status != "resolved" and t.status != "closed"];

            report {
                "id": jid(u),
                "unit": u.number,
                "bedrooms": u.bedrooms,
                "bathrooms": u.bathrooms,
                "sq_ft": u.sq_ft,
                "status": u.status,
                "property": here.name,
                "tenant": tenant.name if tenant else None,
                "tenant_phone": tenant.phone if tenant else None,
                "payment_status": tenant.payment_status if tenant else None,
                "rent": lease.rent_amount if lease else None,
                "lease_end": lease.end_date if lease else None,
                "open_tickets": len(open_tickets),
                "total_tickets": len(tickets)
            };
        }
    }
}


walker list_tickets {
    can start with Root entry {
        visit [-->][?:Property];
    }

    can at_property with Property entry {
        visit [->: HasUnit :->];
    }

    can at_unit with Unit entry {
        tickets = [->: HasTicket :->];
        for t in tickets {
            report {
                "id": jid(t),
                "ticket_id": t.ticket_id,
                "unit": here.number,
                "category": t.category,
                "description": t.description,
                "urgency": t.urgency,
                "status": t.status,
                "ai_summary": t.ai_summary,
                "recommended_action": t.recommended_action,
                "vendor_name": t.vendor_name,
                "estimated_cost": t.estimated_cost,
                "tenant_reply": t.tenant_reply,
                "owner_alert": t.owner_alert,
                "created_at": t.created_at,
                "resolved_at": t.resolved_at
            };
        }
    }
}


walker list_vendors {
    can start with Root entry {
        visit [-->][?:Property];
    }

    can at_property with Property entry {
        vendors = [->: Services :->];
        for v in vendors {
            report {
                "id": jid(v),
                "name": v.name,
                "category": v.category,
                "phone": v.phone,
                "rating": v.rating,
                "avg_cost": v.avg_cost,
                "available": v.available,
                "property": here.name
            };
        }
    }
}


walker register_tenant {
    has tenant_name: str = "";
    has tenant_phone: str = "";
    has tenant_email: str = "";
    has unit_number: str = "";
    has rent_amount: float = 0.0;
    has lease_start: str = "";
    has lease_end: str = "";
    has property_name: str = "";

    can start with Root entry {
        visit [-->][?:Property];
    }

    can find_unit with Property entry {
        if self.property_name and here.name != self.property_name {
            return;
        }
        # Find existing unit (case-insensitive) or create it
        units = [->: HasUnit :->];
        target_unit: Unit | None = None;
        for u in units {
            if u.number.upper() == self.unit_number.upper() {
                target_unit = u;
                break;
            }
        }
        if not target_unit {
            target_unit = Unit(number=self.unit_number.upper(), bedrooms=1, bathrooms=1, sq_ft=0);
            here +>: HasUnit :+> target_unit;
        }
        # Guard: skip if tenant with same phone already registered in this unit
        existing_leases = [target_unit ->: HasLease :->];
        for lease in existing_leases {
            existing_tenants = [lease ->: HasTenant :->];
            for t in existing_tenants {
                if t.phone == self.tenant_phone {
                    report {
                        "status": "already_registered",
                        "tenant": t.name,
                        "phone": t.phone,
                        "unit": target_unit.number,
                        "property": here.name,
                        "id": jid(t)
                    };
                    disengage;
                }
            }
        }
        # Create lease + tenant
        lease = Lease(
            start_date=self.lease_start,
            end_date=self.lease_end,
            rent_amount=self.rent_amount,
            deposit=self.rent_amount
        );
        target_unit +>: HasLease :+> lease;
        lease +>: HasTenant :+> Tenant(
            name=self.tenant_name,
            phone=self.tenant_phone,
            email=self.tenant_email,
            payment_status="current",
            move_in_date=self.lease_start
        );
        tenants_created = [lease ->: HasTenant :->];
        new_tenant = tenants_created[0] if tenants_created else None;
        report {
            "status": "registered",
            "tenant": self.tenant_name,
            "phone": self.tenant_phone,
            "unit": target_unit.number,
            "property": here.name,
            "id": jid(new_tenant) if new_tenant else ""
        };
        disengage;
    }
}


walker db_health {
    can check with Root entry {
        mongo = check_db_health();
        report {
            "database": mongo,
            "graph_store": "ok"
        };
    }
}


walker list_tenants {
    can list_all with Root entry {
        properties = [-->][?:Property];
        result = [];
        for p in properties {
            prop_id = jid(p);
            prop_name = p.name;
            units = [p ->: HasUnit :->];
            for u in units {
                leases = [u ->: HasLease :->];
                for lease in leases {
                    tenants_in_unit = [lease ->: HasTenant :->];
                    for t in tenants_in_unit {
                        result.append({
                            "id": jid(t),
                            "full_name": t.name,
                            "phone_number": t.phone,
                            "unit_number": u.number,
                            "property_id": prop_id,
                            "property_name": prop_name,
                            "rent": lease.rent_amount,
                            "lease_end": lease.end_date
                        });
                    }
                }
            }
        }
        report result;
    }
}


walker add_property_node {
    has name: str = "";
    has address: str = "";
    has unit_numbers: list = [];

    can create with Root entry {
        prop = Property(name=self.name, address=self.address, city="", state="", zip_code="");
        here ++> prop;
        for unit_num in self.unit_numbers {
            prop +>: HasUnit :+> Unit(number=unit_num, bedrooms=1, bathrooms=1, sq_ft=0);
        }
        report {
            "status": "created",
            "id": jid(prop),
            "property": self.name,
            "units": len(self.unit_numbers)
        };
    }
}


walker delete_tenant_node {
    has tenant_id: str = "";

    can start with Root entry {
        visit [-->][?:Property];
    }

    can at_property with Property entry {
        units = [->: HasUnit :->];
        for u in units {
            leases = [u ->: HasLease :->];
            for lease in leases {
                tenants_in_lease = [lease ->: HasTenant :->];
                for t in tenants_in_lease {
                    if jid(t) == self.tenant_id {
                        del t;
                        report {"status": "deleted"};
                        disengage;
                    }
                }
            }
        }
    }

    can not_found with Root exit {
        report {"status": "not_found", "tenant_id": self.tenant_id};
    }
}


walker delete_property_node {
    has property_id: str = "";

    can start with Root entry {
        props = [-->][?:Property];
        for p in props {
            if jid(p) == self.property_id {
                del p;
                report {"status": "deleted"};
                disengage;
            }
        }
        report {"status": "not_found"};
    }
}


walker match_tenant {
    has phone: str = "";

    can start with Root entry {
        visit [-->][?:Property];
    }

    can at_property with Property entry {
        units = [->: HasUnit :->];
        for u in units {
            leases = [u ->: HasLease :->];
            for lease in leases {
                tenants_in_unit = [lease ->: HasTenant :->];
                for t in tenants_in_unit {
                    if t.phone == self.phone {
                        report {
                            "matched": True,
                            "tenant_name": t.name,
                            "property_name": here.name,
                            "unit": u.number
                        };
                        disengage;
                    }
                }
            }
        }
    }

    can not_found with Root exit {
        report {"matched": False};
    }
}
