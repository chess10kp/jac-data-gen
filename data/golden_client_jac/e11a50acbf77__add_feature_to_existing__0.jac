# Good - name is self-explanatory
def extract_emails(text: str) -> list[str] by llm();
sem extract_emails = "Extract all email addresses from the text. Return empty list if none found.";

# New feature - extract phone numbers too
def extract_phone_numbers(text: str) -> list[str] by llm();
sem extract_phone_numbers = "Extract all phone numbers from the text in E.164 format. Return empty list if none found.";
