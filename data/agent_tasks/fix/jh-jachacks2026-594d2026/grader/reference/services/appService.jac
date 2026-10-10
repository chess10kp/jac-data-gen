import from byllm.lib { Model }
import os;
import json;
import from urllib.request { urlopen, Request }
import from urllib.parse { urlencode, quote_plus }

glob llm: Model = Model(model_name="gemini/gemini-2.5-flash", api_key="REDACTED_GEMINI_API_KEY");

# ==== DATA NODES ====

node Goal {
    has title: str;
    has description: str = "";
    has timeline: str = "3 months";
    has progress: int = 0;
    has status: str = "active";
    has created_at: str = "";
}

node Mission {
    has title: str;
    has difficulty: str = "Medium";
    has xp: int = 100;
    has done: bool = False;
    has tag: str = "General";
    has goal_id: str = "";
}

node MemoryEntry {
    has summary: str;
    has tags: str = "";
    has focus_score: int = 80;
    has duration: str = "1h";
    has created_at: str = "";
}

node AgentLog {
    has agent_name: str;
    has action: str;
    has detail: str = "";
    has timestamp: str = "";
    has status: str = "completed";
}

node AIInsightEntry {
    has text: str;
    has icon: str = "💡";
    has insight_type: str = "info";
    has goal_id: str = "";
}

# ==== AI AGENT OBJECTS ====

obj MissionPlan {
    has missions: list[str];
    has tags: list[str];
    has difficulties: list[str];
    has xp_values: list[int];
}

sem MissionPlan.missions = "List of 5 to 7 specific, actionable daily mission titles for the goal. Each should be a concrete task the user can complete in 1-3 hours.";
sem MissionPlan.tags = "Category tag for each mission matching its index. Use: DSA, ML, Python, Project, Career, Reading, System Design, Math, Research, Practice.";
sem MissionPlan.difficulties = "Difficulty level for each mission matching its index. Use exactly: Easy, Medium, or Hard.";
sem MissionPlan.xp_values = "XP reward for each mission matching its index. Easy=50-80, Medium=100-150, Hard=200-300.";

obj InsightReport {
    has insights: list[str];
    has coach_message: str;
    has predicted_completion: str;
    has risk_level: str;
}

sem InsightReport.insights = "List of 4 specific AI insights about the user's progress. Each insight should be 1 sentence, specific and actionable. Include strengths, weaknesses, patterns, and predictions.";
sem InsightReport.coach_message = "A motivating, personalized coach message in 1-2 sentences based on the user's current progress.";
sem InsightReport.predicted_completion = "Predicted completion date or timeframe based on current progress rate. Be specific.";
sem InsightReport.risk_level = "Risk assessment: Low, Medium, or High based on current trajectory.";

obj StrategyReport {
    has milestones: list[str];
    has weekly_focus: str;
    has key_resources: list[str];
    has agent_insights: list[str];
}

sem StrategyReport.milestones = "List of 4-6 major milestones to achieve the goal in order. Each milestone should be a clear achievement.";
sem StrategyReport.weekly_focus = "What the user should focus on THIS week to make the most progress. 1-2 sentences.";
sem StrategyReport.key_resources = "List of 4-5 specific learning resources, courses, or tools for this goal. Include names and brief descriptions.";
sem StrategyReport.agent_insights = "List of 4 insights from different AI agents (Planner, Research, Coach, Analytics). Each prefixed with agent name.";

obj OpportunityReport {
    has internships: list[str];
    has courses: list[str];
    has projects: list[str];
    has networking: list[str];
}

sem OpportunityReport.internships = "List of 4-5 specific internship or job opportunities relevant to the goal. Include company names and roles.";
sem OpportunityReport.courses = "List of 4-5 specific online courses or certifications. Include platform and course name.";
sem OpportunityReport.projects = "List of 4-5 project ideas that would build skills for this goal. Be specific.";
sem OpportunityReport.networking = "List of 3-4 networking opportunities: communities, events, or people to connect with.";

# ==== AI AGENT LLM FUNCTIONS ====

