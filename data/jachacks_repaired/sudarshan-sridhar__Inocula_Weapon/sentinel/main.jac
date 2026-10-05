#* Inocula Sentinel - Laptop A defense app (Phase 2: defense parity)

   Full port of ghostshield's detection graph, walkers, and SOC-terminal
   UI, rebranded to Inocula. Live BT data comes from the win_bt adapter
   (wraps doppelganger/system_utils.py). RSSI is sourced from an inline
   bleak BLE scan cached every 15s, same pattern as upstream ghostshield.

   Hard rules honored:
     - No `by llm()` calls.
     - No byllm / jac_cloud imports.
     - Only "Inocula" in user-visible strings.
     - Zero edits to ghostshield/ / doppelganger/ / doppelganger_poc/.
     - Walker REST shapes keep Phase 1 protocol.md compatibility.
*#

import sys;
import time;
import datetime;
import asyncio;
import concurrent.futures;

import from adapters.win_bt { get_idle_seconds, get_connected_bt_devices, get_os_type, adapter_healthcheck }
import from adapters.net_scan { list_listeners, list_lan_peers, classify_ip, own_lan_ips, trigger_log_recent, adapter_healthcheck as net_adapter_healthcheck }
import from adapters.proc_scan { list_recent_processes, detect_idle_cohort, detect_sendinput_burst, adapter_healthcheck as proc_adapter_healthcheck }
import from adapters.kill_listener { kill_listener_by_port, kill_process_by_name, block_ip_netsh, remediation_dryrun, adapter_healthcheck as remediate_adapter_healthcheck }
import from adapters.classify { classify as classify_attack, adapter_healthcheck as classify_adapter_healthcheck }
import os;
import json;
import pathlib;

glob IS_WIN: bool = "win32" in sys.platform;
glob IS_MAC: bool = "darwin" in sys.platform;

# Inline BLE RSSI cache (mirrors ghostshield's design). 15s TTL so
# we don't thrash the radio when the dashboard polls every 3s.
glob _ble_rssi_cache: dict = {};
glob _ble_cache_time: float = 0.0;

# Ring buffer of recent sentinel alerts for /walker/get_alerts + UI.
glob alert_log: list = [];

# ── Phase 3: Network + Process sentinel state ──────────────────────
# `trigger_payload_log_path` is where /walker/trigger_payload writes
# one NDJSON line per incoming request so NetworkSentinel can detect
# rogue POSTs after-the-fact. Path is relative to the sentinel cwd.
glob trigger_payload_log_path: str = ".jac/data/trigger_payload_access.ndjson";

# `sendinput_marker_path` is the side-channel file doppelganger_poc
# writes when its inject() routine fires. Upstream is NOT modified —
# we just read whatever file happens to exist at this path. If POC
# isn't running, detect_sendinput_burst returns None cleanly.
glob sendinput_marker_path: str = ".jac/data/doppelganger_inject.ndjson";

# Baseline of "known good" LAN peers and ports. Any inbound POST or
# listener outside these sets is suspicious. Populated at init_sentinel
# time from adapter_healthcheck() → own_lan_ips() plus a hardcoded
# control-port allowlist.
glob known_good_peers: list = [];       # list of str IPv4
glob expected_listen_ports: list = [8787];  # sentinel's own port
glob suspicious_listen_ports: list = [18765, 8788];  # control ports we want to see kill signals for

# Ring buffers for the two new sentinel planes.
glob network_alert_log: list = [];
glob process_alert_log: list = [];

# Most recent AttackClassification result (from classify_and_respond).
glob last_classification: dict = {};

# ══════════════════════════════════════════
# GRAPH SCHEMA
# ══════════════════════════════════════════

node LaptopNode {
    has device_id: str = "laptop-a-inocula",
        os_type: str = "unknown",
        paired_devices: list[str] = [];
}

node PeripheralNode {
    has mac_address: str = "00:00:00:00:00:00",
        device_name: str = "unknown_device",
        device_type: str = "UNKNOWN",
        addr_type: str = "unknown",
        trust_score: float = 1.0,
        status: str = "TRUSTED",
        rssi_baseline: float = -60.0,
        rssi_stddev: float = 3.0,
        rssi_live: float = -60.0,
        reconnect_latency_ms: float = 2.0,
        reconnect_baseline_ms: float = 2.0,
        hid_profile: str = "UNKNOWN",
        sleep_cycle_avg: float = 25.0,
        last_seen: int = 0,
        last_seen_utc: str = "",
        duplicate_identity_detected: bool = False,
        connected: bool = False,
        minor_type: str = "unknown",
        services_str: str = "",
        device_class_hex: str = "0x0",
        rssi_history: list = [];
}

edge TrustEdge {}

# ══════════════════════════════════════════
# HELPERS — time, platform, device type inference
# ══════════════════════════════════════════

def now_utc_iso() -> str {
    return datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z");
}

def os_name() -> str {
    if IS_WIN { return "windows"; }
    if IS_MAC { return "macos"; }
    return "linux";
}

def get_device_type(name: str, addr_type: str) -> str {
    n = (name or "").lower();
    if "mouse" in n or "trackpad" in n or "km0" in n { return "MOUSE"; }
    if "keyboard" in n or "kbd" in n { return "KEYBOARD"; }
    if ("buds" in n or "airpods" in n or "headset" in n
        or "headphone" in n or "audio" in n or "speaker" in n) {
        return "HEADSET";
    }
    if "phone" in n or "iphone" in n { return "PHONE"; }
    if "mac" in n or "laptop" in n or "pc" in n { return "COMPUTER"; }
    return "UNKNOWN";
}

def get_hid_profile(dtype: str) -> str {
    if dtype == "MOUSE" { return "MOUSE_ONLY"; }
    if dtype == "KEYBOARD" { return "KEYBOARD_ONLY"; }
    if dtype == "HEADSET" { return "AUDIO_ONLY"; }
    return "UNKNOWN";
}

# ══════════════════════════════════════════
# DETECTION PRIMITIVES — 5 BT sentinels (ported from ghostshield verbatim)
# ══════════════════════════════════════════

def detect_rssi_anomaly(rssi_live: float, rssi_baseline: float, rssi_stddev: float) -> float {
    drift = abs(rssi_live - rssi_baseline);
    if drift <= rssi_stddev { return 0.0; }
    if drift <= rssi_stddev * 2 { return 0.5; }
    return 1.0;
}

def detect_timing_anomaly(actual_ms: float, baseline_ms: float, tolerance_ms: float) -> float {
    delta = abs(actual_ms - baseline_ms);
    if delta <= tolerance_ms { return 0.0; }
    if delta <= tolerance_ms * 2 { return 0.5; }
    return 1.0;
}

def detect_duplicate_identity(known_mac: str, observed_macs: list) -> float {
    count = 0;
    for mac in observed_macs {
        if mac == known_mac { count += 1; }
    }
    if count >= 2 { return 1.0; }
    return 0.0;
}

def detect_hid_anomaly(device_type: str, current_hid: str) -> float {
    if device_type == "MOUSE" and current_hid == "MOUSE_ONLY" { return 0.0; }
    if device_type == "KEYBOARD" and current_hid == "KEYBOARD_ONLY" { return 0.0; }
    if current_hid == "AUDIO_ONLY" or current_hid == "UNKNOWN" { return 0.0; }
    return 1.0;
}

def detect_sleep_violation(sleep_ms: float, sleep_avg_sec: float, min_ratio: float) -> float {
    expected_min = sleep_avg_sec * 1000.0 * min_ratio;
    if sleep_ms >= expected_min { return 0.0; }
    return 1.0;
}

def calc_threat_score(rssi_s: float, timing_s: float, dup_s: float, hid_s: float) -> float {
    return (rssi_s * 0.25) + (timing_s * 0.30) + (dup_s * 0.30) + (hid_s * 0.15);
}

# ══════════════════════════════════════════
# LIVE BT DATA — adapter + inline BLE RSSI cache
# ══════════════════════════════════════════

def _refresh_ble_cache() {
    #* Background BLE scan; 15s TTL. Matches ghostshield behaviour so
       the radio is not thrashed when the dashboard polls. *#
    now = time.time();
    if now - _ble_cache_time < 15.0 { return; }
    _ble_cache_time = now;
    try {
        bleak_mod = __import__("bleak");
        BleakScanner = bleak_mod.BleakScanner;
        def _run_ble_scan() -> dict {
            loop = asyncio.new_event_loop();
            asyncio.set_event_loop(loop);
            try {
                return loop.run_until_complete(BleakScanner.discover(timeout=2, return_adv=True));
            } finally { loop.close(); }
        }
        with concurrent.futures.ThreadPoolExecutor() as pool {
            ble_devices = pool.submit(_run_ble_scan).result(timeout=5);
        }
        new_cache: dict = {};
        for addr in ble_devices {
            pair = ble_devices[addr];
            dev = pair[0];
            adv = pair[1];
            addr_upper = addr.upper().replace("-", ":");
            new_cache[addr_upper] = {"name": dev.name, "rssi": int(adv.rssi)};
        }
        _ble_rssi_cache = new_cache;
    } except Exception { }
}

def scan_bt_with_rssi() -> list {
    #* Returns the live adapter device list enriched with BLE-scanned RSSI.
       Adapter = authoritative for connection + pairing.
       BLE scan  = authoritative for RSSI on devices actively broadcasting. *#
    _refresh_ble_cache();
    base = get_connected_bt_devices();
    out: list = [];
    for d in base {
        mac = d["mac"];
        name = d["name"];
        dtype = d.get("device_type", "UNKNOWN");
        if dtype == "UNKNOWN" {
            dtype = get_device_type(name, d.get("addr_type", "unknown"));
        }
        rssi_val = -60;
        if mac in _ble_rssi_cache {
            rssi_val = _ble_rssi_cache[mac]["rssi"];
        }
        out.append({
            "name": name,
            "mac": mac,
            "addr_type": d.get("addr_type", "unknown"),
            "device_type": dtype,
            "hid_profile": get_hid_profile(dtype),
            "rssi": rssi_val,
            "connected": True,
            "last_seen_utc": d.get("last_seen_utc", now_utc_iso())
        });
    }
    return out;
}

