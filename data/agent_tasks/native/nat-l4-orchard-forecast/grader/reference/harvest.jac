"""Harvest forecasting over the orchard graph."""
import from model.varieties { Variety, MATURE_KG, age_factor }
import from model.orchard { Block, Row, Tree, HasRow, HasTree }

obj Forecast {
    has block: str;
    has total_kg: float;
    has by_variety: dict[str, float];
    has trees_counted: int;
}

"""Spawn on a Block: walk rows -> trees and sum the expected harvest."""
walker ForecastBlock {
    has block_name: str = "";
    has kg: dict[str, float] = {};
    has counted: int = 0;

    can enter_block with Block entry {
        self.block_name = here.name;
        visit [here ->:HasRow:->];
    }

    can enter_row with Row entry {
        visit [here ->:HasTree:->];
    }

    can weigh with Tree entry {
        if here.diseased {
            return;
        }
        name = here.variety.name;
        self.kg[name] = self.kg.get(name, 0.0) + MATURE_KG[name] * age_factor(here.age);
        self.counted += 1;
    }

    can finish with Block exit {
        report Forecast(
            block=self.block_name,
            total_kg=sum(self.kg.values()),
            by_variety=self.kg,
            trees_counted=self.counted
        );
    }
}
