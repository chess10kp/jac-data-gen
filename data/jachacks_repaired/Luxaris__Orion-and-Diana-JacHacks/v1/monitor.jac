"""Orion - Sentinel-2 RGB oil spill detector.

Primary language: Jac (jaclang 0.9).
Jac features:
  - Object Spatial Programming: node (SatelliteRegion) + walker (SpillMonitor)
  - byllm: `def monitor_region(...) -> dict by llm();` — LLM fills the return
    value by calling check_region_for_spill via the ReAct tool loop.

Python bridge: tools.py wraps GEE fetch + vision model call so raw image
bytes never cross the LLM tool-calling boundary.

Run: jac run monitor.jac
"""

import from featherless_model { FeatherlessModel, featherless_api_key }
import from tools { check_region_for_spill, SpillVerdict }

glob llm: FeatherlessModel = FeatherlessModel(
    model_name="Qwen/Qwen3.5-4B",
    base_url="https://api.featherless.ai/v1",
    api_key=featherless_api_key(),
    proxy=True
);

# --- Node: stateful representation of a monitored ocean region ---

node SatelliteRegion {
    has lat: float = 33.59;
    has lon: float = -118.05;
    has start_date: str = '2021-10-01';
    has end_date: str = '2021-10-05';
    has past_anomalies: list = [];
    has last_verdict: SpillVerdict = None;
}

# --- byllm ReAct: LLM autonomously calls the tool and returns a verdict ---

"""Check the given ocean region for oil spills using Sentinel-2 RGB imagery.
Use the check_region_for_spill tool with the provided coordinates and dates.
Return the resulting verdict as a dict with spill_detected, confidence, and reasoning."""
def monitor_region(lat: float, lon: float, start_date: str, end_date: str) -> SpillVerdict
    by llm(tools=[check_region_for_spill]);

# --- Walker: visits each SatelliteRegion and runs the monitor ---

walker SpillMonitor {
    # jaclang 0.9.0 expects the root walker handler in this anonymous form.
    can with Root entry {
        # Spawned on root — traverse to connected SatelliteRegion nodes.
        visit [-->];
    }

    can monitor with SatelliteRegion entry {
        print(f"Monitoring region ({here.lat}, {here.lon}) from {here.start_date} to {here.end_date}...");

        verdict = monitor_region(here.lat, here.lon, here.start_date, here.end_date);

        if verdict {
            here.last_verdict = verdict;
            if verdict.spill_detected {
                here.past_anomalies.append(verdict);
            }
            print("");
            print("--- Spill Detection Result ---");
            print(f"Spill detected : {verdict.spill_detected}");
            print(f"Confidence     : {verdict.confidence:.0%}");
            print(f"Reasoning      : {verdict.reasoning}");
        }
    }
}

# --- Entry point ---

with entry {
    print("[orion] Starting SpillMonitor walker...");
    region = SatelliteRegion(
        lat=33.59,
        lon=-118.05,
        start_date='2021-10-01',
        end_date='2021-10-05'
    );
    root ++> region;
    root spawn SpillMonitor();
    print("[orion] Walker complete.");
}