# ══════════════════════════════════════════
# WALKERS
# ══════════════════════════════════════════

# Each walker self-heals on its entry block: `jac start` gives every HTTP
# request a distinct session root, so the module-level `with entry` can't
# seed it. Every walker checks for LaptopNode and creates one if missing.

walker:pub init_sentinel {
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }
    can populate with LaptopNode entry {
        here.device_id = "laptop-a-inocula";
        here.os_type = os_name();
        scan = scan_bt_with_rssi();
        periphs = [here ->:TrustEdge:->][?:PeripheralNode];
        if len(periphs) == 0 {
            for dev in scan {
                rv = float(dev["rssi"]);
                here +>:TrustEdge():+> PeripheralNode(
                    mac_address=dev["mac"], device_name=dev["name"],
                    device_type=dev["device_type"], addr_type=dev["addr_type"],
                    trust_score=0.98, status="TRUSTED",
                    rssi_baseline=rv, rssi_stddev=3.0, rssi_live=rv,
                    reconnect_latency_ms=2.0, reconnect_baseline_ms=2.0,
                    hid_profile=dev["hid_profile"], sleep_cycle_avg=25.0,
                    connected=True, last_seen_utc=dev["last_seen_utc"],
                    rssi_history=[rv]
                );
            }
        } else {
            # upsert path - keep history, refresh live values
            by_mac: dict = {};
            for p in periphs { by_mac[p.mac_address] = p; }
            for dev in scan {
                rv = float(dev["rssi"]);
                if dev["mac"] in by_mac {
                    p = by_mac[dev["mac"]];
                    p.device_name = dev["name"];
                    p.device_type = dev["device_type"];
                    p.addr_type = dev["addr_type"];
                    p.hid_profile = dev["hid_profile"];
                    p.rssi_live = rv;
                    p.connected = True;
                    p.last_seen_utc = dev["last_seen_utc"];
                } else {
                    here +>:TrustEdge():+> PeripheralNode(
                        mac_address=dev["mac"], device_name=dev["name"],
                        device_type=dev["device_type"], addr_type=dev["addr_type"],
                        trust_score=0.98, status="TRUSTED",
                        rssi_baseline=rv, rssi_stddev=3.0, rssi_live=rv,
                        reconnect_latency_ms=2.0, reconnect_baseline_ms=2.0,
                        hid_profile=dev["hid_profile"], sleep_cycle_avg=25.0,
                        connected=True, last_seen_utc=dev["last_seen_utc"],
                        rssi_history=[rv]
                    );
                }
            }
        }
        visible = [here ->:TrustEdge:->][?:PeripheralNode];
        report {
            "seeded": True,
            "device_id": here.device_id,
            "os_type": here.os_type,
            "peripheral_count": len(visible)
        };
    }
}

walker:pub get_graph {
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
            visit [-->[?:LaptopNode]];
            return;
        }
        visit existing;
    }
    can collect with LaptopNode entry {
        all_p = [here ->:TrustEdge:->][?:PeripheralNode];
        visible = [p for p in all_p if p.device_name != "unused"];
        # Only report active alerts (last 10)
        recent = alert_log[-10:];
        report {
            "device_id": here.device_id,
            "os_type": here.os_type,
            "laptop": here,
            "peripherals": visible,
            "defense_phase": "monitoring",
            "active_alerts": recent
        };
    }
}

walker:pub refresh_scan {
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }
    can update with LaptopNode entry {
        periphs = [here ->:TrustEdge:->][?:PeripheralNode];
        scan = scan_bt_with_rssi();
        updated = 0;
        new_count = 0;
        scan_macs: list = [];
        for dev in scan {
            scan_macs.append(dev["mac"]);
            found = False;
            for p in periphs {
                if p.mac_address == dev["mac"] {
                    rv = float(dev["rssi"]);
                    p.rssi_live = rv;
                    p.connected = True;
                    p.last_seen = 1;
                    p.last_seen_utc = dev["last_seen_utc"];
                    p.rssi_history = (p.rssi_history + [rv])[-20:];
                    if len(p.rssi_history) >= 3 {
                        mean_rssi = sum(p.rssi_history) / len(p.rssi_history);
                        p.rssi_stddev = (sum([(x - mean_rssi) ** 2 for x in p.rssi_history]) / len(p.rssi_history)) ** 0.5;
                        if p.rssi_stddev < 1.0 { p.rssi_stddev = 1.0; }
                    }
                    found = True;
                    updated = updated + 1;
                }
            }
            if not found {
                rv = float(dev["rssi"]);
                here +>:TrustEdge():+> PeripheralNode(
                    mac_address=dev["mac"], device_name=dev["name"],
                    device_type=dev["device_type"], addr_type=dev["addr_type"],
                    trust_score=0.50, status="SUSPECT",
                    rssi_baseline=-60.0, rssi_stddev=3.0, rssi_live=rv,
                    hid_profile=dev["hid_profile"],
                    connected=True, last_seen_utc=dev["last_seen_utc"],
                    rssi_history=[rv]
                );
                new_count = new_count + 1;
            }
        }
        for p in periphs {
            if p.mac_address not in scan_macs {
                p.connected = False;
            }
        }
        report {
            "scan_ok": True,
            "updated": updated,
            "new_devices": new_count,
            "devices_scanned": len(scan),
            "scanned_at_utc": now_utc_iso()
        };
    }
}

walker:pub run_sentinel {
    #* Executes the 5 BT detectors against every peripheral in the graph.
       Flags SUSPECT/QUARANTINED on the node, appends to alert_log, and
       reports a per-device result list matching ghostshield shape. *#
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }
    can scan with LaptopNode entry {
        peripherals = [here ->:TrustEdge:->][?:PeripheralNode];
        results: list = [];
        all_macs = [p.mac_address for p in peripherals];
        for p in peripherals {
            rssi_s = detect_rssi_anomaly(p.rssi_live, p.rssi_baseline, p.rssi_stddev);
            timing_s = detect_timing_anomaly(p.reconnect_latency_ms, p.reconnect_baseline_ms, 15.0);
            dup_s = detect_duplicate_identity(p.mac_address, all_macs);
            hid_s = detect_hid_anomaly(p.device_type, p.hid_profile);
            sleep_s = detect_sleep_violation(p.sleep_cycle_avg * 1000.0, p.sleep_cycle_avg, 0.5);
            score = calc_threat_score(rssi_s, timing_s, dup_s, hid_s);

            rssi_ok = rssi_s < 1.0;
            hid_ok = hid_s == 0.0;
            timing_ok = timing_s < 1.0;

            prev_status = p.status;
            if score >= 0.70 {
                p.status = "QUARANTINED";
                p.trust_score = 0.0;
            } elif score >= 0.40 {
                p.status = "SUSPECT";
                p.trust_score = 0.50;
            } else {
                if p.status != "QUARANTINED" {
                    p.status = "TRUSTED";
                    p.trust_score = 0.98;
                }
            }

            if p.status != "TRUSTED" and prev_status == "TRUSTED" {
                alert_log.append({
                    "id": "alert_" + str(int(time.time() * 1000)),
                    "ts_utc": now_utc_iso(),
                    "mac": p.mac_address,
                    "device_name": p.device_name,
                    "severity": "CRITICAL" if p.status == "QUARANTINED" else "WARN",
                    "summary": p.device_name + " flagged " + p.status,
                    "threat_score": score,
                    "scores": {
                        "rssi": rssi_s, "timing": timing_s,
                        "duplicate_id": dup_s, "hid": hid_s, "sleep": sleep_s
                    }
                });
                if len(alert_log) > 200 {
                    alert_log = alert_log[-200:];
                }
            }

            results.append({
                "name": p.device_name,
                "mac": p.mac_address,
                "rssi": "PASS" if rssi_ok else "FAIL",
                "hid": "PASS" if hid_ok else "FAIL",
                "timing": "PASS" if timing_ok else "FAIL",
                "connected": p.connected,
                "status": p.status,
                "threat_score": score,
                "scores": {
                    "rssi": rssi_s, "timing": timing_s,
                    "duplicate_id": dup_s, "hid": hid_s, "sleep": sleep_s
                }
            });
        }
        report {
            "alerts": [a for a in alert_log if a.get("severity") in ["CRITICAL", "WARN"]][-10:],
            "devices": results,
            "last_run_utc": now_utc_iso(),
            "detectors_run": 5
        };
    }
}

walker:pub simulate_attack {
    #* Demo-mode attack injection - flips the first MOUSE into a
       QUARANTINED ghost-identity state so the threat timeline / dashboard
       light up end-to-end. Same shape as ghostshield's simulate_attack. *#
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }
    can inject with LaptopNode entry {
        for p in [here ->:TrustEdge:->][?:PeripheralNode] {
            if p.device_type == "MOUSE" or p.device_type == "UNKNOWN" {
                p.hid_profile = "MIXED";
                p.rssi_live = -72.0;
                p.reconnect_latency_ms = 45.0;
                p.duplicate_identity_detected = True;
                rssi_s = detect_rssi_anomaly(p.rssi_live, p.rssi_baseline, p.rssi_stddev);
                hid_s = detect_hid_anomaly(p.device_type, p.hid_profile);
                score = calc_threat_score(rssi_s, 1.0, 1.0, hid_s);
                p.status = "QUARANTINED";
                p.trust_score = 0.0;
                alert_log.append({
                    "id": "sim_" + str(int(time.time() * 1000)),
                    "ts_utc": now_utc_iso(),
                    "mac": p.mac_address,
                    "device_name": p.device_name,
                    "severity": "CRITICAL",
                    "summary": "SIMULATED: " + p.device_name + " — HID profile switch + duplicate identity",
                    "threat_score": score
                });
                report {
                    "threat_score": score,
                    "detection_time_ms": 203,
                    "device_name": p.device_name,
                    "final_status": "QUARANTINED"
                };
                return;
            }
        }
        report {"error": "no target peripheral found"};
    }
}

