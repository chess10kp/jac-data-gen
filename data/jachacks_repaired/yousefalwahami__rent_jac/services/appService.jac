import from os { getenv }
import from fastapi { Request, Response, HTTPException }
import from pydantic { BaseModel }
import from dotenv { load_dotenv }
import from twilio.rest { Client }
import from services.graph.models { Property, Unit, Lease, Tenant }
import from datetime { datetime }
import from services.graphService { triage, handle_maintenance, diagnose_issue, list_properties, list_tenants, add_property_node, register_tenant, delete_property_node, delete_tenant_node, approve_dispatch }
import from logging { getLogger }
import from services.graph.localdb { log_sms, log_walker_run, create_notification }

glob _env: any = load_dotenv();
glob _twilio_log: any = getLogger("twilio.http_client").setLevel(40);


glob messages: list = [];
# Map from Twilio SID → triage result, so API-fetched messages can be enriched
glob _triage_by_sid: dict = {};
# Most recent pending maintenance ticket — used for YES/NO landlord approval via SMS
glob _pending_ticket: dict = {};

def:pub get_messages() -> dict {
    try {
        load_dotenv();
        account_sid = getenv("TWILIO_ACCOUNT_SID");
        auth_token = getenv("TWILIO_AUTH_TOKEN");
        twilio_num = getenv("TWILIO_PHONE_NUMBER");

        if account_sid and auth_token {
            client = Client(account_sid, auth_token);
            msgs = client.messages.list(limit=20);

            fmt_msgs = [];
            for m in msgs {
                if "Sent from your Twilio trial account" in str(m.body) {
                    continue;
                }
                fmt_msgs.append({
                    "from": m.from_,
                    "to": m.to,
                    "body": m.body,
                    "time": str(m.date_created) if m.date_created else "",
                    "sid": str(m.sid),
                    "triage": _triage_by_sid.get(str(m.sid), None)
                });
            }
            return {"messages": fmt_msgs, "source": "twilio_api"};
        }
    } except Exception as e {
        print("Failed to fetch from Twilio: " + str(e));
    }

    return {"messages": messages, "source": "memory"};
}

glob _alert_number: str = getenv("TWILIO_TARGET_PHONE_NUMBER") or "";



def:pub get_twilio_number() -> dict {
    number = getenv("TWILIO_PHONE_NUMBER") or "";
    return {"number": number};
}

def:pub set_alert_number(phone_number: str) -> dict {
    _alert_number = phone_number;
    return {"success": True, "alert_number": phone_number};
}


def:pub send_sms(recipient: str, body: str) -> dict {
    account_sid = getenv("TWILIO_ACCOUNT_SID");
    auth_token = getenv("TWILIO_AUTH_TOKEN");
    from_number = getenv("TWILIO_PHONE_NUMBER");
    if not (account_sid and auth_token and from_number) {
        return {"success": False, "error": "Twilio credentials not configured"};
    }
    import from twilio.rest { Client }
    client = Client(account_sid, auth_token);
    msg = client.messages.create(body=body, from_=from_number, to=recipient);
    print("SMS sent to " + recipient + " — SID: " + str(msg.sid));
    return {"success": True, "sid": str(msg.sid)};
}


def:pub greet(name: str = "World") -> dict {
    return {"message": "Hello, " + name + "! Your Jac backend is working."};
}

def _require_env(name: str) -> str {
    import from dotenv { load_dotenv }


    load_dotenv();
    value = getenv(name);
    if not value {
        raise Exception(name + " is not set");
    }
    return value;
}


