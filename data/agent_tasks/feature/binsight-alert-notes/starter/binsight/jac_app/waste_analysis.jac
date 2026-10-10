"""Jac-powered waste analysis entrypoint for BinSight."""

import json;

obj WasteAnalysisItem {
    has food: str;
    has category: str;
    has estimated_weight_oz: float;
    has estimated_portion_wasted_pct: float;
    has estimated_cost_usd: float;
    has avoidable: bool;
}

obj WasteAnalysisSummary {
    has total_items: int;
    has total_estimated_weight_oz: float;
    has total_estimated_cost_usd: float;
    has most_wasted_category: str;
    has waste_severity: str;
    has avoidable_weight_oz: float;
    has unavoidable_weight_oz: float;
    has avoidable_cost_usd: float;
    has unavoidable_cost_usd: float;
}

walker :pub AnalyzeWaste {
    has image_path: str;
    has image_b64: str;
    has image_media_type: str = "image/jpeg";
    has current_menu: list[str] = [];
    has constant_items: list[str] = [];

    can run with Root entry {
        result = {
            "items": [],
            "summary": {
                "total_items": 0,
                "total_estimated_weight_oz": 0.0,
                "total_estimated_cost_usd": 0.0,
                "most_wasted_category": "other",
                "waste_severity": "low",
                "avoidable_weight_oz": 0.0,
                "unavoidable_weight_oz": 0.0,
                "avoidable_cost_usd": 0.0,
                "unavoidable_cost_usd": 0.0
            },
            "notes": (
                "Jac waste analysis stub. Replace this walker body with by_llm or "
                + "tool-backed multimodal analysis while keeping the same response schema. "
                + "Current menu items: "
                + str(self.current_menu)
                + ". Constant items: "
                + str(self.constant_items)
            )
        };
        report result;
    }
}
