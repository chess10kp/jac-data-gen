"""Action walkers: approve dispatch and resolve tickets."""

import from datetime { datetime }
import from services.graph.models {
    Property, Unit, Ticket,
    HasUnit, HasTicket
}


walker approve_dispatch {
    has ticket_id: str = "";

    can start with Root entry {
        visit [-->][?:Property];
    }

    can at_property with Property entry {
        visit [->: HasUnit :->];
    }

    can at_unit with Unit entry {
        tickets = [->: HasTicket :->];
        for t in tickets {
            if t.ticket_id == self.ticket_id {
                t.status = "dispatched";
                report {
                    "ticket_id": t.ticket_id,
                    "status": "dispatched",
                    "vendor_name": t.vendor_name,
                    "unit": here.number,
                    "tenant_reply": t.tenant_reply,
                    "owner_alert": t.owner_alert,
                    "estimated_cost": t.estimated_cost
                };
                disengage;
            }
        }
    }
}


walker resolve_ticket {
    has ticket_id: str = "";

    can start with Root entry {
        visit [-->][?:Property];
    }

    can at_property with Property entry {
        visit [->: HasUnit :->];
    }

    can at_unit with Unit entry {
        tickets = [->: HasTicket :->];
        for t in tickets {
            if t.ticket_id == self.ticket_id {
                t.status = "resolved";
                t.resolved_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S");
                report {
                    "ticket_id": t.ticket_id,
                    "status": "resolved",
                    "resolved_at": t.resolved_at
                };
                disengage;
            }
        }
    }
}