async def ai_plan_missions(goal_title: str, goal_description: str, timeline: str) -> MissionPlan by llm(temperature=0.7, max_tokens=1200);
sem ai_plan_missions = "You are the Planner Agent in FutureOS. Generate a structured mission plan for a user's long-term goal. Create specific, actionable daily missions that progressively build toward the goal.";
sem ai_plan_missions.goal_title = "The user's long-term goal title";
sem ai_plan_missions.goal_description = "Additional description of the goal and what success looks like";
sem ai_plan_missions.timeline = "The timeline to achieve the goal (e.g. 6 months)";

async def ai_generate_insights(goal_title: str, timeline: str, progress: int, done_missions: int, total_missions: int, days_active: int) -> InsightReport by llm(temperature=0.5, max_tokens=800);
sem ai_generate_insights = "You are the Analytics and Coach Agent in FutureOS. Analyze the user's progress data and generate personalized insights, predictions, and coaching advice.";
sem ai_generate_insights.goal_title = "The user's goal title";
sem ai_generate_insights.timeline = "The target timeline for the goal";
sem ai_generate_insights.progress = "Current progress percentage (0-100)";
sem ai_generate_insights.done_missions = "Number of missions completed";
sem ai_generate_insights.total_missions = "Total number of missions";
sem ai_generate_insights.days_active = "Number of days the user has been working on this goal";

async def ai_build_strategy(goal_title: str, goal_description: str, timeline: str) -> StrategyReport by llm(temperature=0.6, max_tokens=1000);
sem ai_build_strategy = "You are the Planner and Research Agent in FutureOS. Build a comprehensive strategy for achieving the user's goal including milestones, resources, and multi-agent insights.";
sem ai_build_strategy.goal_title = "The user's long-term goal";
sem ai_build_strategy.goal_description = "Description of the goal";
sem ai_build_strategy.timeline = "Target timeline";

async def ai_find_opportunities(goal_title: str, timeline: str) -> OpportunityReport by llm(temperature=0.7, max_tokens=1000);
sem ai_find_opportunities = "You are the Research Agent in FutureOS. Find and curate specific opportunities, resources, and connections relevant to the user's goal.";
sem ai_find_opportunities.goal_title = "The user's goal";
sem ai_find_opportunities.timeline = "Timeline for the goal";

# ==== HELPER: LOG AGENT ACTION ====

def log_agent(agent_name: str, action: str, detail: str) -> None {
    (root ++> AgentLog(agent_name=agent_name, action=action, detail=detail, timestamp="now", status="completed"));
}

# ==== RULE-BASED MISSION TEMPLATES ====

