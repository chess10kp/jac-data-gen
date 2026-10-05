#* Inocula C2 — Attacker Control Plane (Laptop B)
   Phase 1 skeleton. Walker shapes mirror shared/protocol.md §5 "C2" and the
   Scout→C2 / C2→Sentinel / Sentinel→C2 contracts in §1, §2, §4.

   Phase 1 scope:
     - Graph + walker endpoints + cl{} attack dashboard
     - OODA state machine transitions based on scan evidence
     - NO real firing. run_operation() just arms + logs. Tracks are stubs.
     - Real orchestration lands in Phase 4 via tracks/track_stealth.jac and
       tracks/track_noisy.jac. *#

import sys;
import os;
import time;
import json;
import datetime;

import from adapters.track_ops { fire_stealth as track_fire_stealth, fire_noisy as track_fire_noisy, plan_operation as track_plan, adapter_healthcheck as track_adapter_healthcheck }

# ── Utility helpers ──────────────────────────────────────────────────────

def now_utc() -> str {
    return datetime.datetime.utcnow().isoformat() + "Z";
}

def cap_event_log(log: list, cap: int) -> list {
    if len(log) > cap {
        return log[-cap:];
    }
    return log;
}

# ── Graph schema ─────────────────────────────────────────────────────────

node C2Node {
    has operator_id: str = "inocula-c2",
        ooda_phase: str = "observe",
        current_track: str = "stealth",
        armed: bool = False,
        auto: bool = False,
        target_mac: str = "",
        target_name: str = "",
        target_rssi: int = 0,
        last_scan_utc: str = "",
        last_scan_device_count: int = 0,
        trigger_count: int = 0,
        last_trigger_utc: str = "",
        last_trigger_epoch: float = 0.0,
        cooldown_seconds: float = 90.0,
        event_log: list = [],
        rssi_min_trigger: int = -55,
        idle_required: bool = True,
        op_state: str = "idle",
        last_operation_id: str = "",
        last_operation_result: dict = {};
}

node PiNode {
    has pi_id: str = "",
        last_seen_utc: str = "",
        last_ip: str = "",
        scan_count: int = 0,
        alive: bool = False;
}

node VictimNode {
    has victim_id: str = "",
        sentinel_url: str = "",
        last_status_utc: str = "",
        idle_seconds: float = 0.0,
        defense_phase: str = "unknown",
        connected_device_count: int = 0;
}

edge ScoutEdge {}
edge TargetEdge {}

# ── Shared helpers ───────────────────────────────────────────────────────

def append_event(c2: C2Node, kind: str, payload: dict) {
    `entry: dict = {"at": now_utc(), "kind": kind, "data": payload};
    c2.event_log = cap_event_log(c2.event_log + [`entry], 200);
}

def pi_summary(p: PiNode) -> dict {
    return {
        "pi_id": p.pi_id,
        "last_ip": p.last_ip,
        "alive": p.alive,
        "last_seen_utc": p.last_seen_utc,
        "scan_count": p.scan_count
    };
}

def victim_summary(v: VictimNode) -> dict {
    return {
        "victim_id": v.victim_id,
        "idle_seconds": v.idle_seconds,
        "defense_phase": v.defense_phase,
        "connected_device_count": v.connected_device_count,
        "last_status_utc": v.last_status_utc
    };
}

def is_interesting_target(name: str) -> bool {
    #* Phase 1 target heuristic: match common HID + audio peripheral names.
       Includes ghostshield's short-code conventions ("km" for mouse-kits,
       "kb" for keyboard kits) so devices like "Samsers KM01-M" resolve
       without additional WinRT metadata. *#
    nl: str = name.lower();
    if "mouse" in nl { return True; }
    if "keyboard" in nl { return True; }
    if "buds" in nl { return True; }
    if "km01" in nl { return True; }
    if " km" in nl { return True; }
    if "kb01" in nl { return True; }
    return False;
}

def select_target(devices: list, rssi_min_trigger: int) -> dict {
    #* Pick the highest-RSSI device whose name matches our target kinds
       and whose RSSI meets the trigger threshold. Returns {} if none. *#
    best: dict = {};
    best_rssi: int = -999;
    for dev in devices {
        name: str = dev.get("name", "");
        if name == "" { continue; }
        rssi_raw = dev.get("rssi", -999);
        rssi_val: int = int(rssi_raw);
        if rssi_val < rssi_min_trigger { continue; }
        if not is_interesting_target(name) { continue; }
        if rssi_val > best_rssi {
            best_rssi = rssi_val;
            best = {
                "name": name,
                "mac": dev.get("mac", ""),
                "rssi": rssi_val,
                "addr_type": dev.get("addr_type", "")
            };
        }
    }
    return best;
}

def compute_ooda_phase(c2: C2Node) -> str {
    if c2.target_mac == "" {
        return "observe";
    }
    if not c2.armed {
        return "orient";
    }
    if c2.trigger_count == 0 {
        return "decide";
    }
    return "act";
}

