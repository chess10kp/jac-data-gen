"""
NAVI — Gen Z Financial Life GPS
JacHacks 2026 | Fintech & Commerce Track
"""

import from byllm.llm {Model}

glob llm = Model(model_name="anthropic/claude-sonnet-4-20250514");

node UserProfile {
    has name: str = "";
    has age: int = 0;
    has income_monthly: float = 0.0;
    has expenses_monthly: float = 0.0;
    has savings_total: float = 0.0;
    has credit_score: int = 0;
    has credit_invisible: bool = True;
    has student_loan_balance: float = 0.0;
    has student_loan_rate: float = 0.0;
    has student_loan_payment: float = 0.0;
    has rent_monthly: float = 0.0;
    has zip_code: str = "";
    has state: str = "";
    has is_first_gen: bool = False;
    has employment_type: str = "student";
    has life_stage: str = "college_student";
    has housing_status: str = "renting";
    has financial_health_score: int = 0;
    has xp_points: int = 0;
    has streak_days: int = 0;
}

node FinancialGoal {
    has goal_type: str = "";
    has title: str = "";
    has target_amount: float = 0.0;
    has current_progress: float = 0.0;
    has priority: int = 1;
    has status: str = "not_started";
    has estimated_months: int = 0;
}

node ActionStep {
    has action_id: str = "";
    has title: str = "";
    has description: str = "";
    has category: str = "";
    has difficulty: str = "easy";
    has estimated_impact: str = "";
    has time_to_complete: str = "";
    has cost: float = 0.0;
    has url: str = "";
    has is_completed: bool = False;
    has xp_reward: int = 25;
    has prerequisites: list = [];
    has ai_explanation: str = "";
}

node Resource {
    has resource_id: str = "";
    has name: str = "";
    has resource_type: str = "";
    has provider: str = "";
    has amount: str = "";
    has eligibility_summary: str = "";
    has eligibility_criteria: dict = {};
    has url: str = "";
    has match_score: float = 0.0;
    has is_match: bool = False;
}

node Milestone {
    has milestone_id: str = "";
    has title: str = "";
    has description: str = "";
    has category: str = "";
    has threshold_type: str = "";
    has threshold_value: float = 0.0;
    has is_achieved: bool = False;
    has xp_reward: int = 100;
    has unlocks: list = [];
    has celebration_message: str = "";
}

node InsuranceNeed {
    has insurance_type: str = "";
    has priority: str = "medium";
    has estimated_cost: str = "";
    has has_coverage: bool = False;
    has explanation: str = "";
}

node LeaseClause {
    has clause_text: str = "";
    has category: str = "";
    has risk_level: str = "green";
    has is_illegal: bool = False;
    has statute_reference: str = "";
    has plain_english: str = "";
}

edge HasGoal { has priority: int = 1; }
edge RequiresAction { has order: int = 1; }
edge NextStep {}
edge LeadsToMilestone { has estimated_days: int = 0; }
edge HasMilestone { has order: int = 1; }
edge QualifiesFor { has match_score: float = 0.0; }