walker:pub victim_status {
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }
    can collect with LaptopNode entry {
        live_bt = get_connected_bt_devices();
        bt: list = [];
        for d in live_bt {
            bt.append({"name": d["name"], "mac": d["mac"], "addr_type": d["addr_type"]});
        }
        # defense_phase: recent-alert-driven
        recent_alerts = [a for a in alert_log if a.get("severity") == "CRITICAL"];
        phase = "monitoring";
        if len(recent_alerts) > 0 { phase = "alerting"; }
        report {
            "device_id": here.device_id,
            "os_type": here.os_type,
            "idle_seconds": get_idle_seconds(),
            "idle_threshold": 10.0,
            "connected_bt_devices": bt,
            "defense_phase": phase,
            "sentinel_alerts_last_30s": len(recent_alerts),
            "now_utc": now_utc_iso()
        };
    }
}

walker:pub trigger_payload {
    has force: bool = False,
        origin: str = "unknown",
        operation_id: str = "";

    # Phase 3: every hit on this endpoint is recorded to an NDJSON
    # log so NetworkSentinel can classify rogue POSTs after the fact.
    # The walker itself still refuses to fire a payload — by design
    # this endpoint exists *only* as bait for the attack chain, and
    # its main job is to feed NetworkSentinel. Until the X-Inocula-Token
    # middleware lands in Phase 6, `origin` is caller-supplied and
    # therefore not cryptographically verified.
    can refuse with Root entry {
        log_entry = {
            "ts": now_utc_iso(),
            "source_ip": self.origin,
            "walker": "trigger_payload",
            "accepted": False,
            "reason": "phase3_bait_endpoint_detection_only",
            "operation_id": self.operation_id,
            "force_flag": self.force
        };
        # Best-effort append; swallow I/O errors so the walker never
        # crashes on a missing .jac/data/ directory.
        try {
            log_path = pathlib.Path(trigger_payload_log_path);
            log_path.parent.mkdir(parents=True, exist_ok=True);
            with log_path.open("a", encoding="utf-8") as fh {
                fh.write(json.dumps(log_entry) + "\n");
            }
        } except Exception as _log_err {
            # Swallow; missing data dir must not crash the walker.
            print("trigger_payload log write failed:", str(_log_err)[:80]);
        }
        report {
            "fired": False,
            "reason": "phase3_bait_endpoint",
            "logged": True,
            "note": "Inocula Sentinel bait endpoint. All hits are recorded for NetworkSentinel classification. No real payload is ever fired."
        };
    }
}

walker:pub configure {
    has armed: bool = False,
        idle_threshold: float = 10.0,
        cooldown: float = 90.0;

    can apply with Root entry {
        report {
            "armed": self.armed,
            "idle_threshold": self.idle_threshold,
            "cooldown": self.cooldown,
            "applied_at_utc": now_utc_iso()
        };
    }
}

walker:pub reset_devices {
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }
    can restore with LaptopNode entry {
        for p in [here ->:TrustEdge:->][?:PeripheralNode] {
            p.status = "TRUSTED";
            p.trust_score = 0.98;
            if p.device_type == "MOUSE" { p.hid_profile = "MOUSE_ONLY"; }
            elif p.device_type == "KEYBOARD" { p.hid_profile = "KEYBOARD_ONLY"; }
            else { p.hid_profile = get_hid_profile(p.device_type); }
            p.rssi_live = p.rssi_baseline;
            p.reconnect_latency_ms = 2.0;
            p.duplicate_identity_detected = False;
        }
        alert_log = [];
        report {"reset": True};
    }
}

walker:pub sentinel_alert_receive {
    has sentinel: str = "unknown",
        severity: str = "INFO",
        summary: str = "",
        signals: list = [];

    can accept with Root entry {
        report {
            "ack": True,
            "received_at_utc": now_utc_iso(),
            "note": "Sentinel->C2 webhook reserved for Phase 6 integration."
        };
    }
}

walker:pub get_alerts {
    can read with Root entry {
        report {"total": len(alert_log), "alerts": alert_log[-50:]};
    }
}

# ══════════════════════════════════════════
# PHASE 3 — NETWORK + PROCESS SENTINELS
# ══════════════════════════════════════════
#
# These two walkers close the doppelganger gap. The existing 5 BT
# detectors only fire on the NOISY track; the STEALTH track is
# network-plane + process-plane and has to be caught here.
#
# LLM classification: `classify_attack` (from adapters/classify.py)
# prefers an Anthropic call via litellm when ANTHROPIC_API_KEY is
# set in the environment. When it's not, the same function returns
# a deterministic rule-based classification with the same shape, so
# the walker logic is identical in both modes. This is effectively
# a runtime `by llm()` with graceful degradation — the user can set
# the key at any time and the next classify_and_respond call picks
# it up without a restart.

def _ensure_log_dir() -> None {
    # Make sure .jac/data/ exists so log writes don't fail on a
    # fresh clone. Called from init_sentinel.
    try {
        log_dir = pathlib.Path(".jac/data");
        log_dir.mkdir(parents=True, exist_ok=True);
    } except Exception as _e {
        print("log dir create failed:", str(_e)[:80]);
    }
}

def _append_alert(alert_list: list, alert_entry: dict, cap: int = 200) -> list {
    # Cap-controlled append for the two new ring buffers. `entry` is a
    # reserved keyword in Jac so we use `alert_entry` here.
    alert_list.append(alert_entry);
    if len(alert_list) > cap {
        alert_list = alert_list[-cap:];
    }
    return alert_list;
}

walker:pub network_scan {
    # Observe the current network plane: listeners, peers, rogue POSTs.
    # Writes alerts to network_alert_log. Does NOT run remediation —
    # that's classify_and_respond's job.
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }

    can scan with LaptopNode entry {
        # 1. Find listeners outside the expected set.
        listeners = list_listeners();
        rogue_listeners = [];
        for lst in listeners {
            port = lst.get("port", 0);
            if port in suspicious_listen_ports {
                rogue_listeners.append(lst);
            }
        }
        # 2. Find established peers to :8787 that aren't our own IPs.
        my_ips = own_lan_ips();
        all_peers = list_lan_peers(self_port=8787);
        unexpected_peers = [];
        for peer in all_peers {
            rip = peer.get("remote_ip", "");
            if rip and rip not in my_ips and rip not in known_good_peers {
                # Classify it. localhost is fine; rfc1918 is suspicious
                # but not critical; public is critical.
                peer_with_class = dict(peer);
                peer_with_class["class"] = classify_ip(rip);
                unexpected_peers.append(peer_with_class);
            }
        }
        # 3. Read the trigger_payload access log; anything in the
        #    last 60s that wasn't from a known peer is rogue.
        recent_triggers = trigger_log_recent(trigger_payload_log_path, window_s=60.0);
        rogue_posts = [];
        for trig in recent_triggers {
            src = trig.get("source_ip", "");
            if src and src not in my_ips and src not in known_good_peers {
                rogue_posts.append(trig);
            }
        }
        # 4. Append alerts for anything we found.
        scan_ts = now_utc_iso();
        new_alerts = [];
        if rogue_listeners {
            alert = {
                "ts": scan_ts,
                "sentinel": "network",
                "severity": "CRITICAL",
                "indicator": "rogue_listener",
                "detail": rogue_listeners,
                "message": f"Unexpected listener on {len(rogue_listeners)} control port(s)"
            };
            new_alerts.append(alert);
            network_alert_log = _append_alert(network_alert_log, alert);
        }
        if unexpected_peers {
            sev = "HIGH";
            for p in unexpected_peers {
                if p.get("class") == "public" { sev = "CRITICAL"; }
            }
            alert = {
                "ts": scan_ts,
                "sentinel": "network",
                "severity": sev,
                "indicator": "unexpected_peer",
                "detail": unexpected_peers,
                "message": f"{len(unexpected_peers)} unexpected LAN peer(s) on :8787"
            };
            new_alerts.append(alert);
            network_alert_log = _append_alert(network_alert_log, alert);
        }
        if rogue_posts {
            alert = {
                "ts": scan_ts,
                "sentinel": "network",
                "severity": "CRITICAL",
                "indicator": "rogue_post",
                "detail": rogue_posts,
                "message": f"{len(rogue_posts)} unauthorized POST to /walker/trigger_payload in last 60s"
            };
            new_alerts.append(alert);
            network_alert_log = _append_alert(network_alert_log, alert);
        }
        report {
            "scan_ok": True,
            "scanned_at_utc": scan_ts,
            "total_listeners": len(listeners),
            "rogue_listeners": rogue_listeners,
            "unexpected_peers": unexpected_peers,
            "rogue_posts": rogue_posts,
            "new_alerts": new_alerts,
            "known_good_peers": known_good_peers
        };
    }
}

walker:pub process_scan {
    # Observe the current process plane: idle-cohort spawn, SendInput
    # burst marker. Writes alerts to process_alert_log.
    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }

    can scan with LaptopNode entry {
        idle = get_idle_seconds();
        cohort = detect_idle_cohort(idle_seconds=idle, idle_threshold=10.0, window_s=15.0);
        burst = detect_sendinput_burst(sendinput_marker_path, max_age_s=30.0);
        scan_ts = now_utc_iso();
        new_alerts = [];
        if cohort {
            names = [];
            for e in cohort {
                n = e.get("name", "");
                if n and n not in names { names.append(n); }
            }
            alert = {
                "ts": scan_ts,
                "sentinel": "process",
                "severity": "CRITICAL",
                "indicator": "idle_cohort_spawn",
                "detail": cohort,
                "idle_seconds": idle,
                "message": f"Interactive cohort spawned while idle ({idle:.1f}s): {', '.join(names)}"
            };
            new_alerts.append(alert);
            process_alert_log = _append_alert(process_alert_log, alert);
        }
        if burst is not None {
            alert = {
                "ts": scan_ts,
                "sentinel": "process",
                "severity": "CRITICAL",
                "indicator": "sendinput_burst",
                "detail": burst,
                "message": f"SendInput burst marker: {burst.get('burst_keys', 0)} keys ({burst.get('age_s', 0)}s ago)"
            };
            new_alerts.append(alert);
            process_alert_log = _append_alert(process_alert_log, alert);
        }
        report {
            "scan_ok": True,
            "scanned_at_utc": scan_ts,
            "idle_seconds": idle,
            "cohort": cohort,
            "sendinput_burst": burst,
            "new_alerts": new_alerts
        };
    }
}