def cooldown_remaining(c2: C2Node) -> float {
    if c2.last_trigger_epoch <= 0.0 {
        return 0.0;
    }
    elapsed: float = time.time() - c2.last_trigger_epoch;
    remaining: float = c2.cooldown_seconds - elapsed;
    if remaining < 0.0 {
        return 0.0;
    }
    return float(int(remaining * 10.0)) / 10.0;
}

def load_env(key: str, fallback: str) -> str {
    val = os.environ.get(key, fallback);
    if val is None {
        return fallback;
    }
    return val;
}

# ── Walkers — REST endpoints ─────────────────────────────────────────────
# All walker:pub are served at POST /walker/<name>

walker:pub get_c2_state {
    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can collect with C2Node entry {
        scouts = [here ->:ScoutEdge:->][?:PiNode];
        victims = [here ->:TargetEdge:->][?:VictimNode];
        scout_list: list = [];
        for s in scouts { scout_list.append(pi_summary(s)); }
        victim_list: list = [];
        for v in victims { victim_list.append(victim_summary(v)); }

        target_obj: dict = {};
        if here.target_mac != "" {
            target_obj = {
                "name": here.target_name,
                "mac": here.target_mac,
                "rssi": here.target_rssi
            };
        }

        report {
            "operator_id": here.operator_id,
            "ooda_phase": here.ooda_phase,
            "current_track": here.current_track,
            "armed": here.armed,
            "auto": here.auto,
            "target": target_obj,
            "last_scan_utc": here.last_scan_utc,
            "last_scan_device_count": here.last_scan_device_count,
            "trigger_count": here.trigger_count,
            "last_trigger_utc": here.last_trigger_utc,
            "cooldown_seconds": here.cooldown_seconds,
            "cooldown_remaining_s": cooldown_remaining(here),
            "rssi_min_trigger": here.rssi_min_trigger,
            "idle_required": here.idle_required,
            "op_state": here.op_state,
            "last_operation_id": here.last_operation_id,
            "last_operation_result": here.last_operation_result,
            "event_log": here.event_log[-50:],
            "scouts": scout_list,
            "victims": victim_list,
            "now_utc": now_utc()
        };
    }
}

walker:pub report_scan {
    #* Scout → C2 contract (see shared/protocol.md §1). Updates pi-as-node,
       selects a target, transitions OODA phase. Does NOT fire anything. *#
    has pi_ip: str = "",
        scan_updated_utc: str = "",
        rssi_min_dbm: int = 0,
        scan_duration_s: int = 0,
        devices: list = [],
        classic: list = [];

    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can handle with C2Node entry {
        # 1. Find-or-create PiNode keyed by pi_ip
        scouts = [here ->:ScoutEdge:->][?:PiNode];
        matches = [s for s in scouts if s.last_ip == self.pi_ip or s.pi_id == self.pi_ip];
        if len(matches) == 0 {
            new_pi = PiNode(pi_id=self.pi_ip, last_ip=self.pi_ip);
            here +>:ScoutEdge():+> new_pi;
            pi_ref = new_pi;
        } else {
            pi_ref = matches[0];
        }
        pi_ref.last_ip = self.pi_ip;
        pi_ref.last_seen_utc = self.scan_updated_utc if self.scan_updated_utc != "" else now_utc();
        pi_ref.scan_count = pi_ref.scan_count + 1;
        pi_ref.alive = True;

        # 2. Update C2 scan state
        here.last_scan_utc = pi_ref.last_seen_utc;
        here.last_scan_device_count = len(self.devices);

        # 3. Target selection — highest-RSSI matching device above threshold
        chosen = select_target(self.devices, here.rssi_min_trigger);
        if len(chosen) > 0 {
            here.target_name = chosen.get("name", "");
            here.target_mac = chosen.get("mac", "");
            here.target_rssi = int(chosen.get("rssi", 0));
        } else {
            here.target_name = "";
            here.target_mac = "";
            here.target_rssi = 0;
        }

        # 4. OODA phase transition (Phase 1 simple logic)
        here.ooda_phase = compute_ooda_phase(here);

        # 5. Append event
        append_event(here, "scan", {
            "pi": self.pi_ip,
            "devices": len(self.devices),
            "classic": len(self.classic),
            "selected": here.target_name,
            "phase": here.ooda_phase
        });

        # 6. Response per protocol §1
        resp_target: dict = {};
        if here.target_mac != "" {
            resp_target = {
                "name": here.target_name,
                "mac": here.target_mac,
                "reason": "rssi " + str(here.target_rssi) + " >= " + str(here.rssi_min_trigger)
            };
        }
        report {
            "devices_received": len(self.devices),
            "c2_phase": here.ooda_phase,
            "target": resp_target,
            "next_poll_seconds": 10
        };
    }
}