walker PathfinderWalker {
    has user_data: dict = {};
    has current_goal: dict = {};
    has path_steps: list = [];
    has milestones: list = [];
    has full_path: dict = {};

    can enter_root with Root entry { visit [-->]; }

    can process_user with UserProfile entry {
        self.user_data = {
            "name": here.name, "age": here.age,
            "income": here.income_monthly, "expenses": here.expenses_monthly,
            "savings": here.savings_total, "credit_score": here.credit_score,
            "credit_invisible": here.credit_invisible,
            "student_loans": here.student_loan_balance,
            "rent": here.rent_monthly, "state": here.state,
            "is_first_gen": here.is_first_gen,
            "employment": here.employment_type
        };
        visit [-->];
    }

    can process_goal with FinancialGoal entry {
        self.current_goal = {
            "type": here.goal_type, "title": here.title,
            "target": here.target_amount,
            "progress": here.current_progress, "status": here.status
        };
        self.path_steps = [];
        visit [-->];
    }

    can process_step with ActionStep entry {
        if not here.is_completed {
            explanation = self.generate_advice(
                self.user_data,
                {"title": here.title, "description": here.description,
                 "category": here.category, "impact": here.estimated_impact,
                 "cost": here.cost},
                self.current_goal
            );
            here.ai_explanation = explanation;
            self.path_steps.append({
                "step_number": len(self.path_steps) + 1,
                "action_id": here.action_id, "title": here.title,
                "category": here.category, "difficulty": here.difficulty,
                "time": here.time_to_complete, "cost": here.cost,
                "xp": here.xp_reward, "explanation": explanation,
                "url": here.url
            });
        }
        visit [-->];
    }

    can process_milestone with Milestone entry {
        self.milestones.append({
            "id": here.milestone_id, "title": here.title,
            "description": here.description, "category": here.category,
            "threshold": here.threshold_value, "achieved": here.is_achieved,
            "xp": here.xp_reward, "unlocks": here.unlocks
        });
    }

    can finalize with exit {
        self.full_path = {
            "user": self.user_data.get("name", ""),
            "goal": self.current_goal,
            "steps": self.path_steps,
            "milestones": self.milestones,
            "total_xp": sum([s.get("xp", 0) for s in self.path_steps])
        };
    }

    """Generate personalized financial advice for a specific action step.
    Use friendly Gen Z tone. Reference user's specific numbers.
    2-3 sentences. Educational info only, not financial advice."""
    def generate_advice(user_profile: dict, action_step: dict, goal: dict) -> str by llm();
}

walker EligibilityWalker {
    has user_data: dict = {};
    has matched_resources: list = [];

    can enter_root with Root entry { visit [-->]; }

    can process_user with UserProfile entry {
        self.user_data = {
            "name": here.name, "age": here.age,
            "income_monthly": here.income_monthly,
            "income_annual": here.income_monthly * 12,
            "savings": here.savings_total,
            "credit_score": here.credit_score,
            "credit_invisible": here.credit_invisible,
            "student_loans": here.student_loan_balance,
            "state": here.state, "zip_code": here.zip_code,
            "is_first_gen": here.is_first_gen,
            "employment": here.employment_type,
            "housing": here.housing_status
        };
        visit [-->];
    }

    can check_resource with Resource entry {
        result = self.check_eligibility(
            self.user_data,
            {"name": here.name, "type": here.resource_type,
             "criteria": here.eligibility_criteria,
             "summary": here.eligibility_summary}
        );
        here.match_score = result.get("score", 0.0);
        here.is_match = result.get("eligible", False);
        if here.is_match {
            self.matched_resources.append({
                "name": here.name, "type": here.resource_type,
                "amount": here.amount, "provider": here.provider,
                "match_score": here.match_score,
                "explanation": result.get("explanation", ""),
                "url": here.url
            });
        }
    }

    can finalize with exit {
        self.matched_resources = self.matched_resources;
    }

    """Check if user qualifies for a resource. Return dict with:
    eligible (bool), score (float 0-1), explanation (str)."""
    def check_eligibility(user_profile: dict, resource: dict) -> dict by llm();
}

walker SimulationWalker {
    has scenario_changes: dict = {};
    has baseline: dict = {};
    has projection: dict = {};

    can enter_root with Root entry { visit [-->]; }

    can run_sim with UserProfile entry {
        self.baseline = {
            "income": here.income_monthly, "expenses": here.expenses_monthly,
            "savings": here.savings_total, "credit_score": here.credit_score,
            "student_loans": here.student_loan_balance,
            "loan_rate": here.student_loan_rate,
            "loan_payment": here.student_loan_payment,
            "rent": here.rent_monthly
        };
        self.projection = self.project_future(self.baseline, self.scenario_changes);
    }

    """Project financial future over 1, 3, 5 years. Return dict with:
    credit_score_1yr, savings_1yr, debt_1yr, months_to_mortgage_ready,
    narrative (Gen Z tone comparing baseline vs scenario)."""
    def project_future(baseline: dict, changes: dict) -> dict by llm();
}