walker:pub classify_and_respond {
    # Collect features from network + process + BT sentinels, hand
    # them to the classifier, and (if armed) execute the recommended
    # remediation. Dry-run by default so physical side-effects only
    # fire when `armed=True` is passed by the operator.
    has armed: bool = False;

    can setup with Root entry {
        existing = [-->[?:LaptopNode]];
        if len(existing) == 0 {
            here ++> LaptopNode(device_id="laptop-a-inocula", os_type=os_name());
        }
        visit [-->[?:LaptopNode]];
    }

    can run with LaptopNode entry {
        # Gather features from all three planes.
        listeners = list_listeners();
        rogue_listeners = [];
        for lst in listeners {
            if lst.get("port", 0) in suspicious_listen_ports {
                rogue_listeners.append(lst);
            }
        }
        my_ips = own_lan_ips();
        peers = list_lan_peers(self_port=8787);
        unexpected_peers = [];
        for p in peers {
            rip = p.get("remote_ip", "");
            if rip and rip not in my_ips and rip not in known_good_peers {
                unexpected_peers.append(p);
            }
        }
        recent_triggers = trigger_log_recent(trigger_payload_log_path, window_s=60.0);
        rogue_post = {};
        for t in recent_triggers {
            src = t.get("source_ip", "");
            if src and src not in my_ips and src not in known_good_peers {
                rogue_post = t;
            }
        }
        idle = get_idle_seconds();
        idle_cohort = detect_idle_cohort(idle_seconds=idle, idle_threshold=10.0, window_s=15.0);
        burst = detect_sendinput_burst(sendinput_marker_path, max_age_s=30.0);
        # Pull recent CRITICAL BT alerts for hybrid-attack context.
        bt_recent_crit = [];
        for a in alert_log[-30:] {
            if a.get("severity") == "CRITICAL" {
                bt_recent_crit.append(a);
            }
        }
        features = {
            "new_listeners": rogue_listeners,
            "unexpected_peers": unexpected_peers,
            "rogue_post": rogue_post,
            "idle_cohort": idle_cohort,
            "sendinput_burst": burst,
            "bt_alerts": bt_recent_crit,
            "idle_seconds": idle,
            "now": now_utc_iso()
        };
        result = classify_attack(features);
        last_classification = result;
        # Execute remediation actions if armed.
        executed = [];
        for action in result.get("recommended_actions", []) {
            if action == "none" { continue; }
            parts = action.split(":");
            if len(parts) != 2 { continue; }
            verb = parts[0];
            target = parts[1];
            action_result = {};
            if verb == "kill_listener" {
                try {
                    port_int = int(target);
                    action_result = kill_listener_by_port(port_int, dry_run=not self.armed);
                } except ValueError {
                    action_result = {"ok": False, "error": f"bad port: {target}"};
                }
            } elif verb == "kill_process" {
                action_result = kill_process_by_name(target, dry_run=not self.armed);
            } elif verb == "block_ip" {
                action_result = block_ip_netsh(target, dry_run=not self.armed);
            } elif verb == "quarantine_device" {
                # BT quarantine is handled by the BT sentinels already;
                # we just record the recommendation.
                action_result = {"ok": True, "action": "quarantine_device", "mac": target, "delegated_to": "bt_sentinel"};
            } else {
                action_result = {"ok": False, "error": f"unknown action verb: {verb}"};
            }
            executed.append({"action": action, "result": action_result});
        }
        report {
            "classification": result,
            "features": features,
            "armed": self.armed,
            "executed": executed,
            "classified_at_utc": now_utc_iso()
        };
    }
}

walker:pub get_network_alerts {
    can read with Root entry {
        report {
            "total": len(network_alert_log),
            "alerts": network_alert_log[-50:]
        };
    }
}

walker:pub get_process_alerts {
    can read with Root entry {
        report {
            "total": len(process_alert_log),
            "alerts": process_alert_log[-50:]
        };
    }
}

walker:pub get_classification {
    # Returns the most recent classify_and_respond result for the UI
    # to poll without re-running the (potentially expensive) classifier.
    can read with Root entry {
        report {
            "last": last_classification,
            "has_result": len(last_classification) > 0
        };
    }
}

# ══════════════════════════════════════════
# ENTRY
# ══════════════════════════════════════════

with entry {
    hc = adapter_healthcheck();
    print("=== Inocula Sentinel bt adapter:", hc);
    net_hc = net_adapter_healthcheck();
    print("=== Inocula Sentinel net adapter:", net_hc);
    proc_hc = proc_adapter_healthcheck();
    print("=== Inocula Sentinel proc adapter:", proc_hc);
    rem_hc = remediate_adapter_healthcheck();
    print("=== Inocula Sentinel remediation adapter:", rem_hc);
    cls_hc = classify_adapter_healthcheck();
    print("=== Inocula Sentinel classifier adapter:", cls_hc);
    # Seed known_good_peers with our own IPs plus loopback so self-talk
    # doesn't alert (the dashboard, the curl smoke tests, etc. all connect
    # via 127.0.0.1 / ::1 to port 8787).
    known_good_peers = list(own_lan_ips()) + ["127.0.0.1", "::1"];
    # Ensure log dir exists for trigger_payload_log_path writes.
    _ensure_log_dir();
    root spawn init_sentinel();
    print("=== Inocula Sentinel Ready (port 8787) ===");
}

# ══════════════════════════════════════════
# CLIENT  (SOC-terminal dashboard, Inocula palette)
# Palette:
#   bg        #0a0a14
#   card bg   #0d0d1a
#   border    #1a1a2e
#   muted     #556
#   text      #c0c8d0
#   success   #00ff88  (cs)
#   alert     #ff3355  (ca)
#   warning   #ffaa00  (cw)
# ══════════════════════════════════════════

import from "react" { useEffect, useRef }
import from "lucide-react" { Mouse, Keyboard, Headphones, Monitor, Smartphone, HelpCircle, Shield, Wifi, Activity, AlertTriangle, Clock }