walker:pub run_operation {
    #* Phase 4: real orchestration. Dispatches to track_ops.py adapters.
       Honors cooldown. Supports dry_run for safe UI preview. *#
    has track: str = "",
        dry_run: bool = False,
        force: bool = False;

    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can fire with C2Node entry {
        valid_tracks = ["stealth", "noisy", "both"];
        if self.track not in valid_tracks {
            report {
                "started": False,
                "error": "invalid track — must be one of stealth|noisy|both",
                "track": self.track
            };
            disengage;
        }

        # Cooldown gate — skip on dry_run and skip on force.
        remaining = cooldown_remaining(here);
        if (not self.dry_run) and (not self.force) and remaining > 0.0 {
            append_event(here, "run_operation", {
                "track": self.track,
                "rejected": "cooldown",
                "cooldown_remaining_s": remaining
            });
            report {
                "started": False,
                "error": "cooldown",
                "cooldown_remaining_s": remaining,
                "track": self.track
            };
            disengage;
        }

        here.current_track = self.track;
        here.armed = True;
        here.auto = True;
        op_id = "op_" + str(int(time.time()));
        here.last_operation_id = op_id;
        here.op_state = ("planning" if self.dry_run else "firing");

        append_event(here, "run_operation", {
            "track": self.track,
            "operation_id": op_id,
            "dry_run": self.dry_run,
            "force": self.force
        });

        # ── Dispatch ─────────────────────────────────────────────
        sentinel_url = load_env("INOCULA_SENTINEL_URL", "");
        token = load_env("INOCULA_TOKEN", "");
        pi_host = load_env("INOCULA_PI_SSH_HOST", "");

        steps: list = [];
        final_ok = True;

        if self.track == "stealth" {
            stealth_res = track_fire_stealth(
                sentinel_url=sentinel_url,
                token=token,
                operation_id=op_id,
                force=self.force,
                dry_run=self.dry_run
            );
            steps.append({"kind": "stealth", "result": stealth_res});
            if not stealth_res.get("ok", False) {
                final_ok = False;
            }
        } elif self.track == "noisy" {
            if here.target_mac == "" {
                steps.append({"kind": "noisy", "result": {"ok": False, "error": "no target locked"}});
                final_ok = False;
            } else {
                noisy_res = track_fire_noisy(
                    target_mac=here.target_mac,
                    pi_ssh_host=pi_host,
                    dry_run=self.dry_run
                );
                steps.append({"kind": "noisy", "result": noisy_res});
                if not noisy_res.get("ok", False) {
                    final_ok = False;
                }
            }
        } else {
            # "both" — noisy first, chain stealth as impact
            noisy_res: dict = {};
            if here.target_mac == "" {
                noisy_res = {"ok": False, "error": "no target locked"};
                final_ok = False;
            } else {
                noisy_res = track_fire_noisy(
                    target_mac=here.target_mac,
                    pi_ssh_host=pi_host,
                    dry_run=self.dry_run
                );
            }
            steps.append({"kind": "noisy", "result": noisy_res});
            stealth_res = track_fire_stealth(
                sentinel_url=sentinel_url,
                token=token,
                operation_id=op_id,
                force=self.force,
                dry_run=self.dry_run
            );
            steps.append({"kind": "stealth", "result": stealth_res});
            if not stealth_res.get("ok", False) {
                final_ok = False;
            }
        }

        # Record outcome. dry_run does NOT advance the cooldown clock or
        # bump trigger_count — it is literally a preview.
        if not self.dry_run {
            here.trigger_count = here.trigger_count + 1;
            here.last_trigger_epoch = time.time();
            here.last_trigger_utc = now_utc();
        }
        here.op_state = "done";
        here.last_operation_result = {
            "operation_id": op_id,
            "track": self.track,
            "dry_run": self.dry_run,
            "ok": final_ok,
            "steps": steps,
            "at_utc": now_utc()
        };
        append_event(here, "operation_result", here.last_operation_result);
        here.ooda_phase = compute_ooda_phase(here);

        report {
            "started": True,
            "ok": final_ok,
            "track": self.track,
            "operation_id": op_id,
            "ooda_phase": here.ooda_phase,
            "dry_run": self.dry_run,
            "steps": steps,
            "trigger_count": here.trigger_count,
            "cooldown_remaining_s": cooldown_remaining(here)
        };
    }
}

walker:pub abort_operation {
    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can kill with C2Node entry {
        here.armed = False;
        here.auto = False;
        append_event(here, "abort_operation", {"note": "kill switch engaged"});
        here.ooda_phase = compute_ooda_phase(here);
        report {"aborted": True, "ooda_phase": here.ooda_phase};
    }
}