walker HealthScoreWalker {
    has score: int = 0;
    has breakdown: dict = {};
    has summary: str = "";

    can enter_root with Root entry { visit [-->]; }

    can calculate with UserProfile entry {
        sr = 0.0;
        if here.income_monthly > 0 {
            sr = (here.income_monthly - here.expenses_monthly) / here.income_monthly;
        }
        dti = here.student_loan_payment / here.income_monthly if here.income_monthly > 0 else 0.0;
        rb = here.rent_monthly / here.income_monthly if here.income_monthly > 0 else 0.0;
        factors = {
            "savings_rate": sr,
            "has_emergency_fund": here.savings_total >= here.expenses_monthly * 3,
            "credit_score": here.credit_score,
            "credit_invisible": here.credit_invisible,
            "debt_to_income": dti, "rent_burden": rb
        };
        result = self.compute_health(factors);
        self.score = result.get("score", 0);
        self.breakdown = result.get("breakdown", {});
        self.summary = result.get("summary", "");
        here.financial_health_score = self.score;
    }

    """Compute financial health score 0-100. Weights: savings_rate 25pts,
    emergency_fund 20pts, credit 25pts, DTI 15pts, rent_burden 15pts.
    Return dict: score (int), breakdown (dict), summary (str Gen Z tone)."""
    def compute_health(factors: dict) -> dict by llm();
}

walker InsuranceGapWalker {
    has insurance_gaps: list = [];

    can enter_root with Root entry { visit [-->]; }

    can analyze with UserProfile entry {
        situation = {
            "age": here.age, "housing": here.housing_status,
            "employment": here.employment_type,
            "income": here.income_monthly, "state": here.state
        };
        self.insurance_gaps = self.find_gaps(situation);
    }

    """Find insurance gaps for Gen Z user. Return list of dicts with:
    type, priority, estimated_monthly_cost, risk_description, action.
    Only 21% of Gen Z has renters insurance."""
    def find_gaps(user_situation: dict) -> list by llm();
}

walker LeaseAnalyzerWalker {
    has lease_text: str = "";
    has state: str = "";
    has analysis: list = [];
    has overall_risk: str = "low";
    has dispute_letter: str = "";

    can enter_root with Root entry {
        self.analysis = self.analyze_lease(self.lease_text, self.state);
        red_clauses = [c for c in self.analysis if c.get("risk_level") == "red"];
        if red_clauses {
            self.dispute_letter = self.generate_dispute(red_clauses, self.state);
            self.overall_risk = "high";
        } elif [c for c in self.analysis if c.get("risk_level") == "yellow"] {
            self.overall_risk = "medium";
        }
    }

    """Analyze residential lease for a US state. For each clause return:
    clause_summary, category, risk_level (green/yellow/red), is_illegal,
    statute_reference, plain_english. Return list of dicts."""
    def analyze_lease(lease_text: str, state: str) -> list by llm();

    """Generate dispute letter for illegal clauses citing state statutes."""
    def generate_dispute(illegal_clauses: list, state: str) -> str by llm();
}

walker ChatWalker {
    has user_message: str = "";
    has response: str = "";

    can enter_root with Root entry { visit [-->]; }

    can process with UserProfile entry {
        ud = {
            "name": here.name, "age": here.age,
            "income": here.income_monthly, "savings": here.savings_total,
            "credit_score": here.credit_score,
            "credit_invisible": here.credit_invisible,
            "student_loans": here.student_loan_balance,
            "rent": here.rent_monthly, "state": here.state,
            "health_score": here.financial_health_score
        };
        self.response = self.answer(self.user_message, ud);
    }

    """You are Navi, friendly AI financial guide for Gen Z. Casual tone,
    reference user's specific numbers. Educational info only. 3-5 sentences."""
    def answer(question: str, user_profile: dict) -> str by llm();
}

"""Create financial summary: strengths, risks, top next action. 4-6 sentences."""
def create_financial_summary(user_profile: dict) -> str by llm();

"""Celebratory message for milestone. Hype, emoji, what it unlocks. 2-3 sentences."""
def generate_celebration(milestone_title: str, user_name: str, unlocked_items: list) -> str by llm();

