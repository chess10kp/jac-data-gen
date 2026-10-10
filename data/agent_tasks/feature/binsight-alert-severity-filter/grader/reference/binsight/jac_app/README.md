# BinSight Jac Layer

Jac-powered intelligence and graph modeling for BinSight.

## Layout

```
jac_app/
├── waste_analysis.jac       # AnalyzeWaste walker (called by vision service)
├── recommendations.jac      # GenerateRecommendations walker (called by recommender)
├── home_page.jac            # GetHomePageContent walker (called by home router)
├── __init__.jac             # Package marker
└── extensions/              # Graph domain model + walker library
    ├── domain/              # Shared archetypes reused across walkers
    │   ├── nodes.jac        # DiningHall, MealService, WasteBin, WasteRecord, …
    │   ├── edges.jac        # Hosts, Features, Captured, Contains, Suggests, …
    │   ├── enums.jac        # MealPeriod, WasteCategory, WasteSeverity, …
    │   └── domain.jac       # Value objects (PortionSize, CostModel, …)
    └── walkers/             # Domain-scoped walker modules
        ├── hall_walkers.jac           # Dining halls, services, stations
        ├── menu_walkers.jac           # Menu items, scraping, normalization
        ├── waste_walkers.jac          # Bins, records, line items
        ├── recommendation_walkers.jac # Recommendation lifecycle
        ├── analytics_walkers.jac      # Trends, rollups, breakdowns
        ├── cost_walkers.jac           # Cost baselines and repricing
        ├── alert_walkers.jac          # Alerts, reviewers, escalations
        ├── vision_walkers.jac         # Image preflight + prompt orchestration
        ├── export_walkers.jac         # Dashboard / CSV payloads
        ├── query_walkers.jac          # Search and graph health
        ├── audit_walkers.jac          # Audit trail
        ├── schedule_walkers.jac       # Service windows and holidays
        └── seed_walkers.jac           # Fixture / demo data bootstrap
```

## Why two tiers?

The three walkers at the top of `jac_app/` are the ones the FastAPI layer
actually invokes today through adapters in `binsight/services/`:

| Walker                    | Called by                         |
| ------------------------- | --------------------------------- |
| `AnalyzeWaste`            | `services/jac_adapter.py`         |
| `GenerateRecommendations` | `services/jac_recommender_adapter.py` |
| `GetHomePageContent`      | `services/jac_home_adapter.py`    |

Everything under `extensions/` is the broader graph layer the product is
migrating toward — domain nodes/edges for dining halls, meal services, bins,
records, recommendations, alerts, trend points, cost baselines — plus the
walkers that operate on that graph (capture → summarize → recommend → audit).

As each Python service is replaced by a Jac walker, the corresponding walker
in `extensions/walkers/` gets promoted and wired into an adapter.