walker:pub configure {
    #* Each field uses a sentinel default so callers can update any subset.
       idle_required is int-encoded (-1 unset, 0 false, 1 true) to keep the
       JSON contract simple. *#
    has target_mac: str = "",
        target_name: str = "",
        current_track: str = "",
        cooldown_seconds: float = -1.0,
        rssi_min_trigger: int = 999,
        idle_required: int = -1;

    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can apply with C2Node entry {
        changes: dict = {};
        if self.target_mac != "" {
            here.target_mac = self.target_mac;
            changes["target_mac"] = self.target_mac;
        }
        if self.target_name != "" {
            here.target_name = self.target_name;
            changes["target_name"] = self.target_name;
        }
        if self.current_track != "" {
            here.current_track = self.current_track;
            changes["current_track"] = self.current_track;
        }
        if self.cooldown_seconds != -1.0 {
            here.cooldown_seconds = self.cooldown_seconds;
            changes["cooldown_seconds"] = self.cooldown_seconds;
        }
        if self.rssi_min_trigger != 999 {
            here.rssi_min_trigger = self.rssi_min_trigger;
            changes["rssi_min_trigger"] = self.rssi_min_trigger;
        }
        if self.idle_required != -1 {
            here.idle_required = (self.idle_required == 1);
            changes["idle_required"] = here.idle_required;
        }
        append_event(here, "configure", changes);
        here.ooda_phase = compute_ooda_phase(here);
        report {
            "updated": changes,
            "current": {
                "target_mac": here.target_mac,
                "target_name": here.target_name,
                "current_track": here.current_track,
                "cooldown_seconds": here.cooldown_seconds,
                "rssi_min_trigger": here.rssi_min_trigger,
                "idle_required": here.idle_required
            }
        };
    }
}

walker:pub operation_dryrun {
    #* Returns what a live run_operation would do, without side-effects.
       Backs the UI "DRY RUN" button and the test harness. *#
    has track: str = "stealth";

    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can plan with C2Node entry {
        valid_tracks = ["stealth", "noisy", "both"];
        if self.track not in valid_tracks {
            report {"ok": False, "error": "invalid track", "track": self.track};
            disengage;
        }
        mac = here.target_mac if here.target_mac != "" else "AA:BB:CC:DD:EE:FF";
        plan = track_plan(self.track, mac);
        report {
            "ok": True,
            "track": self.track,
            "has_target": (here.target_mac != ""),
            "plan": plan,
            "cooldown_remaining_s": cooldown_remaining(here)
        };
    }
}

walker:pub status {
    #* Thin status endpoint for dashboard polling. Same data as
       get_c2_state but without the cost of rebuilding scout/victim
       summaries — used by the cooldown tick loop. *#
    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can snap with C2Node entry {
        report {
            "ooda_phase": here.ooda_phase,
            "armed": here.armed,
            "current_track": here.current_track,
            "trigger_count": here.trigger_count,
            "last_trigger_utc": here.last_trigger_utc,
            "cooldown_seconds": here.cooldown_seconds,
            "cooldown_remaining_s": cooldown_remaining(here),
            "op_state": here.op_state,
            "last_operation_id": here.last_operation_id,
            "has_target": (here.target_mac != ""),
            "now_utc": now_utc()
        };
    }
}

walker:pub sentinel_alert {
    #* Sentinel → C2 webhook (see shared/protocol.md §4). *#
    has sentinel: str = "",
        severity: str = "",
        summary: str = "",
        signals: list = [],
        at_utc: str = "";

    can enter with Root entry {
        existing = [-->[?:C2Node]];
        if len(existing) == 0 {
            here ++> C2Node();
        }
        visit [-->[?:C2Node]];
    }
    can record with C2Node entry {
        append_event(here, "sentinel_alert", {
            "sentinel": self.sentinel,
            "severity": self.severity,
            "summary": self.summary,
            "signals": self.signals,
            "at_utc": (self.at_utc if self.at_utc != "" else now_utc())
        });
        report {"ack": True};
    }
}

# ── Seed graph on boot ───────────────────────────────────────────────────

with entry {
    existing = [root-->[?:C2Node]];
    if len(existing) == 0 {
        c2 = root ++> C2Node();
    }
    t_hc = track_adapter_healthcheck();
    print("=== Inocula C2 track adapter:", t_hc);
    print("=== Inocula C2 Ready (port 8788) ===");
}

# ══════════════════════════════════════════════════════════════════════════
# CLIENT — Inocula C2 Operator Console
# Aesthetic mirrors ghostshield SOC terminal. Only "Inocula" appears in UI.
# ══════════════════════════════════════════════════════════════════════════

import from "react" { useEffect, useRef }
import from "lucide-react" { Activity, AlertTriangle, Radio, Target, Terminal, Crosshair, Zap, Power }


