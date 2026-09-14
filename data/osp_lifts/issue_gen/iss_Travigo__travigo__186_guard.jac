"""Travigo/travigo#186: attach bounded fare quotes to journey plans."""

node JourneyBook {
    has request_id: str;
    has fare_data_version: str = "";
    has quote_attempts: int = 0;
}

node JourneyPlan {
    has plan_id: str;
    has label: str;
    has fare_state: str = "unquoted";
    has fare_summary: str = "";
    has fare_amount: int = -1;
    has fare_currency: str = "";
    has fare_certainty: str = "";
    has fare_availability: str = "";
    has fare_expiry: int = 0;
    has fare_provider: str = "";
    has fare_ticket_boundaries: int = 0;
    has fare_alternatives: int = 0;
    has fare_comparison: str = "not_compared";
}

node FareQuote {
    has quote_id: str;
    has plan_id: str;
    has amount: int;
    has currency: str;
    has passenger: str;
    has certainty: str;
    has availability: str;
    has expiry: int;
    has provider: str;
    has ticket_boundaries: int = 0;
}

edge PlanLink {}
edge QuoteLink {}

walker FareCollector {
    has claimed: dict[str, bool] = {};
    has plans: list[JourneyPlan] = [];
    has quotes: list[FareQuote] = [];

    can collect_book with JourneyBook entry {
        print(here.request_id);
        for plan in [here ->:PlanLink:->][?:JourneyPlan] {
            visit :0: [plan];
        }
    }

    can collect_plan with JourneyPlan entry {
        if "p:" + here.plan_id in self.claimed {
            skip;
        }
        self.claimed["p:" + here.plan_id] = True;
        self.plans.append(here);
        print(here.plan_id);
        for kid in [here ->:PlanLink:->][?:JourneyPlan] {
            visit :0: [kid];
        }
        for quote in [here ->:QuoteLink:->][?:FareQuote] {
            visit :0: [quote];
        }
    }

    can collect_quote with FareQuote entry {
        if "q:" + here.quote_id in self.claimed {
            skip;
        }
        self.claimed["q:" + here.quote_id] = True;
        self.quotes.append(here);
        print(here.quote_id);
    }
}

walker PlanFinder {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: JourneyPlan | None = None;

    can find_book with JourneyBook entry {
        print(here.request_id);
        for plan in [here ->:PlanLink:->][?:JourneyPlan] {
            visit :0: [plan];
        }
    }

    can find_plan_node with JourneyPlan entry {
        if "p:" + here.plan_id in self.claimed {
            skip;
        }
        self.claimed["p:" + here.plan_id] = True;
        print(here.plan_id);
        if here.plan_id == self.wanted {
            self.found = here;
        }
        for kid in [here ->:PlanLink:->][?:JourneyPlan] {
            visit :0: [kid];
        }
    }
}

def add_plan(
    graph_root: JourneyBook, plan_id: str, label: str
) -> JourneyPlan {
    plan = JourneyPlan(plan_id=plan_id, label=label);
    graph_root +>:PlanLink:+> plan;
    return plan;
}

def add_quote(
    plan: JourneyPlan, quote_id: str, amount: int, currency: str,
    passenger: str, certainty: str, availability: str, expiry: int,
    provider: str, ticket_boundaries: int
) -> FareQuote {
    quote = FareQuote(
        quote_id=quote_id, plan_id=plan.plan_id, amount=amount,
        currency=currency, passenger=passenger, certainty=certainty,
        availability=availability, expiry=expiry, provider=provider,
        ticket_boundaries=ticket_boundaries
    );
    plan +>:QuoteLink:+> quote;
    return quote;
}

def find_plan(
    graph_root: JourneyBook, plan_id: str
) -> JourneyPlan | None {
    w = graph_root spawn PlanFinder(wanted=plan_id, claimed={});
    return w.found;
}

def planner_cache_key(graph_root: JourneyBook) -> str {
    return graph_root.request_id + ":" + graph_root.fare_data_version;
}

