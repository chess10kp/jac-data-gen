glob history: list = [];

def respond(msg: str) -> str by llm(
    system_prompt="You are a coding assistant. Answer in Jac.",
    conversation=history
);

def reset_conversation() -> None {
    history.clear();
}