def:pub send_test_sms(to_number: str = "", message: str = "Jac/Twilio webhook test: reply to this message and the sender number + body will print in the server output.") -> dict {
    try {
        account_sid = _require_env("TWILIO_ACCOUNT_SID");
        auth_token = _require_env("TWILIO_AUTH_TOKEN");
        from_number = _require_env("TWILIO_PHONE_NUMBER");
    } except Exception as e {
        return {"success": False, "error": str(e), "message": "Environment variables missing, check .env"};
    }

    to_num: any = to_number;
    if not to_num {
        to_num = getenv("TWILIO_TARGET_PHONE_NUMBER");
    }
    if not to_num {
        return {"success": False, "error": "Missing destination number", "message": "Provide to_number in request or set TWILIO_TARGET_PHONE_NUMBER in .env"};
    }

    try {
        
        client = Client(account_sid, auth_token);
        msg = client.messages.create(
            body=message,
            from_=from_number,
            to=to_num,
        );
        print("Twilio test SMS sent to " + to_num + " with SID " + str(msg.sid));
        
        # Log the outbound message to the feed so the UI picks it up
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S");
        messages.insert(0, {
            "from": from_number,
            "body": message,
            "time": timestamp,
        });

        return {
            "success": True,
            "to": to_num,
            "sid": str(msg.sid),
            "status": msg.status
        };
    } except Exception as e {
        print("Twilio error: " + str(e));
        return {"success": False, "error": "Twilio API Error", "message": str(e)};
    }
}

async def:pub twilio_webhook(request: Request) -> dict {
    form = await request.form();
    from_number = str(form.get("From") or "unknown");
    body = str(form.get("Body") or "");
    msg_sid = str(form.get("MessageSid") or "");
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S");

    print("Incoming Twilio SMS from " + from_number + ": " + body);

    # Log inbound SMS
    twilio_num = getenv("TWILIO_PHONE_NUMBER") or "";
    log_sms(from_number, twilio_num, body, "inbound", msg_sid);

    # ── Landlord YES/NO approval flow ────────────────────────
    alert_num = getenv("TWILIO_TARGET_PHONE_NUMBER") or _alert_number or "+15199992505";
    if from_number == alert_num and _pending_ticket and _pending_ticket.get("ticket_id") {
        cmd = body.strip().upper();
        if cmd in ["YES", "Y", "APPROVE", "CONFIRMED"] {
            ticket_id = _pending_ticket["ticket_id"];
            tenant_phone = _pending_ticket.get("tenant_phone", "");
            vendor = _pending_ticket.get("vendor", "");
            pending_sid = _pending_ticket.get("msg_sid", "");
            try {
                root spawn approve_dispatch(ticket_id=ticket_id);
                print("Ticket " + ticket_id + " approved by landlord");
            } except Exception as e {
                print("approve_dispatch error: " + str(e));
            }
            # Update triage cache so next poll reflects approval
            if pending_sid and pending_sid in _triage_by_sid and _triage_by_sid[pending_sid] {
                if _triage_by_sid[pending_sid].get("result") {
                    _triage_by_sid[pending_sid]["result"]["status"] = "Approved";
                }
            }
            # Confirm to landlord
            send_sms(alert_num, "Approved. Dispatching " + vendor + " for ticket " + ticket_id + ".");
            # Notify tenant
            if tenant_phone {
                send_sms(tenant_phone, "Update: Your repair request has been approved and a vendor has been dispatched. We will follow up shortly.");
            }
            _pending_ticket = {};
            return {"success": True, "action": "approved", "ticket_id": ticket_id};
        } elif cmd in ["NO", "N", "REJECT", "DECLINE"] {
            ticket_id = _pending_ticket["ticket_id"];
            tenant_phone = _pending_ticket.get("tenant_phone", "");
            pending_sid = _pending_ticket.get("msg_sid", "");
            # Update triage cache so next poll reflects rejection
            if pending_sid and pending_sid in _triage_by_sid and _triage_by_sid[pending_sid] {
                if _triage_by_sid[pending_sid].get("result") {
                    _triage_by_sid[pending_sid]["result"]["status"] = "Rejected";
                }
            }
            send_sms(alert_num, "Rejected ticket " + ticket_id + ". No vendor dispatched.");
            if tenant_phone {
                send_sms(tenant_phone, "Update: Your repair request is under review. We will be in touch shortly.");
            }
            _pending_ticket = {};
            return {"success": True, "action": "rejected", "ticket_id": ticket_id};
        }
        # If not a valid YES/NO, still ignore — landlord number is not a tenant
    }

    # Ignore ALL messages from the landlord alert number — not a tenant, no tickets
    if from_number == alert_num {
        print("Ignoring message from landlord alert number: " + from_number);
        return Response(
            content="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Response></Response>",
            media_type="application/xml"
        );
    }

    msg_entry = {
        "from": from_number,
        "body": body,
        "time": timestamp,
        "triage": None,
    };

    # ── Run the AI triage pipeline ───────────────────────────
    triage_result: any = None;
    try {
        result = root spawn triage(message=body, sender_phone=from_number);
        if result.reports {
            triage_result = result.reports[0];
            msg_entry["triage"] = triage_result;
            if msg_sid {
                _triage_by_sid[msg_sid] = triage_result;
            }
            print("Triage result: " + str(triage_result));

            log_walker_run("triage", triage_result.get("unit", ""), {"message": body, "phone": from_number}, triage_result);

            # If maintenance was processed, send SMS notifications
            if triage_result.get("event_type") == "maintenance" and triage_result.get("result") {
                maint = triage_result["result"];

                log_walker_run("handle_maintenance", triage_result.get("unit", ""), {"message": body}, maint);
                create_notification("approval_required", maint, maint.get("ticket_id", ""));

                # Store for landlord YES/NO reply
                _pending_ticket = {
                    "ticket_id": maint.get("ticket_id", ""),
                    "tenant_phone": maint.get("tenant_phone", ""),
                    "vendor": maint.get("vendor", ""),
                    "unit": triage_result.get("unit", ""),
                    "property": triage_result.get("property", "")
                };

                # Send tenant acknowledgment
                if maint.get("tenant_reply") and maint.get("tenant_phone") {
                    send_sms(maint["tenant_phone"], maint["tenant_reply"]);
                }

                # Send owner alert with approval instructions
                if alert_num and maint.get("owner_alert") {
                    owner_msg = maint["owner_alert"] + " — Reply YES to approve or NO to reject.";
                    send_sms(alert_num, owner_msg);
                }
            }
        }
    } except Exception as e {
        print("Triage pipeline error: " + str(e));
    }

    messages.insert(0, msg_entry);

    if alert_num and not triage_result {
        try {
            account_sid = getenv("TWILIO_ACCOUNT_SID");
            auth_token = getenv("TWILIO_AUTH_TOKEN");
            from_twilio = getenv("TWILIO_PHONE_NUMBER");
            if account_sid and auth_token and from_twilio {
                client = Client(account_sid, auth_token);
                client.messages.create(
                    body="New message from " + from_number + ": " + body,
                    from_=from_twilio,
                    to=alert_num,
                );
                print("Alert forwarded to " + alert_num);
            }
        } except Exception as e {
            print("Failed to forward alert: " + str(e));
        }
    }

    return Response(
        content="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Response></Response>",
        media_type="application/xml"
    );
}

