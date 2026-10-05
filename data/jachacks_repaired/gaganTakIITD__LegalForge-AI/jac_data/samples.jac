"""Jac-native demo contracts for login/sample endpoints."""

glob SAMPLE_NDA = """
MUTUAL NON-DISCLOSURE AGREEMENT

This Mutual Non-Disclosure Agreement ("Agreement") is entered into as of January 15, 2026.

1. DEFINITIONS
1.1 "Confidential Information" means all non-public business and technical information.
1.2 "Representatives" means employees, advisors, and contractors with need-to-know access.

2. OBLIGATIONS
2.1 Recipient shall keep Confidential Information strictly confidential.
2.2 Recipient shall use Confidential Information only to evaluate a potential business relationship.
2.3 Recipient shall apply reasonable safeguards to protect Confidential Information.

3. EXCLUSIONS
3.1 Confidential Information excludes information that is public, previously known, or independently developed.

4. TERM
4.1 This Agreement remains in effect for three (3) years.
4.2 Confidentiality obligations survive for five (5) years after termination.

5. REMEDIES
5.1 Discloser may seek injunctive relief for breach.
5.2 Total liability under this Agreement shall not exceed $10,000.

6. INDEMNIFICATION
6.1 Recipient shall indemnify Discloser for all losses arising from breach with no cap.

7. GOVERNING LAW
7.1 Governing law is Delaware.
7.2 Disputes are resolved by arbitration in San Francisco, California.
""";

glob SAMPLE_SAAS = """
SOFTWARE AS A SERVICE AGREEMENT

This SaaS Agreement is effective as of March 1, 2026 between Provider and Client.

1. DEFINITIONS
1.1 "Service" means Provider's cloud software.
1.2 "User Data" means Client data processed by the Service.

2. SERVICE PROVISION
2.1 Provider shall maintain 99.9% uptime.
2.2 Provider may modify features at any time without notice.
2.3 Provider is not liable for downtime.

3. DATA OWNERSHIP AND PRIVACY
3.1 Client retains ownership of User Data.
3.2 Provider may use anonymized User Data for analytics and product improvement.
3.3 Provider shall comply with GDPR and CCPA.
3.4 On termination, Provider deletes User Data within 30 days unless legally required otherwise.

4. FEES
4.1 Subscription fee is $50,000 per month.
4.2 Provider may increase fees by up to 25% annually with 30 days notice.
4.3 Late payments accrue 18% annual interest compounded monthly.
4.4 Fees are non-refundable even if SLA is missed.

5. LIMITATION OF LIABILITY
5.1 Provider's aggregate liability is capped at fees paid in the prior three months.
5.2 Provider is not liable for indirect or consequential damages.
5.3 Liability limits do not apply to indemnification obligations in Section 7.

6. IP
6.1 Provider retains all rights in the Service.
6.2 Client-developed improvements become exclusive property of Provider.

7. INDEMNIFICATION
7.1 Provider indemnifies Client for IP infringement claims.
7.2 Client indemnifies Provider for all claims from Client use, regardless of fault.

8. TERMINATION
8.1 Either party may terminate with 90 days notice.
8.2 Provider may terminate immediately for any Client breach.
8.3 Client may terminate for cause after 60 days cure period.
8.4 On termination, Client owes fees for the remainder of term.

9. GOVERNING LAW
9.1 Governing law is California.
""";

glob SAMPLE_MA = """
LETTER OF INTENT -- ACQUISITION

This LOI is entered into as of February 20, 2026 between Acquirer and Target.

1. TRANSACTION
1.1 Acquirer intends to buy 100% of Target for $50,000,000.
1.2 Consideration is 60% cash and 40% stock.

2. DUE DILIGENCE
2.1 Target provides full access to records for 90 days.
2.2 Target warrants diligence information is materially accurate.

3. REPRESENTATIONS
3.1 Target has no pending litigation.
3.2 Target owns all IP and does not infringe third-party rights.
3.3 Financial statements are accurate except no warranty on projections.

4. NON-COMPETE
4.1 Founders agree to a global non-compete for seven years.

5. EMPLOYEE MATTERS
5.1 Acquirer offers substantially similar employment terms.
5.2 Acquirer may terminate any Target employee in first 12 months without severance.

6. INDEMNIFICATION
6.1 Founders indemnify Acquirer for all losses indefinitely.
6.2 Indemnification cap is total purchase price.

7. EXCLUSIVITY
7.1 Target may not negotiate with alternate buyers for 180 days.

8. GOVERNING LAW
8.1 Governing law is New York.
8.2 Disputes are exclusively in London courts.
""";

glob SAMPLES = {
    "nda": {"title": "Mutual NDA -- Acme Corp & TechStart Inc", "text": SAMPLE_NDA},
    "saas": {"title": "SaaS Agreement -- CloudForge & MegaCorp", "text": SAMPLE_SAAS},
    "ma": {"title": "M&A LOI -- Nexus Global & DataPulse ($50M)", "text": SAMPLE_MA}
};
