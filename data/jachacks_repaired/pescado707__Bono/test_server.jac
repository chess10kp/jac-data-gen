import from server {
    LegalNode, SummaryNode, DocumentChunk, ImmigrationAspect,
    SwitchModel, AnalyzeSituation, FollowUp, Summarize, GetHistory,
    ResetAll, IngestDocument
}

# ---------------------------------------------------------------------------
# Test 1: AnalyzeSituation populates all 8 nodes
# ---------------------------------------------------------------------------

walker TestAnalyzeSituation {
    has test_input: str = "I received a Notice to Appear and my green card application is pending.";
    has passed: bool = False;

    can run with Root entry {
        analyzer = root spawn AnalyzeSituation(user_input=self.test_input);

        results = analyzer.results;
        expected_keys = [
            "case_assessment", "rights_protections", "urgent_steps", "critical_warnings",
            "follow_up_questions", "legal_glossary", "help_contacts", "process_outlook"
        ];

        all_present = True;
        for key in expected_keys {
            if key not in results {
                all_present = False;
            } elif results[key]["value"] == "" {
                all_present = False;
            }
        }

        self.passed = all_present;
        report {
            "test": "TestAnalyzeSituation",
            "passed": self.passed,
            "result_keys": list(results.keys())
        };
    }
}

# ---------------------------------------------------------------------------
# Test 2: SwitchModel updates the correct node's model
# ---------------------------------------------------------------------------

walker TestSwitchModel {
    has passed: bool = False;

    can run with Root entry {
        root spawn SwitchModel(
            target_label="case_assessment",
            new_model="claude-sonnet-4-6"
        );

        for n in [root -->] {
            if isinstance(n, LegalNode) and n.label == "case_assessment" {
                self.passed = (n.model == "claude-sonnet-4-6");
            }
        }

        report {
            "test": "TestSwitchModel",
            "passed": self.passed
        };
    }
}

# ---------------------------------------------------------------------------
# Test 3: SwitchModel rejects invalid models
# ---------------------------------------------------------------------------

walker TestSwitchModelInvalid {
    has passed: bool = False;

    can run with Root entry {
        root spawn SwitchModel(
            target_label="rights_protections",
            new_model="fake-model-xyz"
        );

        for n in [root -->] {
            if isinstance(n, LegalNode) and n.label == "rights_protections" {
                self.passed = (n.model != "fake-model-xyz");
            }
        }

        report {
            "test": "TestSwitchModelInvalid",
            "passed": self.passed
        };
    }
}

# ---------------------------------------------------------------------------
# Test 4: ResetAll clears all nodes
# ---------------------------------------------------------------------------

walker TestResetAll {
    has passed: bool = False;

    can run with Root entry {
        # First populate nodes
        root spawn AnalyzeSituation(user_input="Test input for reset.");

        # Then reset
        root spawn ResetAll();

        # Check all nodes are cleared
        all_reset = True;
        for n in [root -->] {
            if isinstance(n, LegalNode) {
                if n.value != "" or n.loop_count != 0 or n.is_ready != False {
                    all_reset = False;
                }
            }
        }

        self.passed = all_reset;
        report {
            "test": "TestResetAll",
            "passed": self.passed
        };
    }
}

# ---------------------------------------------------------------------------
# Test 5: FollowUp accumulates context and updates nodes
# ---------------------------------------------------------------------------

walker TestFollowUp {
    has passed: bool = False;

    can run with Root entry {
        # First analyze
        root spawn AnalyzeSituation(user_input="My H-1B visa expires next month.");

        # Then follow up
        followup = root spawn FollowUp(
            original_input="My H-1B visa expires next month.",
            follow_up_answer="My employer has already filed an I-129 extension petition."
        );

        results = followup.results;
        self.passed = len(results) > 0;

        report {
            "test": "TestFollowUp",
            "passed": self.passed,
            "result_keys": list(results.keys())
        };
    }
}

# ---------------------------------------------------------------------------
# Test 6: FollowUp hits max_loops and triggers Summarize
# ---------------------------------------------------------------------------

walker TestMaxLoops {
    has passed: bool = False;

    can run with Root entry {
        root spawn AnalyzeSituation(user_input="I am applying for a green card through my spouse.");

        i = 0;
        followup = FollowUp(
            original_input="I am applying for a green card through my spouse.",
            follow_up_answer="Answer number 1"
        );
        while i < 3 {
            followup = root spawn FollowUp(
                original_input="I am applying for a green card through my spouse.",
                follow_up_answer="Answer number " + str(i + 1)
            );
            i += 1;
        }

        self.passed = followup.limit_reached;
        report {
            "test": "TestMaxLoops",
            "passed": self.passed,
            "limit_reached": followup.limit_reached
        };
    }
}

# ---------------------------------------------------------------------------
# Test 7: IngestDocument creates DocumentChunk nodes
# ---------------------------------------------------------------------------

walker TestIngestDocument {
    has passed: bool = False;

    can run with Root entry {
        root spawn IngestDocument(
            content="Green card applicants must file Form I-485 to adjust status. Asylum seekers must file Form I-589 within one year of arrival in the United States.",
            source="USCIS Policy Manual",
            topic="green_card_asylum"
        );

        chunk_count = 0;
        for n in [root -->] {
            if isinstance(n, DocumentChunk) {
                chunk_count += 1;
            }
        }

        self.passed = (chunk_count > 0);
        report {
            "test": "TestIngestDocument",
            "passed": self.passed,
            "chunk_count": chunk_count
        };
    }
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

with entry {
    # Bootstrap the graph for testing
    root ++> LegalNode(label="case_assessment", aspect=ImmigrationAspect.CASE_ASSESSMENT);
    root ++> LegalNode(label="rights_protections", aspect=ImmigrationAspect.RIGHTS_PROTECTIONS);
    root ++> LegalNode(label="urgent_steps", aspect=ImmigrationAspect.URGENT_STEPS);
    root ++> LegalNode(label="critical_warnings", aspect=ImmigrationAspect.CRITICAL_WARNINGS);
    root ++> LegalNode(label="follow_up_questions", aspect=ImmigrationAspect.FOLLOW_UP_QUESTIONS);
    root ++> LegalNode(label="legal_glossary", aspect=ImmigrationAspect.LEGAL_GLOSSARY);
    root ++> LegalNode(label="help_contacts", aspect=ImmigrationAspect.HELP_CONTACTS);
    root ++> LegalNode(label="process_outlook", aspect=ImmigrationAspect.PROCESS_OUTLOOK);
    root ++> SummaryNode();

    print("Running test suite...\n");

    r1 = root spawn TestAnalyzeSituation();
    print("TestAnalyzeSituation: ", r1);

    r2 = root spawn TestSwitchModel();
    print("TestSwitchModel: ", r2);

    r3 = root spawn TestSwitchModelInvalid();
    print("TestSwitchModelInvalid: ", r3);

    r4 = root spawn TestResetAll();
    print("TestResetAll: ", r4);

    r5 = root spawn TestFollowUp();
    print("TestFollowUp: ", r5);

    r6 = root spawn TestMaxLoops();
    print("TestMaxLoops: ", r6);

    r7 = root spawn TestIngestDocument();
    print("TestIngestDocument: ", r7);

    print("\nAll tests complete.");
}