def build_navi_graph() {
    maya = UserProfile(
        name="Maya", age=22, income_monthly=3200.0,
        expenses_monthly=2800.0, savings_total=1500.0,
        credit_score=0, credit_invisible=True,
        student_loan_balance=28000.0, student_loan_rate=5.5,
        student_loan_payment=280.0, rent_monthly=1200.0,
        zip_code="48104", state="MI", is_first_gen=True,
        employment_type="student", life_stage="college_student",
        housing_status="renting"
    );
    g1 = FinancialGoal(goal_type="credit_building", title="Build my credit from scratch", target_amount=650.0, priority=1);
    g2 = FinancialGoal(goal_type="homeownership", title="Buy my first home", target_amount=25000.0, current_progress=1500.0, priority=2);
    g3 = FinancialGoal(goal_type="emergency_fund", title="Build emergency fund", target_amount=8400.0, current_progress=1500.0, priority=3, status="in_progress");
    s1 = ActionStep(action_id="create_budget", title="Create a monthly budget", description="Track income vs expenses using 50/30/20 rule", category="savings", difficulty="easy", estimated_impact="Foundation for all goals", time_to_complete="45 min", xp_reward=25);
    s2 = ActionStep(action_id="open_secured_card", title="Open a Discover It Secured Card", description="$200 deposit to start building credit", category="credit", difficulty="easy", estimated_impact="+30-50 points in 6 months", time_to_complete="30 min", cost=200.0, url="https://www.discover.com/credit-cards/secured/", xp_reward=50);
    s3 = ActionStep(action_id="setup_autopay", title="Set up autopay for all bills", description="Payment history is 35% of credit score", category="credit", difficulty="easy", estimated_impact="Prevents missed payments", time_to_complete="20 min", xp_reward=30);
    s4 = ActionStep(action_id="rent_reporting", title="Enroll in Esusu rent reporting", description="Report $1200/mo rent to credit bureaus free", category="credit", difficulty="easy", estimated_impact="Avg 45-point increase", time_to_complete="15 min", url="https://www.esusu.com/", xp_reward=35);
    s5 = ActionStep(action_id="open_hysa", title="Open high-yield savings account", description="Earn 4-5% APY vs 0.01%", category="savings", difficulty="easy", estimated_impact="$60-75/yr on $1500", time_to_complete="20 min", xp_reward=30);
    s6 = ActionStep(action_id="auto_savings", title="Automate $100/month to savings", description="Pay yourself first on payday", category="savings", difficulty="easy", estimated_impact="$1200/yr saved", time_to_complete="10 min", xp_reward=25);
    s7 = ActionStep(action_id="review_loans", title="Review student loan repayment plan", description="May qualify for income-driven repayment", category="debt", difficulty="medium", estimated_impact="Could reduce payment $50-150/mo", time_to_complete="1 hour", url="https://studentaid.gov/manage-loans/repayment/plans", xp_reward=40);
    s8 = ActionStep(action_id="research_fha", title="Learn FHA loan requirements", description="FHA needs 3.5% down with 580 score", category="housing", difficulty="easy", estimated_impact="Understanding path to ownership", time_to_complete="30 min", xp_reward=20);
    s9 = ActionStep(action_id="apply_dpa", title="Apply for MSHDA Step Forward DPA", description="Up to $7500 down payment help for MI buyers", category="housing", difficulty="hard", estimated_impact="$7500 toward down payment", time_to_complete="2 hours", xp_reward=100);
    s10 = ActionStep(action_id="complete_fafsa", title="Complete your FAFSA", description="Unlock Pell Grants and need-based aid", category="scholarship", difficulty="medium", estimated_impact="Avg Pell Grant $4000+/yr", time_to_complete="1-2 hours", url="https://studentaid.gov/h/apply-for-aid/fafsa", xp_reward=75);
    s11 = ActionStep(action_id="check_benefits", title="Check government benefit eligibility", description="May qualify for SNAP, Medicaid, LIHEAP", category="benefits", difficulty="easy", estimated_impact="$2000-5000/yr unclaimed", time_to_complete="20 min", xp_reward=30);
    m1 = Milestone(milestone_id="credit_580", title="Credit score reaches 580", description="FHA minimum!", category="credit", threshold_type="credit_score_gte", threshold_value=580.0, xp_reward=150, unlocks=["FHA loan eligibility"], celebration_message="From invisible to FHA-eligible!");
    m2 = Milestone(milestone_id="credit_650", title="Credit score reaches 650", description="Good rates unlocked", category="credit", threshold_type="credit_score_gte", threshold_value=650.0, xp_reward=200, unlocks=["Conventional loans", "MSHDA DPA"], celebration_message="650 club! DPA programs open.");
    m3 = Milestone(milestone_id="credit_700", title="Credit score reaches 700", description="Excellent rates", category="credit", threshold_type="credit_score_gte", threshold_value=700.0, xp_reward=300, unlocks=["Best mortgage rates"], celebration_message="700! Top tier rates.");
    m4 = Milestone(milestone_id="emergency_1k", title="Emergency fund hits $1,000", description="First safety net", category="savings", threshold_type="savings_gte", threshold_value=1000.0, xp_reward=100, unlocks=["Handle minor emergencies"], celebration_message="$1K saved!");
    m5 = Milestone(milestone_id="savings_5k", title="Savings reach $5,000", description="Real cushion", category="savings", threshold_type="savings_gte", threshold_value=5000.0, xp_reward=200, unlocks=["3+ month runway"], celebration_message="$5K! Top 22% for your age.");
    m6 = Milestone(milestone_id="home_ready", title="Mortgage pre-qualification ready", description="Credit 640+, savings, income", category="housing", threshold_type="credit_score_gte", threshold_value=640.0, xp_reward=500, unlocks=["Mortgage pre-qual"], celebration_message="MORTGAGE READY.");
    r1 = Resource(resource_id="mshda_dpa", name="MSHDA Step Forward DPA", resource_type="dpa_program", provider="MSHDA", amount="Up to $7,500", eligibility_summary="First-time MI buyers, credit 640+", eligibility_criteria={"min_credit": 640, "state": "MI"}, url="https://www.michigan.gov/mshda");
    r2 = Resource(resource_id="pell", name="Federal Pell Grant", resource_type="scholarship", provider="US DOE", amount="Up to $7,395/yr", eligibility_summary="FAFSA-based need", eligibility_criteria={"student": True}, url="https://studentaid.gov");
    r3 = Resource(resource_id="snap", name="SNAP (Food Assistance)", resource_type="government_benefit", provider="MI DHHS", amount="$234/mo avg", eligibility_summary="Income under 130% FPL", eligibility_criteria={"max_income_monthly": 1580, "state": "MI"}, url="https://michigan.gov/mdhhs");
    r4 = Resource(resource_id="medicaid", name="Healthy Michigan (Medicaid)", resource_type="government_benefit", provider="MI DHHS", amount="Free health insurance", eligibility_summary="Income up to 138% FPL", eligibility_criteria={"max_income_monthly": 1732, "state": "MI"}, url="https://michigan.gov/mdhhs");
    r5 = Resource(resource_id="liheap", name="LIHEAP Utility Assistance", resource_type="government_benefit", provider="MI DHHS", amount="$200-500/season", eligibility_summary="Income under 150% FPL", eligibility_criteria={"max_income_monthly": 1830, "state": "MI"}, url="https://michigan.gov/mdhhs");
    r6 = Resource(resource_id="esusu", name="Esusu Rent Reporting", resource_type="credit_tool", provider="Esusu", amount="Free", eligibility_summary="Any renter", eligibility_criteria={"housing": "renting"}, url="https://www.esusu.com/");
    r7 = Resource(resource_id="discover", name="Discover It Secured Card", resource_type="credit_tool", provider="Discover", amount="$200 deposit", eligibility_summary="No credit needed", eligibility_criteria={"min_deposit": 200}, url="https://discover.com");
    r8 = Resource(resource_id="aotc", name="American Opportunity Tax Credit", resource_type="tax_credit", provider="IRS", amount="Up to $2,500/yr", eligibility_summary="Undergrad, income under $80K", eligibility_criteria={"student": True, "max_income": 80000}, url="https://irs.gov");
    r9 = Resource(resource_id="zell", name="Zell Lurie Grants", resource_type="scholarship", provider="UMich Ross", amount="$1K-$5K", eligibility_summary="UMich entrepreneurs", eligibility_criteria={"school": "umich"}, url="https://zfranchise.umich.edu/");
    r10 = Resource(resource_id="work_study", name="Federal Work-Study", resource_type="scholarship", provider="US DOE", amount="Part-time employment", eligibility_summary="FAFSA need-based", eligibility_criteria={"student": True}, url="https://studentaid.gov");

    root ++> maya;
    maya ++> g1; maya ++> g2; maya ++> g3;
    g1 ++> s1; g1 ++> s2; g1 ++> s3; g1 ++> s4;
    s1 ++> s2; s2 ++> s3;
    s2 ++> m1; s3 ++> m2; s4 ++> m2;
    g1 ++> m1; g1 ++> m2; g1 ++> m3;
    g2 ++> s8; g2 ++> s9; s9 ++> m6; g2 ++> m6;
    g3 ++> s5; g3 ++> s6; s5 ++> s6; s6 ++> m4; s6 ++> m5; g3 ++> m4; g3 ++> m5;
    maya ++> s7; maya ++> s10; maya ++> s11;
    maya ++> r1; maya ++> r2; maya ++> r3; maya ++> r4; maya ++> r5;
    maya ++> r6; maya ++> r7; maya ++> r8; maya ++> r9; maya ++> r10;
}

