"""
Vouch v2: Payload Exfiltration Guard
Detects PII in outbound payloads and redacts before they reach
observability tools or logs.

Scans for: email addresses, phone numbers, SSNs, credit cards,
and custom patterns from user context.
"""

import from ._base { pass_result, confirm_result }
import re;

# PII pattern regexes
glob EMAIL_PATTERN: str = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}';
glob PHONE_PATTERN: str = r'(\+?1?\s?)?(\(?\d{3}\)?[\s.-]?)?\d{3}[\s.-]?\d{4}';
glob SSN_PATTERN: str = r'\b\d{3}-\d{2}-\d{4}\b';
glob CREDIT_CARD_PATTERN: str = r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b';
glob IP_ADDRESS_PATTERN: str = r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b';

obj PiiMatch {
    has pii_type: str;
    has field_path: str;
    has original: str;
    has redacted: str;
}

walker ScanPayload {
    has payload_str: str;
    has context_fields: list[str] = [];

    can scan with entry {
        matches: list[dict] = [];

        # Scan for email addresses
        for m in re.finditer(EMAIL_PATTERN, self.payload_str) {
            matches.append({
                "type": "EMAIL",
                "value": m.group(),
                "redacted": "[EMAIL_REDACTED]"
            });
        }

        # Scan for phone numbers
        for m in re.finditer(PHONE_PATTERN, self.payload_str) {
            if len(m.group().strip()) >= 10 {
                matches.append({
                    "type": "PHONE",
                    "value": m.group(),
                    "redacted": "[PHONE_REDACTED]"
                });
            }
        }

        # Scan for SSNs
        for m in re.finditer(SSN_PATTERN, self.payload_str) {
            matches.append({
                "type": "SSN",
                "value": m.group(),
                "redacted": "[SSN_REDACTED]"
            });
        }

        # Scan for credit cards
        for m in re.finditer(CREDIT_CARD_PATTERN, self.payload_str) {
            matches.append({
                "type": "CREDIT_CARD",
                "value": m.group(),
                "redacted": "[CARD_REDACTED]"
            });
        }

        # Scan for custom context fields (names, addresses, etc.)
        for field in self.context_fields {
            if field.lower() in self.payload_str.lower() and len(field) > 2 {
                matches.append({
                    "type": "CONTEXT_PII",
                    "value": field,
                    "redacted": "[PII_REDACTED]"
                });
            }
        }

        if matches {
            types_found = list(set([m["type"] for m in matches]));
            report confirm_result(
                "exfiltration_guard",
                f"PII detected in payload: {', '.join(types_found)}. {len(matches)} match(es) found."
            );
        } else {
            report pass_result("exfiltration_guard");
        }
    }
}
