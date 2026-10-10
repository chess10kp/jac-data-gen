"""Orion v2 Satellite Verification — Jac orchestrator wrapping Python backend.

Nodes coordinate the 3x3 spatial SAR/RGB consensus scan.
Python (agent_tools, spatial_search) handles compute.
"""

import from agent_tools {
    run_spatial_sar_scan as py_spatial_scan,
    save_rgb_image_to_disk
}
from spatial_search import SpatialSearchResult

node scan_coordinator {
    has lat: float = 0.0;
    has lon: float = 0.0;
    has start_date: str = "";
    has end_date: str = "";
}

node sar_fetch {
    has target_locked: bool = False;
    has confidence_score: float = 0.0;
    has winning_sensor: str = "";
}

node rgb_fetch {
    has image_path: str = "";
}

node result_aggregator {
    has final_result: SpatialSearchResult = None;
}

walker orion_spatial_scan {
    has result: SpatialSearchResult = None;

    can with `root entry {
        visit [-->];
    }

    can with scan_coordinator entry {
        here.lat = self.result.lat if hasattr(self, 'result') and self.result else 0.0;
        here.lon = self.result.lon if hasattr(self, 'result') and self.result else 0.0;
        here.start_date = self.result.start_date if hasattr(self, 'result') and self.result else "";
        here.end_date = self.result.end_date if hasattr(self, 'result') and self.result else "";
        visit [-->];
    }

    can with sar_fetch entry {
        print(f"[orion] Dispatching spatial SAR/RGB scan: {here.lat:.4f}, {here.lon:.4f}");
        self.result = py_spatial_scan(
            lat=self.result.lat,
            lon=self.result.lon,
            start_date=self.result.start_date,
            end_date=self.result.end_date
        );
        here.target_locked = self.result.target_locked;
        here.confidence_score = self.result.confidence_score;
        here.winning_sensor = self.result.winning_sensor;
        print(f"[orion] Scan complete: locked={here.target_locked} confidence={here.confidence_score:.2f}");
        visit [-->];
    }

    can with rgb_fetch entry {
        if self.result and self.result.display_image_path:
            here.image_path = self.result.display_image_path;
        print(f"[orion] RGB display path: {here.image_path}");
        visit [-->];
    }

    can with result_aggregator entry {
        here.final_result = self.result;
        print(f"[orion] Aggregation complete. Result locked for reporting.");
    }
}
