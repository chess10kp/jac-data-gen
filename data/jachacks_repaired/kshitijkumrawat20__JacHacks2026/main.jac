"""
FutureOS — Adaptive AI Life Operating System
"""

import from services.appService {
    Goal, Mission, MemoryEntry, AIInsightEntry, AgentLog,
    MissionPlan, InsightReport, StrategyReport, OpportunityReport,
    get_goals, add_goal, update_goal_progress, delete_goal,
    get_missions, add_mission, toggle_mission, delete_mission,
    get_memories, add_memory,
    get_agent_logs, get_agent_status,
    get_stats,
    agent_generate_missions,
    agent_get_insights,
    agent_get_strategy,
    agent_get_opportunities
}

import ".styles.global.css";

import from .index { ClientApp }

def:pub app() -> JsxElement {
    return <ClientApp />;
}
