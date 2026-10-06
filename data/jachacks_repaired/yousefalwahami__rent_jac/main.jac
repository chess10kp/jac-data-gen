"""
Rentora entry point.
Imports server-side symbols and mounts the client app.
"""

import from services.appService {
    greet,
    send_test_sms,
    twilio_webhook,
    get_messages,
    get_twilio_number,
    set_alert_number,
    send_sms,
    delete_message,
    run_triage_for_message,
    run_maintenance_direct,
    maintenance_phase1,
    send_maintenance_alert,
    fetch_properties,
    fetch_tenants,
    save_property_data,
    save_tenant_data,
    delete_property_data,
    delete_tenant_data,
    seed_if_empty
}
import from services.profileService { get_profile, update_profile }
import from services.dataService {
    get_properties,
    get_tenants,
    add_property,
    add_tenant,
    update_property,
    delete_property,
    update_tenant,
    delete_tenant
}
import from services.graphService {
    Property,
    Unit,
    Lease,
    Tenant,
    Ticket,
    Vendor,
    HasUnit,
    HasLease,
    HasTenant,
    HasTicket,
    Services,
    AssignedTo,
    seed_graph,
    list_properties,
    list_units,
    list_tickets,
    list_vendors,
    triage,
    handle_maintenance,
    approve_dispatch,
    resolve_ticket,
    register_tenant,
    db_health,
    list_tenants,
    add_property_node,
    delete_tenant_node,
    delete_property_node,
    match_tenant
}

with entry {
    print("Rentora server starting...");
}

import ".styles.global.css";
import from .index { ClientApp }


def:pub app() -> JsxElement {
    return <ClientApp/>;
}
