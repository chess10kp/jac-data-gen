"""Walkers that orchestrate image preflight checks and vision pipeline bookkeeping."""


import from ..domain.edges { Contains }
import from ..domain.nodes { WasteLineItem, WasteRecord }
walker :pub PreflightImage {
    has image_path: str;
    has blur_score: float = 0.0;
    has brightness_score: float = 0.0;
    has coverage_pct: float = 100.0;
    has issues: list[str] = [];
    has passed: bool = True;

    can start with Root entry {
        if self.blur_score < 0.15 {
            self.issues.append("image_too_blurry");
            self.passed = False;
        }
        if self.brightness_score < 0.2 {
            self.issues.append("image_too_dark");
            self.passed = False;
        } elif self.brightness_score > 0.95 {
            self.issues.append("image_overexposed");
            self.passed = False;
        }
        if self.coverage_pct < 60.0 {
            self.issues.append("bin_not_centered");
            self.passed = False;
        }
        report {
            "image_path": self.image_path,
            "passed": self.passed,
            "issues": self.issues,
            "scores": {
                "blur": self.blur_score,
                "brightness": self.brightness_score,
                "coverage": self.coverage_pct
            }
        };
    }
}

walker :pub LogVisionUsage {
    has model: str;
    has provider: str = "anthropic";
    has input_tokens: int = 0;
    has output_tokens: int = 0;
    has latency_ms: int = 0;
    has cost_usd: float = 0.0;

    can start with Root entry {
        report {
            "provider": self.provider,
            "model": self.model,
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "latency_ms": self.latency_ms,
            "cost_usd": self.cost_usd
        };
    }
}

walker :pub BuildVisionPrompt {
    has categories: list[str] = [];
    has current_menu: list[str] = [];
    has constant_items: list[str] = [];
    has temperature: float = 0.0;

    can start with Root entry {
        base = (
            "You are analyzing an overhead photo of a dining hall waste bin. "
            + "Identify visible food items, estimate their weight in ounces, "
            + "categorize each item, and mark whether the waste was avoidable. "
            + "Prefer matching items to the provided menu when reasonable, but "
            + "name items you actually see even if they are not on the menu."
        );
        menu_context = "";
        if len(self.current_menu) > 0 {
            menu_context = " Current menu items: " + str(self.current_menu) + ".";
        }
        constants_context = "";
        if len(self.constant_items) > 0 {
            constants_context = " Items that are always available: " + str(self.constant_items) + ".";
        }
        full_prompt = base + menu_context + constants_context;
        report {
            "instructions": full_prompt,
            "categories_allowed": self.categories,
            "response_format": "json",
            "temperature": self.temperature
        };
    }
}

walker :pub EstimateLinePortions {
    has record_id: str;
    has updated: int = 0;

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can estimate with WasteLineItem entry {
        if here.estimated_portion_wasted_pct == 0.0 and here.estimated_weight_oz > 0.0 {
            typical = 4.0;
            pct = (here.estimated_weight_oz / typical) * 100.0;
            if pct > 100.0 {
                pct = 100.0;
            }
            here.estimated_portion_wasted_pct = pct;
            self.updated += 1;
        }
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "updated": self.updated};
    }
}

walker :pub ClassifyAvoidability {
    has record_id: str;
    has updated: int = 0;

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can classify with WasteLineItem entry {
        food_lower = here.food.lower();
        if "peel" in food_lower or "rind" in food_lower or "bone" in food_lower or "core" in food_lower or "shell" in food_lower {
            here.avoidable = False;
            self.updated += 1;
        } else {
            here.avoidable = True;
            self.updated += 1;
        }
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "updated": self.updated};
    }
}

walker :pub SuggestSeverityFromTotals {
    has record_id: str;
    has severity: str = "low";

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can evaluate with WasteRecord entry {
        if here.total_cost_usd >= 100.0 {
            self.severity = "critical";
        } elif here.total_cost_usd >= 50.0 {
            self.severity = "high";
        } elif here.total_cost_usd >= 20.0 {
            self.severity = "medium";
        } else {
            self.severity = "low";
        }
        here.severity = self.severity;
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "severity": self.severity};
    }
}