def get_mission_templates(goal_title: str, timeline: str) -> list[dict] {
    title_lower: str = goal_title.lower();
    templates: list[dict] = [];
    if "ai" in title_lower or "machine learning" in title_lower or "ml" in title_lower {
        templates = [
            {"title": "Complete Python fundamentals — functions, OOP, libraries", "tag": "Python", "difficulty": "Easy", "xp": 70},
            {"title": "Study NumPy and Pandas for data manipulation", "tag": "ML", "difficulty": "Medium", "xp": 120},
            {"title": "Build a linear regression model from scratch", "tag": "ML", "difficulty": "Medium", "xp": 130},
            {"title": "Complete fast.ai Practical Deep Learning Chapter 1", "tag": "Reading", "difficulty": "Easy", "xp": 80},
            {"title": "Implement a neural network using PyTorch", "tag": "Project", "difficulty": "Hard", "xp": 250},
            {"title": "Solve 3 LeetCode medium problems", "tag": "DSA", "difficulty": "Medium", "xp": 150},
            {"title": "Deploy an ML model using FastAPI", "tag": "Project", "difficulty": "Hard", "xp": 280}
        ];
    } elif "engineer" in title_lower or "developer" in title_lower or "software" in title_lower {
        templates = [
            {"title": "Solve 5 LeetCode easy problems on arrays", "tag": "DSA", "difficulty": "Easy", "xp": 70},
            {"title": "Study system design: Load balancers and caching", "tag": "System Design", "difficulty": "Medium", "xp": 130},
            {"title": "Build a REST API with authentication", "tag": "Project", "difficulty": "Hard", "xp": 250},
            {"title": "Read Clean Code chapters 1-3", "tag": "Reading", "difficulty": "Easy", "xp": 60},
            {"title": "Implement binary search tree with all operations", "tag": "DSA", "difficulty": "Medium", "xp": 140},
            {"title": "Set up CI/CD pipeline for a project", "tag": "DevOps", "difficulty": "Hard", "xp": 220},
            {"title": "Apply to 3 internship positions on LinkedIn", "tag": "Career", "difficulty": "Easy", "xp": 80}
        ];
    } elif "startup" in title_lower or "business" in title_lower or "entrepreneur" in title_lower {
        templates = [
            {"title": "Define your target customer and problem statement", "tag": "Research", "difficulty": "Easy", "xp": 70},
            {"title": "Build and test a landing page MVP", "tag": "Project", "difficulty": "Medium", "xp": 150},
            {"title": "Conduct 5 customer discovery interviews", "tag": "Research", "difficulty": "Medium", "xp": 130},
            {"title": "Create a business model canvas", "tag": "Planning", "difficulty": "Easy", "xp": 80},
            {"title": "Launch product on Product Hunt", "tag": "Marketing", "difficulty": "Hard", "xp": 300},
            {"title": "Set up analytics and track key metrics", "tag": "Analytics", "difficulty": "Medium", "xp": 120}
        ];
    } elif "finance" in title_lower or "invest" in title_lower or "money" in title_lower {
        templates = [
            {"title": "Read The Psychology of Money — chapters 1-5", "tag": "Reading", "difficulty": "Easy", "xp": 70},
            {"title": "Set up a monthly budget tracker", "tag": "Practice", "difficulty": "Easy", "xp": 60},
            {"title": "Research and open an index fund account", "tag": "Research", "difficulty": "Medium", "xp": 120},
            {"title": "Calculate your net worth and set 6-month targets", "tag": "Planning", "difficulty": "Easy", "xp": 80},
            {"title": "Study compound interest and investment strategies", "tag": "Research", "difficulty": "Medium", "xp": 130}
        ];
    } else {
        templates = [
            {"title": "Research the top 10 skills needed for " + goal_title, "tag": "Research", "difficulty": "Easy", "xp": 70},
            {"title": "Find and follow 5 experts in this field", "tag": "Research", "difficulty": "Easy", "xp": 60},
            {"title": "Complete one online course related to " + goal_title, "tag": "Learning", "difficulty": "Medium", "xp": 150},
            {"title": "Build a small project to practice core skills", "tag": "Project", "difficulty": "Hard", "xp": 250},
            {"title": "Join a community or forum for " + goal_title, "tag": "Networking", "difficulty": "Easy", "xp": 70},
            {"title": "Create a weekly learning schedule and stick to it", "tag": "Planning", "difficulty": "Medium", "xp": 100}
        ];
    }
    return templates;
}

# ==== GOALS ====

def:pub get_goals() -> list[Goal] {
    return [root -->][?:Goal];
}

def:pub add_goal(title: str, description: str, timeline: str) -> Goal {
    g = (root ++> Goal(title=title, description=description, timeline=timeline, status="active", progress=0, created_at="now"))[0] as Goal;
    log_agent("Planner", "New goal created", title);
    log_agent("Memory", "Goal indexed in memory", title);
    return g;
}

def:pub update_goal_progress(goal_id: str, progress: int) -> Goal | None {
    for g in [root -->][?:Goal] {
        if jid(g) == goal_id {
            g.progress = progress;
            log_agent("Analytics", "Progress updated to " + str(progress) + "%", g.title);
            if progress >= 100 {
                log_agent("Coach", "Goal completed! Celebrating achievement", g.title);
            } elif progress >= 75 {
                log_agent("Coach", "75%+ reached — final push mode activated", g.title);
            }
            return g;
        }
    }
    return None;
}

def:pub delete_goal(goal_id: str) -> bool {
    for g in [root -->][?:Goal] {
        if jid(g) == goal_id {
            log_agent("Planner", "Goal removed from roadmap", g.title);
            del g;
            return True;
        }
    }
    return False;
}

# ==== MISSIONS ====

def:pub get_missions() -> list[Mission] {
    return [root -->][?:Mission];
}

def:pub add_mission(title: str, difficulty: str, xp: int, tag: str, goal_id: str) -> Mission {
    m = (root ++> Mission(title=title, difficulty=difficulty, xp=xp, tag=tag, goal_id=goal_id, done=False))[0] as Mission;
    log_agent("Execution", "Mission added to queue", title);
    return m;
}