def:pub app -> JsxElement {
    has devices: list = [],
        logs: list = [],
        timeline_events: list = [],
        is_attacking: bool = False,
        attack_done: bool = False,
        detection_time: int = 0,
        hid_alert: bool = False,
        sleep_dev: float = 0.2,
        ghost_visible: bool = False,
        loaded: bool = False,
        scan_count: int = 0,
        walker_log: list = [],
        walker_idx: int = 0,
        walker_phase: str = "move",
        walker_checks: list = [],
        walker_active_edge: str = "",
        latency_hist: list = [],
        rssi_hist: list = [],
        idle_seconds: float = 0.0,
        defense_phase: str = "monitoring",
        # Phase 3 state
        net_alerts: list = [],
        proc_alerts: list = [],
        classification: dict = {},
        last_classify_ts: str = "",
        classify_busy: bool = False,
        net_last_ts: str = "",
        proc_last_ts: str = "";

    intel_ref = useRef(None);
    log_buffer = useRef([]);
    log_id_counter = useRef(0);

    def pushLog(ts: str, cat: str, msg: str) {
        log_id_counter.current = log_id_counter.current + 1;
        log_buffer.current = log_buffer.current + ([{"id": "L" + str(log_id_counter.current), "ts": ts, "cat": cat, "msg": msg}]);
        if len(log_buffer.current) > 500 {
            log_buffer.current = log_buffer.current[-500:];
        }
        logs = log_buffer.current[0:];
    }

    useEffect(lambda {
        if intel_ref.current {
            intel_ref.current.scrollTop = intel_ref.current.scrollHeight;
        }
    }, [len(logs)]);

    async def doInit {
        if loaded { return; }
        loaded = True;
        root spawn init_sentinel();
        fetchDevices();
        fetchStatus();
    }

    useEffect(lambda {
        doInit();
    }, []);

    async def fetchDevices {
        result = root spawn get_graph();
        if result.reports and len(result.reports) > 0 {
            devices = result.reports[0].peripherals or [];
            md: any = None;
            fd: any = None;
            for dd in devices {
                if dd.device_type == "MOUSE" { md = dd; }
                if not fd and dd.connected { fd = dd; }
            }
            if not md { md = fd; }
            if md and md.rssi_history and len(md.rssi_history) > 0 {
                rssi_hist = md.rssi_history[0:];
            }
            if md {
                lat_val = md.reconnect_latency_ms or 2.0;
                if len(latency_hist) < 20 {
                    latency_hist = latency_hist + ([lat_val]);
                } else {
                    latency_hist = latency_hist[1:] + ([lat_val]);
                }
            }
        }
    }

    async def fetchStatus {
        result = root spawn victim_status();
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            idle_seconds = r.idle_seconds or 0.0;
            defense_phase = r.defense_phase or "monitoring";
        }
    }

    async def fetchNetworkScan {
        result = root spawn network_scan();
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            net_last_ts = r.scanned_at_utc or "";
            new_a = r.new_alerts or [];
            if len(new_a) > 0 {
                net_alerts = net_alerts + (new_a)[-20:];
                for a in new_a {
                    pushLog("[NET]", "alert", (a.get("severity") or "INFO") + " — " + (a.get("message") or ""));
                }
            }
        }
    }

    async def fetchProcessScan {
        result = root spawn process_scan();
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            proc_last_ts = r.scanned_at_utc or "";
            new_a = r.new_alerts or [];
            if len(new_a) > 0 {
                proc_alerts = proc_alerts + (new_a)[-20:];
                for a in new_a {
                    pushLog("[PROC]", "alert", (a.get("severity") or "INFO") + " — " + (a.get("message") or ""));
                }
            }
        }
    }

    async def fetchClassification {
        result = root spawn get_classification();
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            if r.has_result {
                classification = r.last or {};
            }
        }
    }

    async def doClassifyAndRespond {
        if classify_busy { return; }
        classify_busy = True;
        result = root spawn classify_and_respond();
        classify_busy = False;
        if result.reports and len(result.reports) > 0 {
            r = result.reports[0];
            classification = r.classification or {};
            last_classify_ts = r.classified_at_utc or "";
            kind = classification.get("kind") or "UNKNOWN";
            sev = classification.get("severity") or "INFO";
            conf = classification.get("confidence") or 0.0;
            backend = classification.get("backend") or "rules";
            pushLog("[CLS]", "alert", sev + " " + kind + " conf=" + str(conf) + " via " + backend);
        }
    }

    def clearState {
        ghost_visible = False; is_attacking = False; attack_done = False; timeline_events = [];
        detection_time = 0; hid_alert = False; sleep_dev = 0.2; scan_count = 0; walker_log = [];
        walker_checks = []; walker_active_edge = ""; walker_phase = "move";
        latency_hist = []; rssi_hist = [];
    }

    useEffect(lambda {
        if is_attacking { return; }
        iv = setInterval(lambda {
            doRefreshScan();
            fetchStatus();
            fetchNetworkScan();
            fetchProcessScan();
            fetchClassification();
        }, 5000);
        return lambda { clearInterval(iv); };
    }, [is_attacking]);

    useEffect(lambda {
        if is_attacking or attack_done or len(devices) == 0 { return; }
        step = 0;
        iv = setInterval(lambda {
            dev_count = len(devices);
            if dev_count == 0 { return; }
            target_idx = int(step / 4) - int(int(step / 4) / dev_count) * dev_count;
            phase = step - int(step / 4) * 4;
            d: any = devices[int(target_idx)];
            dn = d.device_name or "DEVICE";
            r = d.rssi_live or -60;
            l = d.reconnect_latency_ms or 2.0;

            if phase == 0 {
                walker_phase = "move";
                walker_idx = int(target_idx);
                walker_active_edge = dn;
                walker_checks = [];
                walker_log = walker_log + ([{"ts": "[" + str(Math.floor(Math.random() * 99)) + "ms]", "msg": "→ traversing TrustEdge: Laptop-A → " + dn, "walker": "SentinelWalker", "ok": True}])[-30:];
            } elif phase == 1 {
                walker_phase = "check";
                walker_checks = [
                    {"label": "RSSI", "value": str(r) + " dBm", "ok": True, "detail": "baseline: " + str(d.rssi_baseline or -60) + " ±" + str(d.rssi_stddev or 3)},
                    {"label": "HID", "value": d.hid_profile or "?", "ok": True, "detail": "expected: " + (d.hid_profile or "?")}
                ];
                walker_log = walker_log + ([{"ts": "", "msg": "  ├ RSSI: " + str(r) + " dBm ✓  HID: " + (d.hid_profile or "?") + " ✓", "walker": "", "ok": True}])[-30:];
            } elif phase == 2 {
                walker_checks = [
                    {"label": "RSSI", "value": str(r) + " dBm", "ok": True, "detail": "baseline: " + str(d.rssi_baseline or -60) + " ±" + str(d.rssi_stddev or 3)},
                    {"label": "HID", "value": d.hid_profile or "?", "ok": True, "detail": "expected: " + (d.hid_profile or "?")},
                    {"label": "LATENCY", "value": str(l) + "ms", "ok": True, "detail": "threshold: 15ms"},
                    {"label": "SLEEP", "value": str(d.sleep_cycle_avg or 25) + "s", "ok": True, "detail": "Δ+0.2s"}
                ];
                walker_log = walker_log + ([{"ts": "", "msg": "  ├ Latency: " + str(l) + "ms ✓  Sleep: " + str(d.sleep_cycle_avg or 25) + "s ✓", "walker": "", "ok": True}])[-30:];
            } else {
                walker_log = walker_log + ([{"ts": "", "msg": "  └ trust_score: " + str(d.trust_score or 0.98) + " — PASS", "walker": "", "ok": True}])[-30:];
            }

            ts = "[" + str(Math.floor(Math.random() * 990) / 10) + "ms]";
            pushLog(ts, "data", dn + " | RSSI:" + str(r) + "dBm | trust:" + str(d.trust_score or 0.98) + " | " + (d.status or "TRUSTED"));
            if len(latency_hist) >= 20 {
                latency_hist = latency_hist[1:] + ([l]);
            } else {
                latency_hist = latency_hist + ([l]);
            }
            if len(rssi_hist) >= 20 {
                rssi_hist = rssi_hist[1:] + ([r]);
            } else {
                rssi_hist = rssi_hist + ([r]);
            }
            step = step + 1;
        }, 700);
        return lambda { clearInterval(iv); };
    }, [is_attacking, attack_done, len(devices)]);

    async def doRefreshScan {
        result = root spawn refresh_scan();
        scan_count = scan_count + 1;
        fetchDevices();
        if result.reports and len(result.reports) > 0 {
            info = result.reports[0];
            if info.new_devices and info.new_devices > 0 {
                pushLog("[SCAN]", "alert", "⚠ " + str(info.new_devices) + " NEW UNKNOWN DEVICE(S) DETECTED");
            }
        }
    }

    def onAttackPhase1(threat_score_val: float) {
        ghost_visible = True; hid_alert = True; sleep_dev = 4.7;
        if len(latency_hist) >= 20 {
            latency_hist = latency_hist[1:] + ([45]);
        } else {
            latency_hist = latency_hist + ([45]);
        }
        if len(rssi_hist) >= 20 {
            rssi_hist = rssi_hist[1:] + ([-72]);
        } else {
            rssi_hist = rssi_hist + ([-72]);
        }
        walker_active_edge = "BT MOUSE";
        walker_phase = "check";
        walker_checks = [
            {"label": "RSSI", "value": "-72 dBm", "ok": False, "detail": "DRIFT: 12 dBm ⚠"},
            {"label": "HID", "value": "MIXED", "ok": False, "detail": "expected: MOUSE_ONLY ⚠"},
            {"label": "LATENCY", "value": "45ms", "ok": False, "detail": "baseline: 2ms ⚠"},
            {"label": "SLEEP", "value": "0.012s", "ok": False, "detail": "expected: 25s ⚠"},
            {"label": "DUP_ID", "value": "DETECTED", "ok": False, "detail": "2 signals on MAC ⚠"}
        ];
        pushLog("[10.2s]", "alert", "ALERT → duplicate BLE identity detected");
        pushLog("[10.2s]", "alert", "Inocula SentinelWalker → RSSI deviation: -72 dBm (expected: -58 to -63)");
        pushLog("[10.2s]", "alert", "Inocula AlertWalker spawned → threat_score: " + str(threat_score_val));
        pushLog("[10.2s]", "alert", "⚠ KEYBOARD REPORTS DETECTED on mouse HID profile");
        timeline_events = [
            {"id": 1, "t": 0, "label": "sleep event", "type": "normal"},
            {"id": 2, "t": 102, "label": "Duplicate identity", "type": "warning"},
            {"id": 3, "t": 155, "label": "Alert triggered", "type": "critical"},
            {"id": 4, "t": 203, "label": "Device quarantined", "type": "critical"}
        ];
    }

    def onAttackPhase2(detect_ms: int) {
        fetchDevices();
        detection_time = detect_ms;
        pushLog("[10.3s]", "alert", "TrustEdge → STATUS: QUARANTINED 🔴");
        pushLog("[10.3s]", "alert", "Ghost node isolated. Connection severed.");
        is_attacking = False;
        attack_done = True;
    }

    async def doAttack {
        if is_attacking { return; }
        is_attacking = True;
        result = root spawn simulate_attack();
        atk: any = result.reports[0] if result.reports and len(result.reports) > 0 else {};
        pushLog("[10.1s]", "fingerprint", "Inocula FingerprintWalker → sleep event detected");
        pushLog("[10.1s]", "sentinel", "Inocula Overwatch → monitoring reconnection window...");
        score_val = atk.threat_score or 0.94;
        detect_val = atk.detection_time_ms or 203;
        setTimeout(lambda { onAttackPhase1(score_val); }, 1200);
        setTimeout(lambda { onAttackPhase2(detect_val); }, 3000);
    }

    async def doReset {
        ghost_visible = False; is_attacking = False; attack_done = False;
        timeline_events = []; logs = []; detection_time = 0; hid_alert = False;
        sleep_dev = 0.2; walker_checks = []; walker_active_edge = ""; walker_phase = "move";
        latency_hist = []; rssi_hist = [];
        log_buffer.current = []; log_id_counter.current = 0;
        root spawn reset_devices();
        fetchDevices();
    }

    async def doSentinel {
        result = root spawn run_sentinel();
        if result.reports and len(result.reports) > 0 {
            fetchDevices();
            r = result.reports[0];
            dev_results = r.devices or [];
            for dr in dev_results {
                cat = "alert" if dr.rssi == "FAIL" or dr.hid == "FAIL" else "sentinel";
                pushLog("[CHECK]", cat, dr.name + " → RSSI:" + dr.rssi + " HID:" + dr.hid + " " + dr.status);
            }
        }
    }

    threats = 0;
    mouse_dev: any = None;
    first_dev: any = None;
    for d in devices {
        if d.status == "QUARANTINED" or d.status == "SUSPECT" { threats = threats + 1; }
        if d.device_type == "MOUSE" { mouse_dev = d; }
        if not first_dev and d.connected { first_dev = d; }
    }
    if not mouse_dev { mouse_dev = first_dev; }
    if ghost_visible { threats = threats + 1; }

    cs = "#00ff88";
    ca = "#ff3355";
    cw = "#ffaa00";

    phase_color = cs;
    if defense_phase == "alerting" { phase_color = cw; }
    if defense_phase == "locked" { phase_color = ca; }

    return
        <div style={{"background": "#0a0a14", "color": "#c0c8d0", "fontFamily": "'JetBrains Mono', 'Fira Code', monospace", "minHeight": "100vh", "fontSize": "12px"}}>
            <style>{"@keyframes pulse{0%,100%{opacity:1}50%{opacity:0.3}} @keyframes dash{to{stroke-dashoffset:-20}} @keyframes glow-pulse{0%,100%{r:6;opacity:1}50%{r:10;opacity:0.6}} .pulse{animation:pulse 2s infinite} .dash-anim{animation:dash 1s linear infinite} .walker-dot{animation:glow-pulse 0.7s ease-in-out infinite} .node-glow{filter:drop-shadow(0 0 8px #00ff88)} .node-glow-check{filter:drop-shadow(0 0 12px #06b6d4)} .edge-glow{filter:drop-shadow(0 0 4px #00ff88);stroke-width:2}"}</style>

            <div style={{"background": "#0d0d1a", "borderBottom": "1px solid #1a1a2e", "padding": "12px 24px", "display": "flex", "justifyContent": "space-between", "alignItems": "center"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "16px"}}>
                    <Shield size={18} color={cs} />
                    <span style={{"fontSize": "16px", "fontWeight": "800", "color": "#fff", "letterSpacing": "3px"}}>INOCULA SENTINEL</span>
                    <span style={{"background": "#00ff8830", "color": cs, "padding": "4px 16px", "borderRadius": "20px", "fontSize": "11px", "fontWeight": "700", "border": "1px solid " + cs + "50", "letterSpacing": "1px"}}>
                        ◉ LIVE
                    </span>
                    <span style={{"fontSize": "10px", "color": "#556"}}>{"Scan #" + str(scan_count)}</span>
                </div>
                <div style={{"display": "flex", "alignItems": "center", "gap": "20px"}}>
                    <div style={{"textAlign": "center"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px"}}>DEVICES</div>
                        <div style={{"fontSize": "18px", "color": "#fff"}}>{str(len(devices))}</div>
                    </div>
                    <div style={{"textAlign": "center"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px"}}>THREATS</div>
                        <div style={{"fontSize": "18px", "color": (ca if threats > 0 else "#fff")}}>{str(threats)}</div>
                    </div>
                    <div style={{"textAlign": "center"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px"}}>PHASE</div>
                        <div style={{"fontSize": "14px", "color": phase_color, "textTransform": "uppercase", "fontWeight": "700"}}>{defense_phase}</div>
                    </div>
                    <div style={{"textAlign": "center"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px"}}>IDLE</div>
                        <div style={{"fontSize": "14px", "color": "#fff"}}>{str(Math.round(idle_seconds * 10) / 10) + "s"}</div>
                    </div>
                    <button onClick={doReset} style={{"padding": "8px 16px", "background": "#1a1a2e", "color": "#888", "border": "1px solid #333", "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "11px", "letterSpacing": "1px"}}>RESET</button>
                    <button onClick={doSentinel} style={{"padding": "8px 16px", "background": "#0a2a1a", "color": cs, "border": "1px solid " + cs + "50", "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "11px", "letterSpacing": "1px", "fontWeight": "700"}}>⟳ RUN SENTINELS</button>
                    <button onClick={doAttack} style={{"padding": "8px 20px", "background": (ca if not is_attacking else "#551122"), "color": "#fff", "border": "none", "borderRadius": "4px", "cursor": "pointer", "fontFamily": "inherit", "fontSize": "12px", "fontWeight": "700", "letterSpacing": "2px"}}>SIMULATE ATTACK</button>
                </div>
            </div>

            <div style={{"background": "#0a0a14", "borderBottom": "1px solid #1a1a2e", "padding": "10px 24px", "display": "flex", "alignItems": "center", "gap": "16px", "fontSize": "11px"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "6px", "color": "#556", "letterSpacing": "1px"}}>
                    <Wifi size={13} color={(ca if len(net_alerts) > 0 else cs)} />
                    <span>NETWORK SENTINEL</span>
                </div>
                <div style={{"color": (ca if len(net_alerts) > 0 else cs), "fontWeight": "700"}}>
                    {(("⚠ " + str(len(net_alerts)) + " ALERT(S)") if len(net_alerts) > 0 else "● CLEAR")}
                </div>
                {net_last_ts and <span style={{"color": "#334"}}>{net_last_ts[11:19] + "Z"}</span>}
                <div style={{"width": "1px", "height": "16px", "background": "#1a1a2e"}} />
                <div style={{"display": "flex", "alignItems": "center", "gap": "6px", "color": "#556", "letterSpacing": "1px"}}>
                    <Activity size={13} color={(ca if len(proc_alerts) > 0 else cs)} />
                    <span>PROCESS SENTINEL</span>
                </div>
                <div style={{"color": (ca if len(proc_alerts) > 0 else cs), "fontWeight": "700"}}>
                    {(("⚠ " + str(len(proc_alerts)) + " ALERT(S)") if len(proc_alerts) > 0 else "● CLEAR")}
                </div>
                {proc_last_ts and <span style={{"color": "#334"}}>{proc_last_ts[11:19] + "Z"}</span>}
                <div style={{"width": "1px", "height": "16px", "background": "#1a1a2e"}} />
                <div style={{"display": "flex", "alignItems": "center", "gap": "6px", "color": "#556", "letterSpacing": "1px"}}>
                    <AlertTriangle size={13} color={((classification.get("severity") or "INFO") == "CRITICAL") and ca or (((classification.get("severity") or "INFO") == "HIGH") and cw or cs)} />
                    <span>LLM CLASSIFIER</span>
                </div>
                <div style={{"color": ((classification.get("severity") or "INFO") == "CRITICAL") and ca or (((classification.get("severity") or "INFO") == "HIGH") and cw or cs), "fontWeight": "700"}}>
                    {(classification.get("kind") or "—") + " / " + (classification.get("severity") or "—")}
                </div>
                {classification.get("confidence") and <span style={{"color": "#aab"}}>{"conf " + str(Math.round((classification.get("confidence") or 0) * 100)) + "%"}</span>}
                {classification.get("backend") and <span style={{"background": "#1a1a2e", "color": "#aab", "padding": "2px 8px", "borderRadius": "10px", "fontSize": "9px", "letterSpacing": "1px"}}>{(classification.get("backend") or "rules").upper()}</span>}
                <div style={{"flex": "1"}} />
                <button onClick={doClassifyAndRespond} disabled={classify_busy} style={{"padding": "6px 14px", "background": "#0a2a1a", "color": cs, "border": "1px solid " + cs + "50", "borderRadius": "4px", "cursor": classify_busy and "wait" or "pointer", "fontFamily": "inherit", "fontSize": "10px", "letterSpacing": "1px", "fontWeight": "700", "opacity": classify_busy and "0.5" or "1"}}>
                    {classify_busy and "⏳ CLASSIFYING..." or "⟳ CLASSIFY + RESPOND"}
                </button>
            </div>

            <div style={{"display": "flex", "height": "calc(100vh - 106px)"}}>
                <div style={{"width": "320px", "borderRight": "1px solid #1a1a2e", "padding": "16px", "overflowY": "auto"}}>
                    <div style={{"color": cs, "fontSize": "11px", "fontWeight": "700", "letterSpacing": "1px", "marginBottom": "16px"}}>
                        {"BEHAVIORAL BASELINE — " + ((mouse_dev and mouse_dev.get("device_name")) or "NO TARGET")}
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "12px", "marginBottom": "12px"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px", "marginBottom": "8px"}}>RSSI MONITOR</div>
                        <div style={{"position": "relative", "height": "24px", "background": "#111", "borderRadius": "4px", "overflow": "hidden"}}>
                            <div style={{"position": "absolute", "left": "30%", "width": "20%", "height": "100%", "background": "#00ff8815"}} />
                            <div style={{"position": "absolute", "left": (str(50 + (((mouse_dev and mouse_dev.get("rssi_live")) or -61) + 60) * 5) + "%"), "width": "3px", "height": "100%", "background": (ca if hid_alert else cs)}} />
                        </div>
                        <div style={{"display": "flex", "justifyContent": "space-between", "fontSize": "10px", "color": "#556", "marginTop": "4px"}}>
                            <span>-80 dBm</span>
                            <span style={{"color": (ca if hid_alert else cs)}}>{str((mouse_dev and mouse_dev.get("rssi_live")) or "—") + " dBm (μ=-60 σ=3)"}</span>
                            <span>-40 dBm</span>
                        </div>
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "12px", "marginBottom": "12px"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px", "marginBottom": "8px"}}>RECONNECTION LATENCY</div>
                        <svg viewBox="0 0 200 40" style={{"width": "100%", "height": "40px"}}>
                            <polyline fill="none" stroke={cs} strokeWidth="1.5"
                                points={" ".join([str(i * 10.5) + "," + str(35 - v * 6) for (i, v) in enumerate(latency_hist)])} />
                            {hid_alert and <line x1="190" y1="0" x2="190" y2="40" stroke={ca} strokeWidth="1" strokeDasharray="3" />}
                        </svg>
                        <div style={{"display": "flex", "justifyContent": "space-between", "fontSize": "10px"}}>
                            <span style={{"color": "#556"}}>Last 20 events</span>
                            <span style={{"color": (ca if hid_alert else cs)}}>threshold: 15ms</span>
                        </div>
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "12px", "marginBottom": "12px"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px", "marginBottom": "8px"}}>HID PROFILE</div>
                        {not hid_alert and <div style={{"color": cs, "fontWeight": "700"}}>{"● " + ((mouse_dev and mouse_dev.get("hid_profile")) or "N/A") + " ✓"}</div>}
                        {hid_alert and <div style={{"color": ca, "fontWeight": "700"}}>● ⚠ KEYBOARD REPORTS DETECTED</div>}
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "12px", "marginBottom": "12px"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px", "marginBottom": "8px"}}>SLEEP CYCLE RHYTHM</div>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "4px"}}>
                            <span style={{"fontSize": "10px", "color": "#556"}}>EXPECTED</span>
                            <div style={{"flex": "1", "display": "flex", "height": "8px", "borderRadius": "4px", "overflow": "hidden", "gap": "2px"}}>
                                <div style={{"flex": "1", "background": cs}} />
                                <div style={{"flex": (sleep_dev / 5.0), "background": (ca if sleep_dev > 1 else cw)}} />
                            </div>
                            <span style={{"fontSize": "10px", "color": "#556"}}>ACTUAL</span>
                            <span style={{"color": (ca if sleep_dev > 1 else cs), "fontWeight": "700", "marginLeft": "8px"}}>{"Δ+" + str(sleep_dev) + "s"}</span>
                        </div>
                    </div>

                    <div style={{"background": "#0d0d1a", "border": "1px solid #1a1a2e", "borderRadius": "8px", "padding": "12px"}}>
                        <div style={{"fontSize": "10px", "color": "#556", "letterSpacing": "1px", "marginBottom": "8px"}}>ALL DEVICES</div>
                        {len(devices) == 0 and <div style={{"color": "#334", "fontSize": "10px", "fontStyle": "italic"}}>no peripherals connected</div>}
                        {[
                            <div key={d.mac_address} style={{"padding": "4px 0", "borderBottom": "1px solid #111", "fontSize": "11px"}}>
                                <span style={{"color": (ca if d.status != "TRUSTED" else (cs if d.connected else "#556")), "display": "inline-flex", "verticalAlign": "middle", "marginRight": "4px"}}>
                                    {d.device_type == "MOUSE" and <Mouse size={12} />}
                                    {d.device_type == "KEYBOARD" and <Keyboard size={12} />}
                                    {d.device_type == "HEADSET" and <Headphones size={12} />}
                                    {d.device_type == "PHONE" and <Smartphone size={12} />}
                                    {d.device_type != "MOUSE" and d.device_type != "KEYBOARD" and d.device_type != "HEADSET" and d.device_type != "PHONE" and <HelpCircle size={12} />}
                                </span>
                                <span style={{"color": "#aab"}}>{d.device_name}</span>
                                {d.connected and <span style={{"color": cs, "marginLeft": "4px"}}>●</span>}
                                <div style={{"fontSize": "9px", "color": "#334", "fontFamily": "monospace"}}>{d.mac_address}</div>
                            </div>
                            for d in devices
                        ]}
                    </div>
                </div>

                <div style={{"flex": "1", "display": "flex", "flexDirection": "column"}}>
                    <div style={{"flex": "1", "position": "relative"}}>
                        <svg style={{"position": "absolute", "inset": "0", "width": "100%", "height": "100%"}}>
                            {for d in devices {
                                <line key={"e-" + d.mac_address}
                                    x1="50%" y1="50%"
                                    x2={("50%" if d.device_type == "MOUSE" else ("78%" if d.device_type == "KEYBOARD" else ("22%" if d.device_type == "PHONE" else ("78%" if d.device_type == "COMPUTER" else "50%"))))}
                                    y2={("15%" if d.device_type == "MOUSE" else ("58%" if d.device_type == "KEYBOARD" else ("35%" if d.device_type == "PHONE" else ("20%" if d.device_type == "COMPUTER" else "85%"))))}
                                    stroke={(ca if d.status == "QUARANTINED" else (cw if d.status == "SUSPECT" else (cs if d.connected else "#222")))}
                                    strokeWidth="1" strokeDasharray="8 4" className="dash-anim" />
                            }}
                            {ghost_visible and <line x1="50%" y1="50%" x2="20%" y2="70%" stroke={ca} strokeWidth="1" strokeDasharray="4 4" className="pulse" />}
                        </svg>

                        <div style={{"position": "absolute", "left": "50%", "top": "50%", "transform": "translate(-50%,-50%)", "display": "flex", "flexDirection": "column", "alignItems": "center", "gap": "4px", "zIndex": "2"}}>
                            <div style={{"width": "80px", "height": "80px", "borderRadius": "50%", "border": "2px solid " + cs, "display": "flex", "alignItems": "center", "justifyContent": "center", "background": "#0a0a14"}}>
                                <Monitor size={32} color={cs} />
                            </div>
                            <span style={{"fontSize": "10px", "color": "#aab", "letterSpacing": "1px", "fontWeight": "600"}}>LAPTOP-A</span>
                            <span style={{"fontSize": "9px", "color": cs}}>TRUSTED</span>
                        </div>

                        {[
                            <div key={"n-" + d.mac_address} style={{
                                "position": "absolute", "zIndex": "2", "display": "flex", "flexDirection": "column", "alignItems": "center", "gap": "4px", "transform": "translate(-50%,-50%)",
                                "left": (d.device_type == "MOUSE" and "50%" or (d.device_type == "KEYBOARD" and "78%" or (d.device_type == "PHONE" and "22%" or (d.device_type == "COMPUTER" and "78%" or "50%")))),
                                "top": (d.device_type == "MOUSE" and "15%" or (d.device_type == "KEYBOARD" and "58%" or (d.device_type == "PHONE" and "35%" or (d.device_type == "COMPUTER" and "20%" or "85%"))))
                            }}>
                                <div style={{
                                    "width": "72px", "height": "72px", "borderRadius": "50%",
                                    "border": "2px " + ("dashed" if d.status == "QUARANTINED" else "solid") + " " + (ca if d.status == "QUARANTINED" else (cw if d.status == "SUSPECT" else (cs if d.connected else "#333"))),
                                    "display": "flex", "alignItems": "center", "justifyContent": "center", "background": "#0a0a14",
                                    "boxShadow": (("0 0 20px " + ca + "40") if d.status == "QUARANTINED" else (("0 0 12px " + cw + "30") if d.status == "SUSPECT" else "none")),
                                    "animation": (d.status == "QUARANTINED" and "pulse 2s infinite" or "none")
                                }}>
                                    {d.device_type == "MOUSE" and <Mouse size={28} color={d.status == "QUARANTINED" and ca or (d.connected and cs or "#444")} />}
                                    {d.device_type == "KEYBOARD" and <Keyboard size={28} color={d.connected and cs or "#444"} />}
                                    {d.device_type == "HEADSET" and <Headphones size={28} color={d.connected and cs or "#444"} />}
                                    {d.device_type == "PHONE" and <Smartphone size={28} color={d.connected and cs or "#444"} />}
                                    {d.device_type == "COMPUTER" and <Monitor size={28} color={d.connected and cs or "#444"} />}
                                    {d.device_type == "UNKNOWN" and <HelpCircle size={28} color="#444" />}
                                </div>
                                <span style={{"fontSize": "10px", "color": "#aab", "letterSpacing": "1px", "fontWeight": "600"}}>{d.device_name}</span>
                                <span style={{"fontSize": "9px", "color": (d.status != "TRUSTED" and ca or cs)}}>{d.status}</span>
                            </div>
                            for d in devices
                        ]}

                        {ghost_visible and
                            <div style={{"position": "absolute", "left": "20%", "top": "70%", "transform": "translate(-50%,-50%)", "zIndex": "2", "display": "flex", "flexDirection": "column", "alignItems": "center", "gap": "4px"}}>
                                <div style={{"width": "68px", "height": "68px", "borderRadius": "50%", "border": "2px dashed " + ca, "display": "flex", "alignItems": "center", "justifyContent": "center", "background": "#0a0a14", "boxShadow": "0 0 20px " + ca + "40", "animation": "pulse 2s infinite"}}>
                                    <HelpCircle size={28} color={ca} />
                                </div>
                                <span style={{"fontSize": "10px", "color": ca, "letterSpacing": "1px", "fontWeight": "600"}}>UNKNOWN IDENTITY</span>
                                <span style={{"fontSize": "9px", "color": ca}}>QUARANTINED</span>
                            </div>
                        }
                    </div>

                    {len(timeline_events) > 0 and
                        <div style={{"borderTop": "1px solid #1a1a2e", "padding": "12px 24px"}}>
                            <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "12px"}}>
                                <span style={{"color": cs, "fontSize": "11px", "fontWeight": "700", "letterSpacing": "1px"}}>THREAT TIMELINE</span>
                                {detection_time > 0 and <span style={{"color": ca, "fontSize": "16px", "fontWeight": "800", "letterSpacing": "2px"}}>
                                    {"TIME TO DETECTION: " + str(detection_time) + "ms"}
                                </span>}
                            </div>
                            <div style={{"position": "relative", "height": "50px"}}>
                                <div style={{"position": "absolute", "top": "20px", "left": "0", "right": "0", "height": "2px", "background": "#1a1a2e"}} />
                                {[
                                    <div key={"tl-" + str(ev.t)} style={{"position": "absolute", "top": "12px", "left": str(ev.t / 2.5) + "%", "textAlign": "center", "transform": "translateX(-50%)"}}>
                                        <div style={{"width": "12px", "height": "12px", "borderRadius": "50%", "margin": "0 auto", "background": (ev.type == "normal" and "#06b6d4" or (ev.type == "warning" and cw or ca))}} />
                                        <div style={{"fontSize": "9px", "color": "#556", "marginTop": "4px"}}>{str(ev.t) + ".0ms"}</div>
                                        <div style={{"fontSize": "10px", "marginTop": "2px", "color": (ev.type == "normal" and "#06b6d4" or (ev.type == "warning" and cw or ca))}}>{ev.label}</div>
                                    </div>
                                    for ev in timeline_events
                                ]}
                            </div>
                        </div>
                    }
                    {len(timeline_events) == 0 and
                        <div style={{"borderTop": "1px solid #1a1a2e", "padding": "16px", "textAlign": "center", "color": "#334", "fontSize": "11px", "letterSpacing": "2px"}}>
                            INOCULA SENTINEL — NO THREAT EVENTS RECORDED
                        </div>
                    }
                </div>

                <div style={{"width": "400px", "borderLeft": "1px solid #1a1a2e", "display": "flex", "flexDirection": "column", "height": "calc(100vh - 56px)"}}>
                    <div style={{"height": "50%", "display": "flex", "flexDirection": "column", "borderBottom": "1px solid #1a1a2e"}}>
                        <div style={{"padding": "10px 16px", "borderBottom": "1px solid #1a1a2e", "display": "flex", "justifyContent": "space-between", "alignItems": "center", "flexShrink": "0"}}>
                            <span style={{"color": ca, "fontSize": "11px", "fontWeight": "700", "letterSpacing": "1px"}}>THREAT INTEL</span>
                            <div style={{"display": "flex", "gap": "6px"}}>
                                <span style={{"padding": "2px 8px", "borderRadius": "3px", "fontSize": "9px", "background": "#06b6d420", "color": "#06b6d4", "border": "1px solid #06b6d430"}}>LIVE</span>
                            </div>
                        </div>
                        <div ref={intel_ref} style={{"flex": "1", "overflowY": "auto", "padding": "4px 8px", "background": "#050508", "fontFamily": "'JetBrains Mono', 'Fira Code', monospace"}}>
                            {len(logs) == 0 and <div style={{"color": "#334", "textAlign": "center", "padding": "24px 0", "fontSize": "11px"}}>Collecting device telemetry...</div>}
                            {[
                                <div key={e.id} style={{"padding": "1px 0", "lineHeight": "1.4", "fontSize": "10px", "whiteSpace": "nowrap"}}>
                                    <span style={{"color": "#334"}}>{e.ts}</span>
                                    <span style={{"color": (e.cat == "alert" and ca or (e.cat == "score" and cw or (e.cat == "data" and "#5a7a5a" or "#06b6d4")))}}>{" " + e.msg}</span>
                                </div>
                                for e in logs
                            ]}
                        </div>
                    </div>

                    <div style={{"height": "50%", "display": "flex", "flexDirection": "column"}}>
                        <div style={{"padding": "10px 16px", "borderBottom": "1px solid #1a1a2e", "display": "flex", "justifyContent": "space-between", "alignItems": "center", "flexShrink": "0"}}>
                            <div style={{"display": "flex", "alignItems": "center", "gap": "8px"}}>
                                <div style={{"width": "6px", "height": "6px", "borderRadius": "50%", "background": cs, "boxShadow": "0 0 8px " + cs}} />
                                <span style={{"color": cs, "fontSize": "11px", "fontWeight": "700", "letterSpacing": "1px"}}>TRUST NETWORK</span>
                            </div>
                            <span style={{"fontSize": "9px", "color": "#445"}}>
                                {"Inocula SentinelWalker → " + (walker_active_edge or "idle")}
                            </span>
                        </div>

                        <div style={{"flex": "1", "display": "flex", "flexDirection": "column", "alignItems": "center", "justifyContent": "center", "padding": "8px"}}>
                            <svg viewBox="0 0 340 240" style={{"width": "100%", "maxHeight": "100%"}}>
                                <defs>
                                    <filter id="tg">
                                        <feGaussianBlur stdDeviation="3" result="b" />
                                        <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
                                    </filter>
                                    <radialGradient id="sg">
                                        <stop offset="0%" stopColor="#00ffaa" stopOpacity="1" />
                                        <stop offset="100%" stopColor="#00ff88" stopOpacity="0" />
                                    </radialGradient>
                                </defs>

                                <line x1="170" y1="120" x2="70" y2="40" stroke={len(walker_checks) > 0 and walker_checks[0] and walker_checks[0].ok and cs or "#1a1a2e"} strokeWidth="1" strokeDasharray="4 3" />
                                <line x1="170" y1="120" x2="270" y2="40" stroke={len(walker_checks) > 1 and walker_checks[1] and walker_checks[1].ok and cs or "#1a1a2e"} strokeWidth="1" strokeDasharray="4 3" />
                                <line x1="170" y1="120" x2="40" y2="160" stroke={len(walker_checks) > 2 and walker_checks[2] and walker_checks[2].ok and cs or "#1a1a2e"} strokeWidth="1" strokeDasharray="4 3" />
                                <line x1="170" y1="120" x2="300" y2="160" stroke={len(walker_checks) > 3 and walker_checks[3] and walker_checks[3].ok and cs or "#1a1a2e"} strokeWidth="1" strokeDasharray="4 3" />

                                <circle cx="170" cy="120" r="24" fill="#0d0d1a" stroke={cs} strokeWidth="1.5" />
                                <text x="170" y="116" textAnchor="middle" fill="#fff" fontSize="8" fontFamily="inherit">{walker_active_edge or "DEVICE"}</text>
                                <text x="170" y="128" textAnchor="middle" fill={cs} fontSize="7" fontFamily="inherit">
                                    {len(devices) > 0 and devices[walker_idx] and devices[walker_idx].status or "—"}
                                </text>

                                <circle cx="70" cy="40" r="18" fill="#0d0d1a" stroke={len(walker_checks) > 0 and (walker_checks[0].ok and cs or ca) or "#1a1a2e"} strokeWidth={len(walker_checks) > 0 and "2" or "1"} filter={len(walker_checks) > 0 and "url(#tg)" or "none"} />
                                <text x="70" y="36" textAnchor="middle" fill={len(walker_checks) > 0 and (walker_checks[0].ok and cs or ca) or "#334"} fontSize="7" fontFamily="inherit" fontWeight="700">RSSI</text>
                                <text x="70" y="46" textAnchor="middle" fill={len(walker_checks) > 0 and "#aab" or "#222"} fontSize="6" fontFamily="inherit">
                                    {len(walker_checks) > 0 and walker_checks[0].value or "—"}
                                </text>

                                <circle cx="270" cy="40" r="18" fill="#0d0d1a" stroke={len(walker_checks) > 1 and (walker_checks[1].ok and cs or ca) or "#1a1a2e"} strokeWidth={len(walker_checks) > 1 and "2" or "1"} filter={len(walker_checks) > 1 and "url(#tg)" or "none"} />
                                <text x="270" y="36" textAnchor="middle" fill={len(walker_checks) > 1 and (walker_checks[1].ok and cs or ca) or "#334"} fontSize="7" fontFamily="inherit" fontWeight="700">HID</text>
                                <text x="270" y="46" textAnchor="middle" fill={len(walker_checks) > 1 and "#aab" or "#222"} fontSize="6" fontFamily="inherit">
                                    {len(walker_checks) > 1 and walker_checks[1].value or "—"}
                                </text>

                                <circle cx="40" cy="160" r="18" fill="#0d0d1a" stroke={len(walker_checks) > 2 and (walker_checks[2].ok and cs or ca) or "#1a1a2e"} strokeWidth={len(walker_checks) > 2 and "2" or "1"} filter={len(walker_checks) > 2 and "url(#tg)" or "none"} />
                                <text x="40" y="156" textAnchor="middle" fill={len(walker_checks) > 2 and (walker_checks[2].ok and cs or ca) or "#334"} fontSize="7" fontFamily="inherit" fontWeight="700">LATENCY</text>
                                <text x="40" y="166" textAnchor="middle" fill={len(walker_checks) > 2 and "#aab" or "#222"} fontSize="6" fontFamily="inherit">
                                    {len(walker_checks) > 2 and walker_checks[2].value or "—"}
                                </text>

                                <circle cx="300" cy="160" r="18" fill="#0d0d1a" stroke={len(walker_checks) > 3 and (walker_checks[3].ok and cs or ca) or "#1a1a2e"} strokeWidth={len(walker_checks) > 3 and "2" or "1"} filter={len(walker_checks) > 3 and "url(#tg)" or "none"} />
                                <text x="300" y="156" textAnchor="middle" fill={len(walker_checks) > 3 and (walker_checks[3].ok and cs or ca) or "#334"} fontSize="7" fontFamily="inherit" fontWeight="700">SLEEP</text>
                                <text x="300" y="166" textAnchor="middle" fill={len(walker_checks) > 3 and "#aab" or "#222"} fontSize="6" fontFamily="inherit">
                                    {len(walker_checks) > 3 and walker_checks[3].value or "—"}
                                </text>

                                <line x1="170" y1="120" x2="170" y2="220" stroke={len(walker_checks) > 4 and (walker_checks[4].ok and cs or ca) or "#1a1a2e"} strokeWidth="1" strokeDasharray="4 3" />
                                <circle cx="170" cy="220" r="18" fill="#0d0d1a" stroke={len(walker_checks) > 4 and (walker_checks[4].ok and cs or ca) or "#1a1a2e"} strokeWidth={len(walker_checks) > 4 and "2" or "1"} filter={len(walker_checks) > 4 and "url(#tg)" or "none"} />
                                <text x="170" y="217" textAnchor="middle" fill={len(walker_checks) > 4 and (walker_checks[4].ok and cs or ca) or "#334"} fontSize="6" fontFamily="inherit" fontWeight="700">DUP_ID</text>
                                <text x="170" y="226" textAnchor="middle" fill={len(walker_checks) > 4 and "#aab" or "#222"} fontSize="6" fontFamily="inherit">
                                    {len(walker_checks) > 4 and walker_checks[4].value or "none"}
                                </text>

                                {walker_phase == "check" and len(walker_checks) > 0 and
                                    <circle
                                        cx={((70 if len(walker_checks) == 1 else 270) if len(walker_checks) <= 2 else (40 if len(walker_checks) == 3 else 300))}
                                        cy={len(walker_checks) <= 2 and 40 or 160}
                                        r="5" fill="url(#sg)" filter="url(#tg)" className="walker-dot"
                                    />
                                }
                                {walker_phase == "move" and
                                    <circle cx="170" cy="120" r="5" fill="url(#sg)" filter="url(#tg)" className="walker-dot" />
                                }
                            </svg>
                        </div>
                    </div>
                </div>
            </div>
        </div>;
}