def attach_fares(
    graph_root: JourneyBook, include_fares: bool = False,
    max_quotes: int = 8, budget_ms: int = 500
) -> list[JourneyPlan] {
    w = graph_root spawn FareCollector(claimed={});
    graph_root.quote_attempts = 0;
    if !include_fares {
        return w.plans;
    }

    limit: int = max_quotes;
    if budget_ms < limit {
        limit = budget_ms;
    }
    if limit < 0 {
        limit = 0;
    }

    for plan in w.plans {
        plan.fare_state = "unquoted";
        plan.fare_summary = "";
        plan.fare_amount = -1;
        plan.fare_currency = "";
        plan.fare_certainty = "";
        plan.fare_availability = "";
        plan.fare_expiry = 0;
        plan.fare_provider = "";
        plan.fare_ticket_boundaries = 0;
        plan.fare_alternatives = 0;
        plan.fare_comparison = "not_compared";

        candidates: list[FareQuote] = [];
        for quote in w.quotes {
            if quote.plan_id == plan.plan_id {
                candidates.append(quote);
            }
        }
        if len(candidates) == 0 {
            plan.fare_state = "unavailable";
            continue;
        }

        baseline: FareQuote | None = None;
        incomparable: bool = False;
        attempted: int = 0;
        for quote in candidates {
            if graph_root.quote_attempts >= limit {
                break;
            }
            graph_root.quote_attempts = graph_root.quote_attempts + 1;
            attempted = attempted + 1;
            if quote.availability == "unavailable" or quote.availability == "timeout" {
                continue;
            }
            if baseline == None {
                baseline = quote;
            } elif quote.currency != baseline.currency or quote.passenger != baseline.passenger or quote.certainty != baseline.certainty {
                incomparable = True;
            } elif quote.amount < baseline.amount {
                baseline = quote;
            }
        }

        plan.fare_alternatives = len(candidates);
        if baseline == None {
            if attempted == 0 {
                plan.fare_state = "unquoted";
            } else {
                plan.fare_state = "unavailable";
            }
            continue;
        }

        plan.fare_summary = baseline.currency + " fare from " + baseline.provider;
        plan.fare_amount = baseline.amount;
        plan.fare_currency = baseline.currency;
        plan.fare_certainty = baseline.certainty;
        plan.fare_availability = baseline.availability;
        plan.fare_expiry = baseline.expiry;
        plan.fare_provider = baseline.provider;
        plan.fare_ticket_boundaries = baseline.ticket_boundaries;
        if incomparable {
            plan.fare_comparison = "incomparable";
        } else {
            plan.fare_comparison = "comparable";
        }
        if attempted < len(candidates) or baseline.ticket_boundaries > 0 {
            plan.fare_state = "partial";
        } elif baseline.certainty == "authoritative" {
            plan.fare_state = "authoritative";
        } else {
            plan.fare_state = "computed";
        }
    }
    return w.plans;
}

test "backward compatible without fares" {
    graph_root = JourneyBook(request_id="compat");
    plan = add_plan(graph_root, "p1", "local");
    add_quote(plan, "q1", 250, "GBP", "adult", "computed", "available", 99, "local", 0);
    plans = attach_fares(graph_root);
    assert (len(plans) == 1);
    assert (plan.fare_state == "unquoted");
    assert (plan.fare_amount == -1);
    assert (planner_cache_key(graph_root) == "compat:");
}

test "diamond revisit keeps closure complete" {
    graph_root = JourneyBook(request_id="diamond", fare_data_version="v2");
    a = JourneyPlan(plan_id="a", label="A");
    b = JourneyPlan(plan_id="b", label="B");
    c = JourneyPlan(plan_id="c", label="C");
    d = JourneyPlan(plan_id="d", label="D");
    graph_root +>:PlanLink:+> a;
    a +>:PlanLink:+> b;
    a +>:PlanLink:+> c;
    b +>:PlanLink:+> d;
    c +>:PlanLink:+> d;
    add_quote(d, "qd", 300, "GBP", "adult", "computed", "available", 120, "rail", 1);
    plans = attach_fares(graph_root, True, 10, 10);
    assert (len(plans) == 4);
    assert (d.fare_state == "partial");
    assert (d.fare_ticket_boundaries == 1);
    assert (graph_root.quote_attempts == 1);
}

test "unknown plan ids are tolerated" {
    graph_root = JourneyBook(request_id="unknown");
    known = add_plan(graph_root, "known", "TfL");
    ghost = FareQuote(
        quote_id="ghost", plan_id="missing", amount=10, currency="GBP",
        passenger="adult", certainty="computed", availability="available",
        expiry=50, provider="unknown", ticket_boundaries=0
    );
    known +>:QuoteLink:+> ghost;
    assert (find_plan(graph_root, "missing") == None);
    plans = attach_fares(graph_root, True, 4, 4);
    assert (len(plans) == 1);
    assert (known.fare_state == "unavailable");
}

test "incompatible quotes are not ranked cheapest" {
    graph_root = JourneyBook(request_id="currency");
    plan = add_plan(graph_root, "p1", "National Rail");
    add_quote(plan, "gbp", 100, "GBP", "adult", "computed", "available", 90, "nr", 0);
    add_quote(plan, "eur", 1, "EUR", "adult", "computed", "available", 90, "eu", 0);
    add_quote(plan, "child", 1, "GBP", "child", "computed", "available", 90, "nr", 0);
    attach_fares(graph_root, True, 10, 10);
    assert (plan.fare_amount == 100);
    assert (plan.fare_comparison == "incomparable");
    assert (plan.fare_provider == "nr");
}

test "provider failures respect the quote budget" {
    graph_root = JourneyBook(request_id="bounded");
    plan = add_plan(graph_root, "p1", "local");
    add_quote(plan, "down", 0, "GBP", "adult", "computed", "unavailable", 0, "local", 0);
    add_quote(plan, "slow", 0, "GBP", "adult", "computed", "timeout", 0, "rail", 0);
    attach_fares(graph_root, True, 1, 1);
    assert (graph_root.quote_attempts == 1);
    assert (plan.fare_state == "unavailable");
}