def:pub toggle_mission(mission_id: str) -> Mission | None {
    for m in [root -->][?:Mission] {
        if jid(m) == mission_id {
            m.done = not m.done;
            if m.done {
                log_agent("Execution", "Mission completed! +" + str(m.xp) + " XP earned", m.title);
                log_agent("Memory", "Session logged — completed: " + m.tag + " task", m.title);
                log_agent("Analytics", "Consistency streak updated", "+" + str(m.xp) + " XP");
                auto_summary: str = "Completed: " + m.title;
                (root ++> MemoryEntry(summary=auto_summary, tags=m.tag, focus_score=85, duration="1h", created_at="now"));
            } else {
                log_agent("Execution", "Mission marked incomplete", m.title);
            }
            return m;
        }
    }
    return None;
}

def:pub delete_mission(mission_id: str) -> bool {
    for m in [root -->][?:Mission] {
        if jid(m) == mission_id {
            log_agent("Planner", "Mission removed from plan", m.title);
            del m;
            return True;
        }
    }
    return False;
}

# ==== MEMORY ====

def:pub get_memories() -> list[MemoryEntry] {
    return [root -->][?:MemoryEntry];
}

def:pub add_memory(summary: str, tags: str, focus_score: int, duration: str) -> MemoryEntry {
    e = (root ++> MemoryEntry(summary=summary, tags=tags, focus_score=focus_score, duration=duration, created_at="now"))[0] as MemoryEntry;
    log_agent("Memory", "Session manually logged", summary[:50]);
    log_agent("Analytics", "Focus score recorded: " + str(focus_score) + "%", tags);
    return e;
}

# ==== AGENT LOGS ====

def:pub get_agent_logs() -> list[AgentLog] {
    all_logs = [root -->][?:AgentLog];
    if len(all_logs) > 20 {
        return all_logs[len(all_logs)-20:];
    }
    return all_logs;
}

def:pub get_agent_status() -> dict {
    goals = [root -->][?:Goal];
    missions = [root -->][?:Mission];
    done_missions = [root -->][?:Mission][?done == True];
    memories = [root -->][?:MemoryEntry];
    logs = [root -->][?:AgentLog];
    return {
        "planner": {
            "status": "active" if len(goals) > 0 else "idle",
            "task": "Managing " + str(len(goals)) + " active goals" if len(goals) > 0 else "Waiting for first goal",
            "tasks_done": len(goals)
        },
        "execution": {
            "status": "active" if len(missions) > len(done_missions) else "idle",
            "task": str(len(missions) - len(done_missions)) + " missions in queue" if len(missions) > len(done_missions) else "All missions complete",
            "tasks_done": len(done_missions)
        },
        "memory": {
            "status": "active" if len(memories) > 0 else "idle",
            "task": "Indexed " + str(len(memories)) + " sessions" if len(memories) > 0 else "No sessions logged yet",
            "tasks_done": len(memories)
        },
        "analytics": {
            "status": "active" if len(done_missions) > 0 else "idle",
            "task": "Tracking " + str(len(done_missions)) + " completed missions",
            "tasks_done": len(logs)
        },
        "coach": {
            "status": "active",
            "task": "Monitoring consistency and motivation",
            "tasks_done": len(done_missions)
        },
        "research": {
            "status": "idle",
            "task": "Ready to scan opportunities",
            "tasks_done": 0
        }
    };
}

# ==== STATS ====

def:pub get_stats() -> dict {
    goals = [root -->][?:Goal];
    missions = [root -->][?:Mission];
    done_missions = [root -->][?:Mission][?done == True];
    total_xp = 0;
    for m in done_missions {
        total_xp = total_xp + m.xp;
    }
    avg_progress = 0;
    if len(goals) > 0 {
        total_prog = 0;
        for g in goals {
            total_prog = total_prog + g.progress;
        }
        avg_progress = total_prog // len(goals);
    }
    return {
        "total_goals": len(goals),
        "total_missions": len(missions),
        "done_missions": len(done_missions),
        "total_xp": total_xp,
        "avg_progress": avg_progress
    };
}

# ==== AI AGENT ENDPOINTS (with LLM fallback) ====

