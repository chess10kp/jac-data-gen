"""ChainWalker: traverses drug interaction graph to detect compounding risk chains."""

import from graph { Drug, InteractsWith }
import from rules { get_multiplier, RISK_THRESHOLD }

glob _collected_chains: list[dict] = [];

def reset_collector() {
    _collected_chains.clear();
}

def get_collected_chains() -> list[dict] {
    return list(_collected_chains);
}

walker ChainWalker {
    has current_path: list[str] = [],
        accumulated_risk: float = 0.0,
        max_depth: int = 3,
        last_interaction_type: str = "";

    can detect with Drug entry {
        self.current_path = self.current_path + [here.name];

        if len(self.current_path) > self.max_depth + 1 {
            disengage;
        }

        if self.accumulated_risk >= RISK_THRESHOLD and len(self.current_path) > 1 {
            here.is_flagged = True;
            risk_rounded = float(int(self.accumulated_risk * 1000)) / 1000.0;
            _collected_chains.append({
                "path": list(self.current_path),
                "risk": risk_rounded,
                "depth": len(self.current_path) - 1
            });
        }

        if len(self.current_path) > self.max_depth {
            disengage;
        }

        for target in [->:InteractsWith:->] {
            edge_list: list = [edge ->:InteractsWith:-> target];
            if len(edge_list) == 0 {
                continue;
            }
            edge_obj: InteractsWith = edge_list[0];
            target_drug: Drug = target;

            if target_drug.name in self.current_path {
                continue;
            }

            itype = edge_obj.interaction_type;
            sev = edge_obj.severity;
            multiplier = get_multiplier(self.last_interaction_type, str(itype));

            new_risk = float(sev);
            if self.accumulated_risk > 0.0 {
                new_risk = self.accumulated_risk + (float(sev) * float(multiplier));
            }

            ChainWalker(
                current_path=list(self.current_path),
                accumulated_risk=new_risk,
                max_depth=self.max_depth,
                last_interaction_type=str(itype)
            ) spawn target_drug;
        }
    }
}