with entry {
    print("=== NAVI — Your Financial Life, Mapped ===");
    print("=== JacHacks 2026 | Fintech & Commerce ===\n");
    build_navi_graph();
    print("Graph built: Maya's financial life mapped.\n");
    print("--- Health Score ---");
    health = root spawn HealthScoreWalker();
    print(f"Score: {health.score}/100\n{health.summary}\n");
    print("--- Pathfinder: Credit Building ---");
    pf = root spawn PathfinderWalker();
    p = pf.full_path;
    print(f"Goal: {p.get('goal', {}).get('title', '?')}");
    print(f"Steps: {len(p.get('steps', []))} | XP: {p.get('total_xp', 0)}\n");
    steps_list: list = p.get("steps", []);
    for s in steps_list {
        print(f"  {s['step_number']}. {s['title']} ({s['difficulty']}, {s['time']}, +{s['xp']}XP)");
        print(f"     {s['explanation']}\n");
    }
    ms_list: list = p.get("milestones", []);
    for ms in ms_list {
        icon = "X" if ms["achieved"] else " ";
        print(f"  [{icon}] {ms['title']} (+{ms['xp']}XP)");
    }
    print("\n--- Eligibility Scanner ---");
    el = root spawn EligibilityWalker();
    for r in el.matched_resources {
        print(f"  [{int(float(r.get('match_score', 0))*100)}%] {r['name']}: {r['amount']}");
        print(f"       {r['explanation']}");
    }
    print("\n--- Simulation: +$200/mo savings ---");
    sim = SimulationWalker(scenario_changes={"extra_savings": 200});
    root spawn sim;
    print(f"  {sim.projection.get('narrative', 'Done.')}\n");
    print("--- Insurance Gaps ---");
    ins = root spawn InsuranceGapWalker();
    for g in ins.insurance_gaps {
        print(f"  ! {g.get('type','?')}: {g.get('risk_description','')}");
        print(f"    Cost: {g.get('estimated_monthly_cost','?')} | Do: {g.get('action','')}");
    }
    print("\n--- Chat ---");
    chat = ChatWalker(user_message="How do I build credit from zero?");
    root spawn chat;
    print(f"  You: How do I build credit from zero?");
    print(f"  Navi: {chat.response}\n");
    print("--- Summary ---");
    s = create_financial_summary({"name": "Maya", "age": 22, "income": 3200, "expenses": 2800, "savings": 1500, "credit_score": 0, "credit_invisible": True, "student_loans": 28000, "rent": 1200, "is_first_gen": True});
    print(f"  {s}\n");
    print("=== Navi ready. Walkers deployed. ===");
}