async def:pub agent_generate_missions(goal_id: str, goal_title: str, goal_description: str, timeline: str) -> list[Mission] {
    created: list[Mission] = [];
    log_agent("Planner", "Generating missions for goal", goal_title);
    try {
        plan = await ai_plan_missions(goal_title, goal_description, timeline);
        missions_list = plan.missions;
        tags_list = plan.tags;
        diffs_list = plan.difficulties;
        xp_list = plan.xp_values;
        for i in range(len(missions_list)) {
            tag_val: str = "General";
            diff_val: str = "Medium";
            xp_val: int = 100;
            if i < len(tags_list) {
                tag_val = str(tags_list[i]);
            }
            if i < len(diffs_list) {
                diff_val = str(diffs_list[i]);
            }
            if i < len(xp_list) {
                xp_val = int(xp_list[i]);
            }
            m = (root ++> Mission(title=str(missions_list[i]), difficulty=diff_val, xp=xp_val, tag=tag_val, goal_id=goal_id, done=False))[0];
            created = created + [m];
        }
        log_agent("Planner", "AI generated " + str(len(created)) + " missions", goal_title);
    } except Exception as ex {
        templates = get_mission_templates(goal_title, timeline);
        for t in templates {
            m = (root ++> Mission(title=str(t["title"]), difficulty=str(t["difficulty"]), xp=int(t["xp"]), tag=str(t["tag"]), goal_id=goal_id, done=False))[0];
            created = created + [m];
        }
        log_agent("Planner", "Smart templates used — " + str(len(created)) + " missions created", goal_title);
    }
    log_agent("Execution", "Mission queue loaded with " + str(len(created)) + " tasks", goal_title);
    return created;
}

async def:pub agent_get_insights(goal_id: str) -> InsightReport {
    goals = [root -->][?:Goal];
    missions = [root -->][?:Mission];
    done_missions = [root -->][?:Mission][?done == True];
    goal_title: str = "your goal";
    timeline: str = "3 months";
    progress: int = 0;
    for g in goals {
        if jid(g) == goal_id {
            goal_title = g.title;
            timeline = g.timeline;
            progress = g.progress;
        }
    }
    log_agent("Analytics", "Generating insights for", goal_title);
    try {
        insight_result: InsightReport = await ai_generate_insights(goal_title, timeline, progress, len(done_missions), len(missions), 7);
        log_agent("Coach", "AI insights delivered", goal_title);
        return insight_result;
    } except Exception as ex {
        done_count: int = len(done_missions);
        total_count: int = len(missions);
        pct: int = 0;
        if total_count > 0 {
            pct = (done_count * 100) // total_count;
        }
        risk: str = "Low";
        if pct < 30 {
            risk = "High";
        } elif pct < 60 {
            risk = "Medium";
        }
        fallback_insights: list[str] = [
            "You have completed " + str(done_count) + " of " + str(total_count) + " missions (" + str(pct) + "% completion rate).",
            "Current goal progress is at " + str(progress) + "% — keep pushing forward.",
            "Consistency is key — try to complete at least 1 mission per day.",
            "Focus on high-XP missions first to maximize your learning velocity."
        ];
        log_agent("Coach", "Rule-based insights generated", goal_title);
        return InsightReport(
            insights=fallback_insights,
            coach_message="You're making progress on " + goal_title + ". Stay consistent and trust the process!",
            predicted_completion="On track for " + timeline,
            risk_level=risk
        );
    }
}

async def:pub agent_get_strategy(goal_id: str) -> StrategyReport {
    goal_title: str = "your goal";
    goal_description: str = "";
    timeline: str = "3 months";
    for g in [root -->][?:Goal] {
        if jid(g) == goal_id {
            goal_title = g.title;
            goal_description = g.description;
            timeline = g.timeline;
        }
    }
    log_agent("Planner", "Building strategy for", goal_title);
    try {
        strategy_result: StrategyReport = await ai_build_strategy(goal_title, goal_description, timeline);
        log_agent("Research", "Strategy resources curated", goal_title);
        return strategy_result;
    } except Exception as ex {
        log_agent("Planner", "Smart strategy template applied", goal_title);
        return StrategyReport(
            milestones=["Foundation & Setup", "Core Skills Development", "Project Building", "Portfolio & Applications"],
            weekly_focus="Focus on completing your daily missions consistently. Small daily progress compounds into massive results.",
            key_resources=["YouTube tutorials for " + goal_title, "Coursera/Udemy courses", "GitHub projects to study", "Reddit communities", "Discord servers"],
            agent_insights=["Planner: Break your goal into weekly sprints", "Research: Find 3 mentors in this field", "Coach: Track your daily habits", "Analytics: Review progress every Sunday"]
        );
    }
}

