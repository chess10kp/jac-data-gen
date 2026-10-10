# Ghost Board — Jac Migration (Hackathon Edition)

This directory contains the Jac implementation of the Ghost Board's core intelligence and orchestration logic. This migration moves the "Brain" of the application from a multi-cloud n8n workflow into a single, AI-native graph structure.

## Core Paradigms Used

1.  **Object-Spatial Programming (OSP):** The AI Executives and Crises are modeled as a **Knowledge Graph**. Relationships (edges) define how information flows between them.
2.  **Meaning-Typed Programming (MTP):** We use `by llm()` to define AI capabilities directly in the language. No more manual prompt engineering or JSON parsing; Jac handles the intent and response structure automatically.
3.  **Walkers:** The `OrchestrateCrisis` walker automates the "thought process" by traversing the graph, gathering executive input, and synthesizing a final report.

## File Structure

- `ghost_board.jac`: The main entry point, defining the graph structure and core orchestrator.
- `executive_logic.jac`: Role-specific reasoning capabilities and background synchronization logic.
- `models.jac` (Planned): Shared data structures for the graph.

## How to Run

1.  **Install Jaclang:**
    ```bash
    pip install jaclang
    ```

2.  **Set your LLM Key (if using OpenAI/Anthropic):**
    ```bash
    export OPENAI_API_KEY=your_key_here
    ```

3.  **Run the Orchestrator:**
    ```bash
    jac run src/jac/ghost_board.jac
    ```

## Next Steps for the Hackathon

- **API Integration:** Use `to sv:` blocks to expose these walkers as a FastAPI backend, replacing `src/app/api/crisis/orchestrate/route.ts`.
- **Frontend Sync:** Use Jac-client (`to cl:`) to bind these graph nodes directly to your React components, removing the need for polling hooks.