def:pub app -> JsxElement {
    has operator_id: str = "inocula-c2",
        ooda_phase: str = "observe",
        current_track: str = "stealth",
        armed: bool = False,
        auto: bool = False,
        target: dict = {},
        last_scan_utc: str = "",
        last_scan_device_count: int = 0,
        trigger_count: int = 0,
        cooldown_seconds: float = 90.0,
        cooldown_remaining_s: float = 0.0,
        op_state: str = "idle",
        last_operation_result: dict = {},
        scouts: list = [],
        victims: list = [],
        event_log: list = [],
        now_utc_val: str = "",
        selected_track: str = "stealth",
        last_status: str = "",
        op_busy: bool = False,
        loaded: bool = False;

    log_ref = useRef(None);

    async def fetchState {
        result = root spawn get_c2_state();
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            operator_id = r.operator_id or "inocula-c2";
            ooda_phase = r.ooda_phase or "observe";
            current_track = r.current_track or "stealth";
            armed = r.armed or False;
            auto = r.auto or False;
            target = r.target or {};
            last_scan_utc = r.last_scan_utc or "";
            last_scan_device_count = r.last_scan_device_count or 0;
            trigger_count = r.trigger_count or 0;
            cooldown_seconds = r.cooldown_seconds or 90.0;
            cooldown_remaining_s = r.cooldown_remaining_s or 0.0;
            op_state = r.op_state or "idle";
            last_operation_result = r.last_operation_result or {};
            scouts = r.scouts or [];
            victims = r.victims or [];
            event_log = r.event_log or [];
            now_utc_val = r.now_utc or "";
        }
    }

    async def doInit {
        if loaded { return; }
        loaded = True;
        fetchState();
    }

    useEffect(lambda { doInit(); }, []);

    useEffect(lambda {
        iv = setInterval(lambda { fetchState(); }, 2000);
        return lambda { clearInterval(iv); };
    }, []);

    useEffect(lambda {
        if log_ref.current {
            log_ref.current.scrollTop = log_ref.current.scrollHeight;
        }
    }, [len(event_log)]);

    async def doRunOperation(track_arg: str) {
        if not target or not target.get("mac") { return; }
        if op_busy { return; }
        op_busy = True;
        last_status = "Firing " + track_arg + " — contacting sentinel/scout...";
        selected_track = track_arg;
        result = root spawn run_operation(track=track_arg, dry_run=False, force=False);
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            if r.started {
                last_status = "OPERATION " + (r.operation_id or "?") + " fired — track=" + (r.track or "?") + " ok=" + str(r.ok or False);
            } else {
                reason = r.error or "unknown";
                if reason == "cooldown" {
                    last_status = "BLOCKED: cooldown " + str(r.cooldown_remaining_s or 0) + "s remaining";
                } else {
                    last_status = "REJECTED: " + str(reason);
                }
            }
        }
        op_busy = False;
        fetchState();
    }

    async def doDryRun(track_arg: str) {
        if op_busy { return; }
        op_busy = True;
        last_status = "Planning dry-run on track " + track_arg + "...";
        selected_track = track_arg;
        result = root spawn operation_dryrun(track=track_arg);
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            last_status = "DRY RUN complete — track=" + track_arg + ", steps=" + str((r.plan and r.plan.steps and len(r.plan.steps)) or 0);
        }
        op_busy = False;
        fetchState();
    }

    async def doAbort {
        last_status = "ABORT requested";
        result = root spawn abort_operation();
        if result.reports and len(result.reports) > 0 {
            last_status = "OPERATION ABORTED — kill switch engaged";
        }
        fetchState();
    }

    def selectTrack(t: str) {
        selected_track = t;
    }

    # Palette (mirrors ghostshield)
    cs = "#00ff88";
    ca = "#ff3355";
    cw = "#ffaa00";
    cb = "#06b6d4";
    cdim = "#556";

    # OODA pill helper values
    phases = ["observe", "orient", "decide", "act"];

    has_target = target and target.get("mac");
    target_name_disp = (target and target.get("name")) or "";
    target_mac_disp = (target and target.get("mac")) or "";
    target_rssi_disp = (target and target.get("rssi"));

    return
        <div style={{"background": "#0a0a14", "color": "#c0c8d0", "fontFamily": "'JetBrains Mono', 'Fira Code', monospace", "minHeight": "100vh", "fontSize": "12px"}}>
            <style>{"@keyframes pulse{0%,100%{opacity:1}50%{opacity:0.35}} @keyframes glow{0%,100%{boxShadow:0 0 6px currentColor}50%{boxShadow:0 0 18px currentColor}} .pulse{animation:pulse 2s infinite}"}</style>

            <div style={{"background": "#0d0d1a", "borderBottom": "1px solid #1a1a2e", "padding": "14px 24px", "display": "flex", "justifyContent": "space-between", "alignItems": "center"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "16px"}}>
                    <Terminal size={18} color={ca} />
                    <span style={{"fontSize": "16px", "fontWeight": "800", "color": "#fff", "letterSpacing": "3px"}}>INOCULA C2</span>
                    <span style={{"fontSize": "11px", "color": cdim, "letterSpacing": "2px"}}>OPERATOR CONSOLE</span>
                    <span style={{"background": ((ca + "30") if armed else (cs + "20")), "color": (ca if armed else cs), "padding": "4px 14px", "borderRadius": "20px", "fontSize": "11px", "fontWeight": "700", "border": "1px solid " + (ca if armed else cs) + "50", "letterSpacing": "2px"}}>
                        {("● ARMED" if armed else "○ SAFE")}
                    </span>
                </div>
                <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "1px"}}>
                    {now_utc_val}
                </div>
            </div>

            <div style={{"padding": "14px 24px", "borderBottom": "1px solid #1a1a2e", "background": "#0b0b18"}}>
                <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "3px", "marginBottom": "10px"}}>OODA LOOP</div>
                <div style={{"display": "flex", "gap": "10px"}}>
                    {[
                        <div key={p} style={{
                            "flex": "1",
                            "padding": "14px 10px",
                            "textAlign": "center",
                            "background": ("#1a2a3a" if p == ooda_phase else "#0d0d1a"),
                            "border": "1px solid " + (cs if p == ooda_phase else "#1a1a2e"),
                            "borderRadius": "4px",
                            "color": (cs if p == ooda_phase else "#445"),
                            "fontSize": "13px",
                            "fontWeight": "800",
                            "letterSpacing": "3px",
                            "textTransform": "uppercase",
                            "boxShadow": (("0 0 18px " + cs + "40") if p == ooda_phase else "none")
                        }} className={("pulse" if (p == ooda_phase and p == "act") else "")}>
                            {p}
                        </div>
                        for p in phases
                    ]}
                </div>
            </div>

            <div style={{"padding": "14px 24px", "borderBottom": "1px solid #1a1a2e", "display": "flex", "gap": "24px"}}>
                <div>
                    <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "2px"}}>ARMED</div>
                    <div style={{"fontSize": "16px", "color": (ca if armed else "#aab"), "fontWeight": "800", "letterSpacing": "1px"}}>{("YES" if armed else "NO")}</div>
                </div>
                <div>
                    <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "2px"}}>TRACK</div>
                    <div style={{"fontSize": "16px", "color": "#fff", "fontWeight": "800", "letterSpacing": "1px"}}>{current_track}</div>
                </div>
                <div>
                    <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "2px"}}>TRIGGERS</div>
                    <div style={{"fontSize": "16px", "color": "#fff", "fontWeight": "800"}}>{str(trigger_count)}</div>
                </div>
                <div>
                    <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "2px"}}>SCOUTS</div>
                    <div style={{"fontSize": "16px", "color": "#fff", "fontWeight": "800"}}>{str(len(scouts))}</div>
                </div>
                <div style={{"flex": "1"}}>
                    <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "2px"}}>TARGET</div>
                    <div style={{"fontSize": "16px", "color": (cs if has_target else "#445"), "fontWeight": "800"}}>
                        {(target_name_disp if has_target else "— NONE —")}
                    </div>
                </div>
            </div>

            <div style={{"display": "flex", "height": "calc(100vh - 270px)"}}>
                <div style={{"flex": "1", "display": "flex", "flexDirection": "column", "padding": "18px 24px", "overflowY": "auto"}}>

                    <div style={{"background": "#0d0d1a", "border": "1px solid " + ((ca + "40") if has_target else "#1a1a2e"), "borderRadius": "8px", "padding": "18px", "marginBottom": "16px"}}>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "8px", "marginBottom": "12px"}}>
                            <Crosshair size={14} color={(ca if has_target else cdim)} />
                            <span style={{"fontSize": "11px", "color": (ca if has_target else cdim), "letterSpacing": "2px", "fontWeight": "700"}}>TARGET LOCK</span>
                        </div>
                        {has_target and
                            <div>
                                <div style={{"fontSize": "22px", "color": "#fff", "fontWeight": "800", "letterSpacing": "1px"}}>{target_name_disp}</div>
                                <div style={{"fontSize": "11px", "color": "#8af", "fontFamily": "monospace", "marginTop": "4px"}}>{target_mac_disp}</div>
                                <div style={{"fontSize": "11px", "color": cdim, "marginTop": "8px"}}>{"RSSI: "}<span style={{"color": cs, "fontWeight": "700"}}>{str(target_rssi_disp) + " dBm"}</span></div>
                            </div>
                        }
                        {not has_target and
                            <div style={{"fontSize": "20px", "color": "#445", "fontWeight": "800", "letterSpacing": "2px"}}>— NO TARGET —</div>
                        }
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "18px", "marginBottom": "16px"}}>
                        <div style={{"fontSize": "11px", "color": cs, "letterSpacing": "2px", "fontWeight": "700", "marginBottom": "12px"}}>TRACK SELECTOR</div>
                        <div style={{"display": "flex", "gap": "10px", "marginBottom": "14px"}}>
                            <button onClick={lambda { selectTrack("stealth"); }}
                                style={{"flex": "1", "padding": "14px 0", "background": ("#1a2a3a" if selected_track == "stealth" else "#0d0d1a"), "color": (cs if selected_track == "stealth" else "#aab"), "border": "1px solid " + (cs if selected_track == "stealth" else "#1a1a2e"), "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "13px", "fontWeight": "800", "letterSpacing": "3px"}}>
                                STEALTH
                            </button>
                            <button onClick={lambda { selectTrack("noisy"); }}
                                style={{"flex": "1", "padding": "14px 0", "background": ("#2a2a0a" if selected_track == "noisy" else "#0d0d1a"), "color": (cw if selected_track == "noisy" else "#aab"), "border": "1px solid " + (cw if selected_track == "noisy" else "#1a1a2e"), "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "13px", "fontWeight": "800", "letterSpacing": "3px"}}>
                                NOISY
                            </button>
                            <button onClick={lambda { selectTrack("both"); }}
                                style={{"flex": "1", "padding": "14px 0", "background": ("#2a0a1a" if selected_track == "both" else "#0d0d1a"), "color": (ca if selected_track == "both" else "#aab"), "border": "1px solid " + (ca if selected_track == "both" else "#1a1a2e"), "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "13px", "fontWeight": "800", "letterSpacing": "3px"}}>
                                BOTH
                            </button>
                        </div>
                        <div style={{"display": "flex", "gap": "10px"}}>
                            <button onClick={lambda { doRunOperation(selected_track); }}
                                disabled={(not has_target) or op_busy or (cooldown_remaining_s > 0.0)}
                                style={{"flex": "2", "padding": "18px 0", "background": (ca if (has_target and (cooldown_remaining_s <= 0.0)) else "#33111a"), "color": "#fff", "border": "1px solid " + (ca if (has_target and (cooldown_remaining_s <= 0.0)) else "#331111"), "borderRadius": "4px", "cursor": ("pointer" if (has_target and (cooldown_remaining_s <= 0.0)) else "not-allowed"), "fontFamily": "inherit", "fontSize": "15px", "fontWeight": "900", "letterSpacing": "4px", "boxShadow": (("0 0 16px " + ca + "40") if (has_target and (cooldown_remaining_s <= 0.0)) else "none")}}>
                                {("COOLDOWN " + str(int(cooldown_remaining_s)) + "s") if cooldown_remaining_s > 0.0 else "RUN OPERATION"}
                            </button>
                            <button onClick={lambda { doDryRun(selected_track); }}
                                disabled={op_busy}
                                style={{"flex": "1", "padding": "18px 0", "background": "#0d1a2a", "color": cb, "border": "1px solid " + cb + "60", "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "12px", "fontWeight": "800", "letterSpacing": "3px"}}>
                                DRY RUN
                            </button>
                            <button onClick={doAbort}
                                style={{"flex": "1", "padding": "18px 0", "background": "#1a1a2e", "color": "#aab", "border": "1px solid #333", "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "12px", "fontWeight": "800", "letterSpacing": "3px"}}>
                                ABORT
                            </button>
                        </div>
                        <div style={{"fontSize": "10px", "color": cdim, "letterSpacing": "1px", "marginTop": "10px"}}>
                            {last_status or "Awaiting operator command"}
                        </div>
                        {last_operation_result and last_operation_result.get("operation_id") and
                            <div style={{"marginTop": "12px", "padding": "10px", "background": "#050512", "border": "1px solid " + ((last_operation_result.get("ok") and cs or ca) + "40"), "borderRadius": "4px"}}>
                                <div style={{"fontSize": "9px", "color": cdim, "letterSpacing": "2px", "marginBottom": "4px"}}>LAST OPERATION</div>
                                <div style={{"fontSize": "11px", "color": "#fff", "fontFamily": "monospace"}}>
                                    {last_operation_result.get("operation_id")}
                                </div>
                                <div style={{"fontSize": "10px", "color": (last_operation_result.get("ok") and cs or ca), "marginTop": "4px", "fontWeight": "700", "letterSpacing": "1px"}}>
                                    {"track=" + (last_operation_result.get("track") or "?") + " · " + ("LANDED" if last_operation_result.get("ok") else "FAILED") + (" · DRY" if last_operation_result.get("dry_run") else "")}
                                </div>
                            </div>
                        }
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "14px", "marginBottom": "16px"}}>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "8px", "marginBottom": "10px"}}>
                            <Radio size={12} color={cb} />
                            <span style={{"fontSize": "11px", "color": cb, "letterSpacing": "2px", "fontWeight": "700"}}>SCOUTS</span>
                        </div>
                        <table style={{"width": "100%", "borderCollapse": "collapse", "fontSize": "11px"}}>
                            <thead>
                                <tr style={{"color": cdim, "textAlign": "left"}}>
                                    <th style={{"padding": "4px 8px"}}>PI_ID</th>
                                    <th style={{"padding": "4px 8px"}}>IP</th>
                                    <th style={{"padding": "4px 8px"}}>ALIVE</th>
                                    <th style={{"padding": "4px 8px"}}>LAST_SEEN</th>
                                    <th style={{"padding": "4px 8px"}}>SCANS</th>
                                </tr>
                            </thead>
                            <tbody>
                                {len(scouts) == 0 and
                                    <tr><td colSpan="5" style={{"padding": "12px 8px", "color": "#334", "textAlign": "center"}}>No scouts reporting</td></tr>
                                }
                                {[
                                    <tr key={s.pi_id} style={{"borderTop": "1px solid #111"}}>
                                        <td style={{"padding": "4px 8px", "color": "#aab", "fontFamily": "monospace"}}>{s.pi_id or "?"}</td>
                                        <td style={{"padding": "4px 8px", "color": "#8af", "fontFamily": "monospace"}}>{s.last_ip or "?"}</td>
                                        <td style={{"padding": "4px 8px", "color": (s.alive and cs or "#666")}}>{("● YES" if s.alive else "○ NO")}</td>
                                        <td style={{"padding": "4px 8px", "color": "#aab", "fontFamily": "monospace"}}>{s.last_seen_utc or "—"}</td>
                                        <td style={{"padding": "4px 8px", "color": "#fff"}}>{str(s.scan_count or 0)}</td>
                                    </tr>
                                    for s in scouts
                                ]}
                            </tbody>
                        </table>
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "14px"}}>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "8px", "marginBottom": "10px"}}>
                            <Target size={12} color={ca} />
                            <span style={{"fontSize": "11px", "color": ca, "letterSpacing": "2px", "fontWeight": "700"}}>VICTIMS</span>
                        </div>
                        <table style={{"width": "100%", "borderCollapse": "collapse", "fontSize": "11px"}}>
                            <thead>
                                <tr style={{"color": cdim, "textAlign": "left"}}>
                                    <th style={{"padding": "4px 8px"}}>VICTIM_ID</th>
                                    <th style={{"padding": "4px 8px"}}>IDLE_S</th>
                                    <th style={{"padding": "4px 8px"}}>DEFENSE_PHASE</th>
                                </tr>
                            </thead>
                            <tbody>
                                {len(victims) == 0 and
                                    <tr><td colSpan="3" style={{"padding": "12px 8px", "color": "#334", "textAlign": "center"}}>No victims tracked</td></tr>
                                }
                                {[
                                    <tr key={v.victim_id} style={{"borderTop": "1px solid #111"}}>
                                        <td style={{"padding": "4px 8px", "color": "#aab", "fontFamily": "monospace"}}>{v.victim_id or "?"}</td>
                                        <td style={{"padding": "4px 8px", "color": "#fff"}}>{str(v.idle_seconds or 0)}</td>
                                        <td style={{"padding": "4px 8px", "color": cs}}>{v.defense_phase or "unknown"}</td>
                                    </tr>
                                    for v in victims
                                ]}
                            </tbody>
                        </table>
                    </div>
                </div>

                <div style={{"width": "420px", "borderLeft": "1px solid #1a1a2e", "display": "flex", "flexDirection": "column"}}>
                    <div style={{"padding": "12px 16px", "borderBottom": "1px solid #1a1a2e", "display": "flex", "justifyContent": "space-between", "alignItems": "center"}}>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "8px"}}>
                            <Activity size={12} color={cb} />
                            <span style={{"color": cb, "fontSize": "11px", "fontWeight": "700", "letterSpacing": "2px"}}>EVENT LOG</span>
                        </div>
                        <span style={{"padding": "2px 8px", "borderRadius": "3px", "fontSize": "9px", "background": cb + "20", "color": cb, "border": "1px solid " + cb + "30"}}>{"LIVE · " + str(len(event_log))}</span>
                    </div>
                    <div ref={log_ref} style={{"flex": "1", "overflowY": "auto", "padding": "8px 12px", "background": "#050508", "fontFamily": "'JetBrains Mono', 'Fira Code', monospace"}}>
                        {len(event_log) == 0 and
                            <div style={{"color": "#334", "textAlign": "center", "padding": "24px 0", "fontSize": "11px"}}>
                                Awaiting telemetry...
                            </div>
                        }
                        {[
                            <div key={(e.at or "") + "-" + (e.kind or "")} style={{"padding": "2px 0", "lineHeight": "1.5", "fontSize": "10px"}}>
                                <span style={{"color": "#334"}}>{e.at or ""}</span>
                                <span style={{"color": "#556", "marginLeft": "6px"}}>{"[" + (e.kind or "") + "]"}</span>
                                <span style={{"color": (ca if (e.kind == "sentinel_alert") else (cw if (e.kind == "run_operation" or e.kind == "abort_operation") else cb)), "marginLeft": "6px"}}>
                                    {(e.data and e.data.note) or (e.data and e.data.summary) or (e.data and e.data.selected and ("target=" + str(e.data.selected) + " devices=" + str(e.data.devices or 0))) or (e.data and e.data.track and ("track=" + str(e.data.track))) or ""}
                                </span>
                            </div>
                            for e in event_log
                        ]}
                    </div>
                    <div style={{"padding": "10px 16px", "borderTop": "1px solid #1a1a2e", "fontSize": "9px", "color": "#445", "letterSpacing": "1px"}}>
                        <Zap size={10} color={cs} />
                        <span style={{"marginLeft": "6px"}}>{"Phase 4 · tracks live · " + op_state + " · cooldown " + str(int(cooldown_remaining_s)) + "s"}</span>
                    </div>
                </div>
            </div>
        </div>;
}