def web_search_ddg(query: str, max_results: int) -> list[str] {
    results: list[str] = [];
    try {
        import from duckduckgo_search { DDGS }
        ddgs: Any = DDGS();
        text_fn: Any = getattr(ddgs, "text");
        search_results: list = list(text_fn(query, max_results=max_results));
        for r in search_results {
            title: str = str(r["title"]) if "title" in r else "";
            href: str = str(r["href"]) if "href" in r else "";
            body: str = str(r["body"]) if "body" in r else "";
            if title {
                entry_line: str = title;
                if href {
                    entry_line = title + " — " + href;
                }
                results = results + [entry_line];
            }
        }
    } except Exception as ex {
        results = [];
    }
    return results;
}

async def:pub agent_get_opportunities(goal_id: str) -> OpportunityReport {
    goal_title: str = "your goal";
    timeline: str = "3 months";
    for g in [root -->][?:Goal] {
        if jid(g) == goal_id {
            goal_title = g.title;
            timeline = g.timeline;
        }
    }
    log_agent("Research", "🔍 Web crawling for opportunities", goal_title);

    internships: list[str] = [];
    courses: list[str] = [];
    projects: list[str] = [];
    networking: list[str] = [];

    try {
        log_agent("Research", "Searching internships/jobs", goal_title);
        internship_query: str = goal_title + " internship jobs 2024 2025 site:linkedin.com OR site:internshala.com OR site:glassdoor.com";
        internships = web_search_ddg(internship_query, 5);
        if len(internships) == 0 {
            internships = web_search_ddg(goal_title + " internship opportunities apply", 5);
        }

        log_agent("Research", "Searching courses", goal_title);
        course_query: str = goal_title + " best online course tutorial 2024 site:coursera.org OR site:udemy.com OR site:youtube.com";
        courses = web_search_ddg(course_query, 5);
        if len(courses) == 0 {
            courses = web_search_ddg(goal_title + " learn online free course", 5);
        }

        log_agent("Research", "Searching project ideas", goal_title);
        project_query: str = goal_title + " project ideas for beginners portfolio github";
        projects = web_search_ddg(project_query, 5);

        log_agent("Research", "Searching communities", goal_title);
        network_query: str = goal_title + " community discord reddit forum professionals";
        networking = web_search_ddg(network_query, 4);

        log_agent("Research", "✅ Web crawl complete — " + str(len(internships) + len(courses) + len(projects)) + " results found", goal_title);
    } except Exception as ex {
        log_agent("Research", "Web search failed, using smart templates", str(ex)[:50]);
    }

    if len(internships) == 0 {
        internships = ["Google Summer of Code — summerofcode.withgoogle.com", "Microsoft Internship — careers.microsoft.com", "Amazon SDE Intern — amazon.jobs", "Internshala: " + goal_title + " internships — internshala.com", "LinkedIn: " + goal_title + " jobs — linkedin.com/jobs"];
    }
    if len(courses) == 0 {
        courses = ["Coursera: " + goal_title + " Specialization — coursera.org", "Udemy: Complete " + goal_title + " Bootcamp — udemy.com", "edX: Professional Certificate — edx.org", "fast.ai Practical Course — fast.ai", "FreeCodeCamp Full Course — youtube.com/freecodecamp"];
    }
    if len(projects) == 0 {
        projects = ["Build a portfolio project from scratch", "Contribute to open source on GitHub — github.com", "Create a personal website showcasing skills", "Build a clone of a popular app", "Solve real-world problems with code"];
    }
    if len(networking) == 0 {
        networking = ["Join relevant Discord servers", "Follow experts on Twitter/X", "Attend local meetups — meetup.com", "LinkedIn connections in the field"];
    }

    return OpportunityReport(
        internships=internships,
        courses=courses,
        projects=projects,
        networking=networking
    );
}
