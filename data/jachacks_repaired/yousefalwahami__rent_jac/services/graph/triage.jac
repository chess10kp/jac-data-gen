"""Triage walker: classifies inbound events and routes to handlers."""

import from datetime { datetime }
import from services.graph.models {
    Property, Unit, Lease, Tenant,
    HasUnit, HasLease, HasTenant
}
import from services.graph.ai { classify_event, EventType }
import from services.graph.maintenance { handle_maintenance }


walker triage {
    has message: str = "";
    has sender_phone: str = "";
    has ctx_property_name: str = "";
    has ctx_unit_number: str = "";
    has ctx_unit_ref: any = None;
    has ctx_found: bool = False;

    can start with Root entry {
        visit : 0 : [-->][?:Property];
    }

    can at_property with Property entry {
        if not self.ctx_found {
            self.ctx_property_name = here.name;
            visit : 0 : [->: HasUnit :->];
        }
    }

    can at_unit with Unit entry {
        if not self.ctx_found {
            self.ctx_unit_number = here.number;
            self.ctx_unit_ref = here;
            visit : 0 : [->: HasLease :->];
        }
    }

    can at_lease with Lease entry {
        if not self.ctx_found {
            visit : 0 : [->: HasTenant :->];
        }
    }

    can at_tenant with Tenant entry {
        if not self.ctx_found and here.phone == self.sender_phone {
            self.ctx_found = True;

            t_classify = datetime.now();
            classification = classify_event(self.message);
            classify_ms = int((datetime.now() - t_classify).total_seconds() * 1000);

            if classification == EventType.MAINTENANCE {
                print("[triage] MAINTENANCE matched tenant=" + here.name + " unit=" + self.ctx_unit_number);
                result = (self.ctx_unit_ref as Unit) spawn handle_maintenance(
                    message=self.message,
                    tenant_name=here.name,
                    tenant_phone=here.phone,
                    property_name=self.ctx_property_name
                );
                print("[triage] handle_maintenance result.reports count=" + str(len(result.reports)));
                maint = result.reports[0] if result.reports else None;
                print("[triage] maint=" + str(maint)[:120]);
                if maint and "timings" in maint {
                    maint["timings"]["entity_ms"] = 1;
                    maint["timings"]["classify_ms"] = classify_ms;
                    maint["timings"]["urgency_ms"] = classify_ms;
                } elif maint {
                    maint["timings"] = {"entity_ms": 1, "classify_ms": classify_ms, "urgency_ms": classify_ms};
                }
                report {
                    "status": "processed",
                    "event_type": "maintenance",
                    "tenant": here.name,
                    "property": self.ctx_property_name,
                    "unit": self.ctx_unit_number,
                    "result": maint
                };
            } else {
                report {
                    "status": "classified",
                    "event_type": str(classification).split(".")[-1].lower(),
                    "tenant": here.name,
                    "property": self.ctx_property_name,
                    "unit": self.ctx_unit_number,
                    "message": self.message,
                    "timings": {"entity_ms": 1, "classify_ms": classify_ms, "urgency_ms": classify_ms}
                };
            }

            disengage;
        }
    }

    can finish with Root exit {
        if not self.ctx_found {
            # No registered tenant matched — still run AI classification
            try {
                classification = classify_event(self.message);
                event_type = str(classification).split(".")[-1].lower();
                report {
                    "status": "classified",
                    "event_type": event_type,
                    "tenant": self.sender_phone,
                    "property": "Unknown",
                    "unit": "?",
                    "unmatched": True,
                    "message": self.message
                };
            } except Exception {
                report {
                    "status": "tenant_not_found",
                    "phone": self.sender_phone,
                    "message": self.message
                };
            }
        }
    }
}