walker run_triage_for_message {
    has body: str = "";
    has from_number: str = "";
    has msg_sid: str = "";

    can process with Root entry {
        try {
            root spawn triage(message=self.body, sender_phone=self.from_number);
            # triage's report() propagates automatically into this walker's reports
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
    }
}


walker run_maintenance_direct {
    has body: str = "";
    has from_number: str = "";

    can process with Root entry {
        try {
            found = False;
            for p in [here -->][?:Property] {
                if found { break; }
                for u in [p -->][?:Unit] {
                    if found { break; }
                    for l in [u -->][?:Lease] {
                        if found { break; }
                        for t in [l -->][?:Tenant] {
                            if t.phone == self.from_number {
                                found = True;
                                print("[run_maintenance_direct] matched tenant=" + t.name + " unit=" + u.number + " property=" + p.name);
                                # Inner spawn: handle_maintenance's report propagates into this walker's reports
                                u spawn handle_maintenance(
                                    message=self.body,
                                    tenant_name=t.name,
                                    tenant_phone=t.phone,
                                    property_name=p.name
                                );
                                disengage;
                            }
                        }
                    }
                }
            }
            if not found {
                print("[run_maintenance_direct] tenant not found for phone=" + self.from_number);
                report {"success": False, "error": "Tenant not found for " + self.from_number};
            }
        } except Exception as e {
            print("[run_maintenance_direct] error: " + str(e));
            report {"success": False, "error": str(e)};
        }
    }
}


walker maintenance_phase1 {
    has body: str = "";
    has from_number: str = "";

    can process with Root entry {
        try {
            for p in [here -->][?:Property] {
                for u in [p -->][?:Unit] {
                    for l in [u -->][?:Lease] {
                        for t in [l -->][?:Tenant] {
                            if t.phone == self.from_number {
                                print("[maintenance_phase1] diagnosing for tenant=" + t.name);
                                t0 = datetime.now();
                                diagnosis = diagnose_issue(self.body);
                                ms = int((datetime.now() - t0).total_seconds() * 1000);
                                print("[maintenance_phase1] category=" + diagnosis.category + " urgency=" + diagnosis.urgency + " (" + str(ms) + "ms)");
                                report {
                                    "step": "diagnosed",
                                    "tenant": t.name,
                                    "property": p.name,
                                    "unit": u.number,
                                    "category": diagnosis.category,
                                    "urgency": diagnosis.urgency,
                                    "summary": diagnosis.summary,
                                    "recommended_action": diagnosis.recommended_action,
                                    "timings": {"entity_ms": 1, "classify_ms": ms, "urgency_ms": ms, "diagnose_ms": ms}
                                };
                                disengage;
                            }
                        }
                    }
                }
            }
            report {"step": "not_found", "error": "Tenant not found for " + self.from_number};
        } except Exception as e {
            print("[maintenance_phase1] error: " + str(e));
            report {"step": "error", "error": str(e)};
        }
    }
}


def:pub send_maintenance_alert(maint_result: dict, msg_sid: str = "") -> dict {
    alert_num = getenv("TWILIO_TARGET_PHONE_NUMBER") or _alert_number or "+15199992505";
    try {
        if maint_result and maint_result.get("owner_alert") {
            owner_msg = str(maint_result["owner_alert"]) + " — Reply YES to approve or NO to reject.";
            send_sms(alert_num, owner_msg);
            print("[send_maintenance_alert] owner alert sent to " + alert_num);
        }
        if maint_result and maint_result.get("tenant_reply") and maint_result.get("tenant_phone") {
            send_sms(str(maint_result["tenant_phone"]), str(maint_result["tenant_reply"]));
            print("[send_maintenance_alert] tenant reply sent to " + str(maint_result["tenant_phone"]));
        }
        _pending_ticket = {
            "ticket_id": maint_result.get("ticket_id", "") if maint_result else "",
            "tenant_phone": maint_result.get("tenant_phone", "") if maint_result else "",
            "vendor": maint_result.get("vendor", "") if maint_result else "",
            "unit": maint_result.get("unit", "") if maint_result else "",
            "property": maint_result.get("property", "") if maint_result else "",
            "msg_sid": msg_sid
        };
        # Populate _triage_by_sid so YES/NO updates are visible on next poll
        if msg_sid and maint_result {
            _triage_by_sid[msg_sid] = {
                "status": "processed",
                "event_type": "maintenance",
                "result": maint_result
            };
        }
        print("[send_maintenance_alert] pending_ticket=" + _pending_ticket["ticket_id"] + " sid=" + msg_sid);
        return {"success": True};
    } except Exception as e {
        print("[send_maintenance_alert] error: " + str(e));
        return {"success": False, "error": str(e)};
    }
}


walker seed_if_empty {
    can run with Root entry {
        # Use direct graph traversal — avoids inner-spawn report propagation bug
        existing = [here -->][?:Property];
        if existing and len(existing) > 0 {
            report {"status": "already_seeded", "count": len(existing)};
            disengage;
        }
        #*
        root spawn add_property_node(name="Harbor Point Apts", address="221 Lakeview Dr", unit_numbers=["1A", "2B", "3C"]);
        root spawn add_property_node(name="Maple Street House", address="845 Maple St", unit_numbers=["Unit 1", "Unit 2"]);
        root spawn add_property_node(name="Oak View Complex", address="560 Oak Ave", unit_numbers=["101", "102", "201"]);
        root spawn register_tenant(tenant_name="John Smith", tenant_phone="+15551001001", unit_number="1A", rent_amount=1400.0, lease_start="2025-01-01", lease_end="2026-12-31", property_name="Harbor Point Apts");
        root spawn register_tenant(tenant_name="Sarah Johnson", tenant_phone="+15551001002", unit_number="2B", rent_amount=1600.0, lease_start="2025-01-01", lease_end="2026-12-31", property_name="Harbor Point Apts");
        root spawn register_tenant(tenant_name="Mike Lee", tenant_phone="+15551001003", unit_number="Unit 1", rent_amount=1200.0, lease_start="2025-01-01", lease_end="2026-12-31", property_name="Maple Street House");
        root spawn register_tenant(tenant_name="Emily Chen", tenant_phone="+15551001004", unit_number="101", rent_amount=950.0, lease_start="2025-01-01", lease_end="2026-12-31", property_name="Oak View Complex");
        *#
        report {"status": "seeded", "properties": 3, "tenants": 4};
    }
}


walker fetch_properties {
    can list with Root entry {
        result = [];
        for p in [here -->][?:Property] {
            units = [p -->][?:Unit];
            result.append({
                "id": jid(p),
                "name": p.name,
                "address": p.address,
                "city": p.city,
                "state": p.state,
                "unit_count": len(units)
            });
        }
        report {"properties": result};
    }
}


walker fetch_tenants {
    can list with Root entry {
        result = [];
        for p in [here -->][?:Property] {
            for u in [p -->][?:Unit] {
                for l in [u -->][?:Lease] {
                    for t in [l -->][?:Tenant] {
                        result.append({
                            "id": jid(t),
                            "full_name": t.name,
                            "phone_number": t.phone,
                            "unit_number": u.number,
                            "property_id": jid(p),
                            "property_name": p.name,
                            "rent": str(l.rent_amount),
                            "lease_end": l.end_date
                        });
                    }
                }
            }
        }
        report {"tenants": result};
    }
}


walker save_property_data {
    has name: str = "";
    has address: str = "";

    can create with Root entry {
        if not self.name {
            report {"status": "error", "message": "Property name is required"};
            disengage;
        }
        result = root spawn add_property_node(name=self.name, address=self.address);
        if result and result.reports {
            report result.reports[0];
        } else {
            report {"status": "error", "message": "No result"};
        }
    }
}


walker save_tenant_data {
    has tenant_name: str = "";
    has tenant_phone: str = "";
    has unit_number: str = "";
    has rent_amount: float = 0.0;
    has property_name: str = "";

    can create with Root entry {
        if not (self.tenant_name and self.tenant_phone and self.unit_number and self.property_name) {
            report {"status": "error", "message": "All fields are required"};
            disengage;
        }
        result = root spawn register_tenant(
            tenant_name=self.tenant_name,
            tenant_phone=self.tenant_phone,
            unit_number=self.unit_number,
            rent_amount=self.rent_amount,
            lease_start="2025-01-01",
            lease_end="2026-12-31",
            property_name=self.property_name
        );
        if result and result.reports {
            report result.reports[0];
        } else {
            report {"status": "error", "message": "No result"};
        }
    }
}


def:pub delete_property_data(property_id: str) -> dict {
    try {
        result = root spawn delete_property_node(property_id=property_id);
        if result and result.reports {
            return result.reports[0];
        }
        return {"status": "deleted"};
    } except Exception as e {
        print("delete_property_data error: " + str(e));
        return {"status": "error", "message": str(e)};
    }
}


def:pub delete_tenant_data(tenant_id: str) -> dict {
    try {
        result = root spawn delete_tenant_node(tenant_id=tenant_id);
        if result and result.reports {
            return result.reports[0];
        }
        return {"status": "deleted"};
    } except Exception as e {
        print("delete_tenant_data error: " + str(e));
        return {"status": "error", "message": str(e)};
    }
}

def:pub delete_message(msg_id: str) -> dict {
    try {
        load_dotenv();
        sid = str(msg_id).replace("INC-", "");
        account_sid = getenv("TWILIO_ACCOUNT_SID");
        auth_token = getenv("TWILIO_AUTH_TOKEN");
        if sid.startswith("SM") and account_sid and auth_token {
            client = Client(account_sid, auth_token);
            client.messages(sid).delete();
            print("Deleted Twilio message " + sid);
            return {"success": True};
        } else {
            for i in range(len(messages)) {
                if messages[i].get("sid", "") == sid or str(messages[i].get("id", "")) == sid {
                    messages.pop(i);
                    return {"success": True};
                }
            }
            # Fallback for old memory mock
            for i in range(len(messages)) {
                messages.pop(i);
                return {"success": True};
            }
        }
    } except Exception as e {
        return {"success": False, "error": str(e)};
    }
    return {"success": False, "error": "Not found"};
}
