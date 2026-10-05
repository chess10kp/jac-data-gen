"""Drug interaction dataset for ChainRx."""

glob DRUG_INTERACTIONS: list[dict] = [
    {
        "drug_a": "Ibuprofen",
        "drug_b": "Lisinopril",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal prostaglandin synthesis, blunting ACE inhibitor renal protection",
        "severity": 0.55
    },
    {
        "drug_a": "Ibuprofen",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "NSAIDs impair renal clearance of metformin, increasing lactic acidosis risk",
        "severity": 0.5
    },
    {
        "drug_a": "Lisinopril",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "Both drugs depend on renal clearance; combined use in renal impairment raises toxicity",
        "severity": 0.35
    },
    {
        "drug_a": "Ibuprofen",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce diuretic efficacy and worsen renal perfusion when combined with loop diuretics",
        "severity": 0.5
    },
    {
        "drug_a": "Lisinopril",
        "drug_b": "Furosemide",
        "type": "additive_hypotension",
        "mechanism": "ACE inhibitor plus diuretic causes excessive blood pressure drop and renal hypoperfusion",
        "severity": 0.4
    },
    {
        "drug_a": "Naproxen",
        "drug_b": "Lisinopril",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal prostaglandin synthesis, blunting ACE inhibitor renal protection",
        "severity": 0.55
    },
    {
        "drug_a": "Naproxen",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce diuretic efficacy and worsen renal perfusion when combined with loop diuretics",
        "severity": 0.5
    },
    {
        "drug_a": "Naproxen",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "NSAIDs impair renal clearance of metformin, increasing lactic acidosis risk",
        "severity": 0.5
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs blunt ARB renal protective effects and reduce GFR",
        "severity": 0.55
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Furosemide",
        "type": "additive_hypotension",
        "mechanism": "ARB plus loop diuretic causes excessive hypotension and renal hypoperfusion",
        "severity": 0.4
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ARB reduces aldosterone while spironolactone blocks its receptor — additive K+ retention",
        "severity": 0.6
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "Both drugs depend on renal clearance; combined use in renal impairment raises toxicity",
        "severity": 0.35
    },
    {
        "drug_a": "Hydrochlorothiazide",
        "drug_b": "Lisinopril",
        "type": "additive_hypotension",
        "mechanism": "Thiazide plus ACE inhibitor causes first-dose hypotension and electrolyte imbalance",
        "severity": 0.4
    },
    {
        "drug_a": "Hydrochlorothiazide",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce thiazide diuretic efficacy and impair renal function",
        "severity": 0.45
    },
    {
        "drug_a": "Hydrochlorothiazide",
        "drug_b": "Lithium",
        "type": "reduced_clearance",
        "mechanism": "Thiazides reduce lithium renal clearance causing toxic accumulation",
        "severity": 0.7
    },

    # === SEROTONIN SYNDROME CHAINS ===
    {
        "drug_a": "Sertraline",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus opioid with serotonergic activity causes additive serotonin accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Sertraline",
        "drug_b": "Ondansetron",
        "type": "serotonin_increase",
        "mechanism": "SSRI combined with 5-HT3 antagonist may increase serotonergic tone via receptor modulation",
        "severity": 0.3
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "Ondansetron",
        "type": "serotonin_increase",
        "mechanism": "Both agents affect serotonin pathways; combined use elevates serotonin syndrome risk",
        "severity": 0.35
    },
    {
        "drug_a": "Fluoxetine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus MAOI causes dangerous serotonin accumulation — contraindicated combination",
        "severity": 0.95
    },
    {
        "drug_a": "Fluoxetine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Fluoxetine inhibits CYP2D6 and increases serotonin; tramadol adds serotonergic load",
        "severity": 0.65
    },
    {
        "drug_a": "Sertraline",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SSRI raises syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Tramadol serotonin reuptake inhibition combined with MAO inhibition — potentially fatal",
        "severity": 0.9
    },
    {
        "drug_a": "Escitalopram",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus serotonergic opioid causes additive serotonin accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Escitalopram",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus MAOI causes dangerous serotonin accumulation — contraindicated",
        "severity": 0.95
    },
    {
        "drug_a": "Escitalopram",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SSRI raises syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Venlafaxine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus serotonergic opioid causes additive serotonin and norepinephrine accumulation",
        "severity": 0.65
    },
    {
        "drug_a": "Venlafaxine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus MAOI causes severe serotonin syndrome — contraindicated combination",
        "severity": 0.95
    },
    {
        "drug_a": "Venlafaxine",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SNRI raises syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Duloxetine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus serotonergic opioid causes additive serotonin accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Duloxetine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus MAOI — contraindicated due to severe serotonin syndrome risk",
        "severity": 0.95
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Trazodone serotonin reuptake inhibition adds to SSRI serotonergic effect",
        "severity": 0.5
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Fluoxetine",
        "type": "serotonin_increase",
        "mechanism": "Fluoxetine inhibits CYP2D6, raising trazodone levels; both increase serotonin",
        "severity": 0.55
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Both agents inhibit serotonin reuptake; combined use elevates syndrome risk",
        "severity": 0.55
    },
    {
        "drug_a": "Linezolid",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Linezolid is a reversible MAOI; combined with SSRI causes serotonin syndrome",
        "severity": 0.85
    },
    {
        "drug_a": "Linezolid",
        "drug_b": "Fluoxetine",
        "type": "serotonin_increase",
        "mechanism": "Linezolid MAOI activity plus SSRI serotonin reuptake inhibition — high syndrome risk",
        "severity": 0.85
    },
    {
        "drug_a": "Linezolid",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Linezolid MAOI activity combined with tramadol serotonergic effects",
        "severity": 0.8
    },
    {
        "drug_a": "Dextromethorphan",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "DXM sigma-1 agonism and serotonin reuptake inhibition adds to SSRI serotonergic load",
        "severity": 0.5
    },
    {
        "drug_a": "Dextromethorphan",
        "drug_b": "Fluoxetine",
        "type": "serotonin_increase",
        "mechanism": "Fluoxetine inhibits CYP2D6 metabolism of DXM, raising levels; both increase serotonin",
        "severity": 0.6
    },
    {
        "drug_a": "Dextromethorphan",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "DXM plus MAOI causes severe serotonin syndrome — contraindicated",
        "severity": 0.9
    },

    # === ADDITIONAL PSYCH INTERACTIONS ===
    {
        "drug_a": "Fluoxetine",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SSRI raises serotonin syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Fluoxetine",
        "drug_b": "Alprazolam",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP3A4 metabolism of alprazolam, raising levels and sedation",
        "severity": 0.5
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Trazodone plus benzodiazepine causes additive sedation and respiratory depression",
        "severity": 0.5
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Both agents increase serotonergic tone; combined use raises serotonin syndrome risk",
        "severity": 0.4
    },
    {
        "drug_a": "Alprazolam",
        "drug_b": "Lithium",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus lithium causes additive CNS depression and neurotoxicity risk",
        "severity": 0.35
    },

    # === BLEEDING RISK CHAINS ===
    {
        "drug_a": "Warfarin",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Anticoagulant plus antiplatelet synergistically impairs hemostasis",
        "severity": 0.7
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAIDs inhibit platelet function and may displace warfarin from protein binding",
        "severity": 0.65
    },
    {
        "drug_a": "Aspirin",
        "drug_b": "Clopidogrel",
        "type": "bleeding_risk",
        "mechanism": "Dual antiplatelet therapy significantly increases bleeding risk",
        "severity": 0.55
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Fluoxetine",
        "type": "bleeding_risk",
        "mechanism": "SSRIs impair platelet aggregation and fluoxetine inhibits CYP2C9 warfarin metabolism",
        "severity": 0.6
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Sertraline",
        "type": "bleeding_risk",
        "mechanism": "SSRIs reduce platelet serotonin uptake impairing aggregation; additive with anticoagulant",
        "severity": 0.5
    },
    {
        "drug_a": "Clopidogrel",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAID plus antiplatelet increases GI bleeding risk through dual hemostasis impairment",
        "severity": 0.5
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Naproxen",
        "type": "bleeding_risk",
        "mechanism": "NSAIDs inhibit platelet function and may displace warfarin from protein binding",
        "severity": 0.65
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "Omeprazole inhibits CYP2C19, potentially increasing warfarin levels and INR",
        "severity": 0.35
    },
    {
        "drug_a": "Clopidogrel",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "Omeprazole inhibits CYP2C19 activation of clopidogrel, reducing antiplatelet effect",
        "severity": 0.55
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Amoxicillin",
        "type": "bleeding_risk",
        "mechanism": "Amoxicillin disrupts gut flora reducing vitamin K production, potentiating warfarin",
        "severity": 0.45
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Ciprofloxacin",
        "type": "bleeding_risk",
        "mechanism": "Ciprofloxacin inhibits CYP1A2 warfarin metabolism and disrupts vitamin K gut flora",
        "severity": 0.6
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Metronidazole",
        "type": "bleeding_risk",
        "mechanism": "Metronidazole inhibits CYP2C9 metabolism of warfarin, significantly raising INR",
        "severity": 0.7
    },
    {
        "drug_a": "Apixaban",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Direct oral anticoagulant plus antiplatelet increases major bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Apixaban",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAID impairs platelet function adding to DOAC anticoagulation effect",
        "severity": 0.55
    },
    {
        "drug_a": "Apixaban",
        "drug_b": "Clopidogrel",
        "type": "bleeding_risk",
        "mechanism": "Triple antithrombotic risk — DOAC plus antiplatelet significantly raises bleeding",
        "severity": 0.6
    },
    {
        "drug_a": "Rivaroxaban",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Direct oral anticoagulant plus antiplatelet increases major bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Rivaroxaban",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAID impairs platelet function adding to DOAC anticoagulation effect",
        "severity": 0.55
    },
    {
        "drug_a": "Rivaroxaban",
        "drug_b": "Clopidogrel",
        "type": "bleeding_risk",
        "mechanism": "DOAC plus antiplatelet significantly raises major bleeding risk",
        "severity": 0.6
    },

    # === QT PROLONGATION CHAINS ===
    {
        "drug_a": "Amiodarone",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; combined use increases torsades de pointes risk",
        "severity": 0.7
    },
    {
        "drug_a": "Amiodarone",
        "drug_b": "Fluoxetine",
        "type": "qt_prolongation",
        "mechanism": "Additive QT prolongation from two QT-prolonging agents",
        "severity": 0.6
    },
    {
        "drug_a": "Ondansetron",
        "drug_b": "Fluoxetine",
        "type": "qt_prolongation",
        "mechanism": "Both agents independently prolong QT; combined effect is additive",
        "severity": 0.45
    },
    {
        "drug_a": "Amiodarone",
        "drug_b": "Ciprofloxacin",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; fluoroquinolone adds to amiodarone QT effect",
        "severity": 0.65
    },
    {
        "drug_a": "Ciprofloxacin",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Fluoroquinolone plus 5-HT3 antagonist causes additive QT prolongation",
        "severity": 0.5
    },
    {
        "drug_a": "Amiodarone",
        "drug_b": "Escitalopram",
        "type": "qt_prolongation",
        "mechanism": "Escitalopram prolongs QT; additive risk with amiodarone",
        "severity": 0.6
    },
    {
        "drug_a": "Escitalopram",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both agents prolong QT interval; combined use raises torsades risk",
        "severity": 0.45
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Methadone prolongs QT; additive effect with ondansetron QT prolongation",
        "severity": 0.6
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT; combination is high risk for torsades de pointes",
        "severity": 0.8
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Fluoxetine",
        "type": "qt_prolongation",
        "mechanism": "Fluoxetine inhibits CYP2D6 raising methadone levels; both prolong QT",
        "severity": 0.6
    },
    {
        "drug_a": "Azithromycin",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Macrolide plus amiodarone causes additive QT prolongation",
        "severity": 0.6
    },
    {
        "drug_a": "Azithromycin",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Macrolide plus ondansetron causes additive QT prolongation risk",
        "severity": 0.45
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT; high risk for torsades de pointes",
        "severity": 0.75
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Additive QT prolongation from antipsychotic and antiemetic",
        "severity": 0.5
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Ciprofloxacin",
        "type": "qt_prolongation",
        "mechanism": "Antipsychotic plus fluoroquinolone causes additive QT prolongation",
        "severity": 0.5
    },

    # === HYPERKALEMIA RISK ===
    {
        "drug_a": "Lisinopril",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ACE inhibitor reduces aldosterone while spironolactone blocks its receptor — additive K+ retention",
        "severity": 0.6
    },
    {
        "drug_a": "Spironolactone",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal blood flow compounding potassium-sparing diuretic retention risk",
        "severity": 0.5
    },
    {
        "drug_a": "Lisinopril",
        "drug_b": "Trimethoprim",
        "type": "hyperkalemia_risk",
        "mechanism": "Trimethoprim blocks ENaC channels like amiloride; combined with ACEi causes dangerous hyperkalemia",
        "severity": 0.6
    },
    {
        "drug_a": "Spironolactone",
        "drug_b": "Trimethoprim",
        "type": "hyperkalemia_risk",
        "mechanism": "Both agents retain potassium through different mechanisms; additive hyperkalemia risk",
        "severity": 0.55
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Trimethoprim",
        "type": "hyperkalemia_risk",
        "mechanism": "Trimethoprim potassium retention adds to ARB aldosterone suppression",
        "severity": 0.55
    },

    # === CNS DEPRESSION ===
    {
        "drug_a": "Tramadol",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression",
        "severity": 0.8
    },
    {
        "drug_a": "Diazepam",
        "drug_b": "Amitriptyline",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus tricyclic antidepressant produces additive sedation and respiratory risk",
        "severity": 0.55
    },
    {
        "drug_a": "Oxycodone",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — FDA black box warning",
        "severity": 0.85
    },
    {
        "drug_a": "Oxycodone",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — FDA black box warning",
        "severity": 0.85
    },
    {
        "drug_a": "Oxycodone",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression risk",
        "severity": 0.6
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression",
        "severity": 0.8
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression and sedation risk",
        "severity": 0.55
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — high fatality risk",
        "severity": 0.9
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — high fatality risk",
        "severity": 0.9
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression risk",
        "severity": 0.6
    },
    {
        "drug_a": "Alprazolam",
        "drug_b": "Amitriptyline",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus TCA produces additive sedation and anticholinergic effects",
        "severity": 0.55
    },
    {
        "drug_a": "Gabapentin",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus benzodiazepine produces additive CNS and respiratory depression",
        "severity": 0.5
    },
    {
        "drug_a": "Gabapentin",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus benzodiazepine produces additive CNS and respiratory depression",
        "severity": 0.5
    },
    {
        "drug_a": "Pregabalin",
        "drug_b": "Oxycodone",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus opioid causes additive respiratory depression",
        "severity": 0.6
    },
    {
        "drug_a": "Pregabalin",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus benzodiazepine causes additive CNS depression",
        "severity": 0.5
    },

    # === HEPATOTOXICITY / REDUCED CLEARANCE ===
    {
        "drug_a": "Methotrexate",
        "drug_b": "Ibuprofen",
        "type": "reduced_clearance",
        "mechanism": "NSAIDs reduce renal clearance of methotrexate leading to toxic accumulation",
        "severity": 0.75
    },
    {
        "drug_a": "Methotrexate",
        "drug_b": "Naproxen",
        "type": "reduced_clearance",
        "mechanism": "NSAIDs reduce renal clearance of methotrexate leading to toxic accumulation",
        "severity": 0.75
    },
    {
        "drug_a": "Methotrexate",
        "drug_b": "Trimethoprim",
        "type": "reduced_clearance",
        "mechanism": "Trimethoprim inhibits renal tubular secretion of methotrexate causing toxic buildup",
        "severity": 0.7
    },
    {
        "drug_a": "Acetaminophen",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Chronic acetaminophen use increases INR by inhibiting vitamin K-dependent clotting factor synthesis",
        "severity": 0.4
    },
    {
        "drug_a": "Acetaminophen",
        "drug_b": "Isoniazid",
        "type": "hepatotoxicity",
        "mechanism": "Isoniazid induces CYP2E1 increasing hepatotoxic NAPQI metabolite from acetaminophen",
        "severity": 0.65
    },
    {
        "drug_a": "Simvastatin",
        "drug_b": "Amiodarone",
        "type": "reduced_clearance",
        "mechanism": "Amiodarone inhibits CYP3A4 raising simvastatin levels; high rhabdomyolysis risk",
        "severity": 0.7
    },
    {
        "drug_a": "Simvastatin",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin strongly inhibits CYP3A4, dramatically increasing statin levels and myopathy risk",
        "severity": 0.75
    },
    {
        "drug_a": "Atorvastatin",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising atorvastatin levels; increased myopathy risk",
        "severity": 0.6
    },

    # === DIGOXIN TOXICITY ===
    {
        "drug_a": "Digoxin",
        "drug_b": "Amiodarone",
        "type": "reduced_clearance",
        "mechanism": "Amiodarone inhibits P-glycoprotein and renal clearance of digoxin, doubling levels",
        "severity": 0.75
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits P-glycoprotein and eliminates gut flora that inactivate digoxin",
        "severity": 0.7
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Furosemide",
        "type": "additive_kidney_stress",
        "mechanism": "Furosemide-induced hypokalemia potentiates digoxin toxicity on cardiac conduction",
        "severity": 0.6
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Hydrochlorothiazide",
        "type": "additive_kidney_stress",
        "mechanism": "Thiazide-induced hypokalemia and hypomagnesemia potentiate digoxin cardiac toxicity",
        "severity": 0.55
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Verapamil",
        "type": "reduced_clearance",
        "mechanism": "Verapamil inhibits P-glycoprotein reducing digoxin clearance; additive bradycardia",
        "severity": 0.7
    },

    # === DIABETES / HYPOGLYCEMIA ===
    {
        "drug_a": "Metformin",
        "drug_b": "Glipizide",
        "type": "additive_hypoglycemia",
        "mechanism": "Sulfonylurea stimulates insulin secretion; combined with metformin increases hypoglycemia risk",
        "severity": 0.45
    },
    {
        "drug_a": "Glipizide",
        "drug_b": "Fluoxetine",
        "type": "additive_hypoglycemia",
        "mechanism": "SSRIs can increase insulin sensitivity and enhance sulfonylurea hypoglycemic effect",
        "severity": 0.4
    },
    {
        "drug_a": "Glipizide",
        "drug_b": "Ciprofloxacin",
        "type": "additive_hypoglycemia",
        "mechanism": "Fluoroquinolones can cause dysglycemia; combined with sulfonylurea worsens hypoglycemia",
        "severity": 0.5
    },
    {
        "drug_a": "Insulin",
        "drug_b": "Glipizide",
        "type": "additive_hypoglycemia",
        "mechanism": "Dual insulin-stimulating therapy significantly increases severe hypoglycemia risk",
        "severity": 0.6
    },
    {
        "drug_a": "Insulin",
        "drug_b": "Ciprofloxacin",
        "type": "additive_hypoglycemia",
        "mechanism": "Fluoroquinolones cause dysglycemia; combined with insulin increases hypoglycemia risk",
        "severity": 0.45
    },

    # === ANTICHOLINERGIC BURDEN ===
    {
        "drug_a": "Amitriptyline",
        "drug_b": "Diphenhydramine",
        "type": "anticholinergic_burden",
        "mechanism": "TCA plus antihistamine causes additive anticholinergic effects — confusion, urinary retention, delirium",
        "severity": 0.55
    },
    {
        "drug_a": "Amitriptyline",
        "drug_b": "Oxybutynin",
        "type": "anticholinergic_burden",
        "mechanism": "Dual high-anticholinergic agents cause severe dry mouth, constipation, cognitive impairment",
        "severity": 0.6
    },
    {
        "drug_a": "Diphenhydramine",
        "drug_b": "Oxybutynin",
        "type": "anticholinergic_burden",
        "mechanism": "Both high-anticholinergic agents; combined use raises delirium risk especially in elderly",
        "severity": 0.5
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Amitriptyline",
        "type": "anticholinergic_burden",
        "mechanism": "Antipsychotic plus TCA causes additive anticholinergic toxicity and QT prolongation",
        "severity": 0.55
    },

    # === CALCIUM CHANNEL BLOCKER INTERACTIONS ===
    {
        "drug_a": "Verapamil",
        "drug_b": "Metoprolol",
        "type": "additive_hypotension",
        "mechanism": "Non-dihydropyridine CCB plus beta-blocker causes severe bradycardia and heart block",
        "severity": 0.75
    },
    {
        "drug_a": "Diltiazem",
        "drug_b": "Metoprolol",
        "type": "additive_hypotension",
        "mechanism": "Non-dihydropyridine CCB plus beta-blocker causes severe bradycardia and AV block",
        "severity": 0.7
    },
    {
        "drug_a": "Amlodipine",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Amlodipine inhibits CYP3A4 raising simvastatin levels; increased myopathy risk",
        "severity": 0.5
    },

    # === CORTICOSTEROID INTERACTIONS ===
    {
        "drug_a": "Prednisone",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "Corticosteroid plus NSAID dramatically increases GI ulceration and bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Naproxen",
        "type": "bleeding_risk",
        "mechanism": "Corticosteroid plus NSAID dramatically increases GI ulceration and bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Corticosteroids increase warfarin effect and add GI bleeding risk",
        "severity": 0.5
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Metformin",
        "type": "reduced_clearance",
        "mechanism": "Corticosteroids raise blood glucose counteracting metformin; may require dose adjustment",
        "severity": 0.4
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Insulin",
        "type": "reduced_clearance",
        "mechanism": "Corticosteroids significantly raise blood glucose requiring insulin dose increases",
        "severity": 0.45
    },

    # === THYROID INTERACTIONS ===
    {
        "drug_a": "Levothyroxine",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "PPIs reduce gastric acid needed for levothyroxine absorption, reducing efficacy",
        "severity": 0.35
    },
    {
        "drug_a": "Levothyroxine",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Thyroid hormone increases catabolism of vitamin K clotting factors, potentiating warfarin",
        "severity": 0.4
    },

    # === ADDITIONAL COMMON MEDICATIONS ===

    # --- Potassium / Electrolyte interactions ---
    {
        "drug_a": "Lisinopril",
        "drug_b": "Potassium Chloride",
        "type": "hyperkalemia_risk",
        "mechanism": "ACE inhibitor reduces aldosterone causing K+ retention; supplemental potassium adds to hyperkalemia risk",
        "severity": 0.6
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Potassium Chloride",
        "type": "hyperkalemia_risk",
        "mechanism": "ARB reduces aldosterone causing K+ retention; supplemental potassium adds to hyperkalemia risk",
        "severity": 0.6
    },
    {
        "drug_a": "Spironolactone",
        "drug_b": "Potassium Chloride",
        "type": "hyperkalemia_risk",
        "mechanism": "Potassium-sparing diuretic plus potassium supplement — high risk of dangerous hyperkalemia",
        "severity": 0.75
    },

    # --- Phenytoin interactions (epilepsy) ---
    {
        "drug_a": "Phenytoin",
        "drug_b": "Warfarin",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin induces and competes for CYP2C9; unpredictable warfarin level changes and bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Phenytoin",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2C9 raising phenytoin levels; risk of phenytoin toxicity (ataxia, nystagmus)",
        "severity": 0.55
    },
    {
        "drug_a": "Phenytoin",
        "drug_b": "Methotrexate",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin displaces methotrexate from protein binding increasing free drug toxicity",
        "severity": 0.5
    },
    {
        "drug_a": "Phenytoin",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "Omeprazole inhibits CYP2C19 reducing phenytoin metabolism; elevated phenytoin levels",
        "severity": 0.4
    },
    {
        "drug_a": "Phenytoin",
        "drug_b": "Levothyroxine",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin increases thyroid hormone metabolism reducing levothyroxine efficacy",
        "severity": 0.4
    },

    # --- Carbamazepine interactions (epilepsy/mood) ---
    {
        "drug_a": "Carbamazepine",
        "drug_b": "Warfarin",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces CYP3A4/2C9 increasing warfarin metabolism and reducing anticoagulant effect",
        "severity": 0.55
    },
    {
        "drug_a": "Carbamazepine",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 causing toxic carbamazepine accumulation",
        "severity": 0.7
    },
    {
        "drug_a": "Carbamazepine",
        "drug_b": "Sertraline",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces CYP3A4 reducing sertraline levels; therapeutic failure risk",
        "severity": 0.45
    },
    {
        "drug_a": "Carbamazepine",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces CYP3A4 dramatically reducing simvastatin levels and efficacy",
        "severity": 0.5
    },
    {
        "drug_a": "Carbamazepine",
        "drug_b": "Diltiazem",
        "type": "reduced_clearance",
        "mechanism": "Diltiazem inhibits CYP3A4 raising carbamazepine to toxic levels; carbamazepine induces diltiazem metabolism",
        "severity": 0.6
    },

    # --- Quetiapine interactions (antipsychotic) ---
    {
        "drug_a": "Quetiapine",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising quetiapine levels; excessive sedation and QT prolongation risk",
        "severity": 0.65
    },
    {
        "drug_a": "Quetiapine",
        "drug_b": "Fluoxetine",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; fluoxetine also inhibits CYP2D6 raising quetiapine levels",
        "severity": 0.5
    },
    {
        "drug_a": "Quetiapine",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Antipsychotic plus benzodiazepine causes additive sedation and respiratory depression",
        "severity": 0.6
    },
    {
        "drug_a": "Quetiapine",
        "drug_b": "Oxycodone",
        "type": "cns_depression",
        "mechanism": "Antipsychotic plus opioid causes additive CNS depression and respiratory risk",
        "severity": 0.65
    },
    {
        "drug_a": "Quetiapine",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT interval; combined use increases torsades de pointes risk",
        "severity": 0.7
    },

    # --- Morphine interactions ---
    {
        "drug_a": "Morphine",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine — FDA black box warning for synergistic respiratory depression",
        "severity": 0.9
    },
    {
        "drug_a": "Morphine",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine — FDA black box warning for synergistic respiratory depression",
        "severity": 0.9
    },
    {
        "drug_a": "Morphine",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression risk",
        "severity": 0.6
    },
    {
        "drug_a": "Morphine",
        "drug_b": "Pregabalin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid causes additive respiratory depression",
        "severity": 0.6
    },
    {
        "drug_a": "Morphine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Morphine with MAOIs can cause serotonin syndrome and severe respiratory depression — contraindicated",
        "severity": 0.9
    },
    {
        "drug_a": "Morphine",
        "drug_b": "Amitriptyline",
        "type": "cns_depression",
        "mechanism": "Opioid plus TCA causes additive sedation and respiratory depression",
        "severity": 0.6
    },

    # --- Citalopram (common SSRI) ---
    {
        "drug_a": "Citalopram",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus serotonergic opioid causes additive serotonin accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Citalopram",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus MAOI — contraindicated due to severe serotonin syndrome risk",
        "severity": 0.95
    },
    {
        "drug_a": "Citalopram",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; FDA warning against concurrent use at high doses",
        "severity": 0.55
    },
    {
        "drug_a": "Citalopram",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT interval; high risk for torsades de pointes",
        "severity": 0.65
    },
    {
        "drug_a": "Citalopram",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "SSRIs impair platelet serotonin uptake reducing aggregation; additive bleeding with anticoagulant",
        "severity": 0.5
    },
    {
        "drug_a": "Citalopram",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SSRI raises serotonin syndrome risk",
        "severity": 0.45
    },

    # --- Rosuvastatin (common statin) ---
    {
        "drug_a": "Rosuvastatin",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Rosuvastatin may increase warfarin effect and INR; monitor closely during initiation",
        "severity": 0.35
    },
    {
        "drug_a": "Rosuvastatin",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin increases rosuvastatin exposure via OATP1B1 inhibition; myopathy risk",
        "severity": 0.55
    },

    # --- Pantoprazole (PPI) ---
    {
        "drug_a": "Pantoprazole",
        "drug_b": "Methotrexate",
        "type": "reduced_clearance",
        "mechanism": "PPIs inhibit renal H+/K+ ATPase reducing methotrexate elimination; toxic accumulation risk",
        "severity": 0.55
    },
    {
        "drug_a": "Pantoprazole",
        "drug_b": "Clopidogrel",
        "type": "reduced_clearance",
        "mechanism": "PPIs may reduce CYP2C19 activation of clopidogrel; less antiplatelet effect (weaker than omeprazole)",
        "severity": 0.35
    },
    {
        "drug_a": "Pantoprazole",
        "drug_b": "Levothyroxine",
        "type": "reduced_clearance",
        "mechanism": "PPIs reduce gastric acid needed for levothyroxine absorption, reducing efficacy",
        "severity": 0.35
    },

    # --- Propranolol (beta-blocker) ---
    {
        "drug_a": "Propranolol",
        "drug_b": "Verapamil",
        "type": "additive_hypotension",
        "mechanism": "Beta-blocker plus non-dihydropyridine CCB causes severe bradycardia and AV block",
        "severity": 0.75
    },
    {
        "drug_a": "Propranolol",
        "drug_b": "Diltiazem",
        "type": "additive_hypotension",
        "mechanism": "Beta-blocker plus non-dihydropyridine CCB causes severe bradycardia and heart block",
        "severity": 0.7
    },
    {
        "drug_a": "Propranolol",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "Beta-blockers mask hypoglycemia symptoms and impair glucose recovery; dangerous with insulin",
        "severity": 0.55
    },
    {
        "drug_a": "Propranolol",
        "drug_b": "Glipizide",
        "type": "additive_hypoglycemia",
        "mechanism": "Beta-blockers mask hypoglycemia warning signs; prolonged hypoglycemia with sulfonylureas",
        "severity": 0.5
    },
    {
        "drug_a": "Propranolol",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2D6 reducing propranolol metabolism; excessive bradycardia and hypotension",
        "severity": 0.5
    },

    # --- Valproic Acid (epilepsy/mood) ---
    {
        "drug_a": "Valproic Acid",
        "drug_b": "Lamotrigine",
        "type": "reduced_clearance",
        "mechanism": "Valproate inhibits lamotrigine glucuronidation doubling levels; serious rash risk including Stevens-Johnson",
        "severity": 0.7
    },
    {
        "drug_a": "Valproic Acid",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Aspirin displaces valproate from protein binding and both impair platelet function; bleeding risk",
        "severity": 0.5
    },
    {
        "drug_a": "Valproic Acid",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Valproate displaces warfarin from protein binding and inhibits platelet aggregation",
        "severity": 0.55
    },
    {
        "drug_a": "Valproic Acid",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces valproate metabolism reducing levels; valproate inhibits carbamazepine epoxide hydrolysis causing toxicity",
        "severity": 0.6
    },

    # --- Clonazepam (benzodiazepine) ---
    {
        "drug_a": "Clonazepam",
        "drug_b": "Oxycodone",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus opioid — FDA black box warning for synergistic respiratory depression",
        "severity": 0.85
    },
    {
        "drug_a": "Clonazepam",
        "drug_b": "Morphine",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus opioid — FDA black box warning for synergistic respiratory depression",
        "severity": 0.9
    },
    {
        "drug_a": "Clonazepam",
        "drug_b": "Tramadol",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus opioid causes synergistic respiratory depression",
        "severity": 0.8
    },
    {
        "drug_a": "Clonazepam",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus gabapentinoid produces additive CNS depression",
        "severity": 0.5
    },

    # --- Hydrocodone (common opioid) ---
    {
        "drug_a": "Hydrocodone",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine — FDA black box warning for synergistic respiratory depression",
        "severity": 0.85
    },
    {
        "drug_a": "Hydrocodone",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine — FDA black box warning for synergistic respiratory depression",
        "severity": 0.85
    },
    {
        "drug_a": "Hydrocodone",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression risk",
        "severity": 0.6
    },
    {
        "drug_a": "Hydrocodone",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Hydrocodone has weak serotonergic activity; combined with SSRI may elevate serotonin syndrome risk",
        "severity": 0.35
    },
    {
        "drug_a": "Hydrocodone",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2D6 reducing hydrocodone conversion to active metabolite and raising parent drug levels",
        "severity": 0.45
    },

    # --- Celecoxib (COX-2 NSAID) ---
    {
        "drug_a": "Celecoxib",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "COX-2 inhibitor reduces thromboxane and may increase warfarin levels via CYP2C9 competition",
        "severity": 0.55
    },
    {
        "drug_a": "Celecoxib",
        "drug_b": "Lisinopril",
        "type": "reduces_kidney_function",
        "mechanism": "COX-2 inhibitors reduce renal prostaglandins blunting ACE inhibitor renal protection",
        "severity": 0.5
    },
    {
        "drug_a": "Celecoxib",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "COX-2 inhibitors reduce diuretic efficacy and worsen renal perfusion",
        "severity": 0.45
    },
    {
        "drug_a": "Celecoxib",
        "drug_b": "Lithium",
        "type": "reduced_clearance",
        "mechanism": "NSAIDs including COX-2 inhibitors reduce renal lithium clearance causing toxic accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Celecoxib",
        "drug_b": "Methotrexate",
        "type": "reduced_clearance",
        "mechanism": "COX-2 inhibitors reduce renal clearance of methotrexate leading to toxic accumulation",
        "severity": 0.65
    },

    # --- Fluconazole (antifungal) ---
    {
        "drug_a": "Fluconazole",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Fluconazole potently inhibits CYP2C9 dramatically increasing warfarin levels and INR",
        "severity": 0.75
    },
    {
        "drug_a": "Fluconazole",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Fluconazole inhibits CYP3A4 raising simvastatin levels; high rhabdomyolysis risk",
        "severity": 0.7
    },
    {
        "drug_a": "Fluconazole",
        "drug_b": "Phenytoin",
        "type": "reduced_clearance",
        "mechanism": "Fluconazole inhibits CYP2C9 raising phenytoin to toxic levels",
        "severity": 0.6
    },
    {
        "drug_a": "Fluconazole",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; combined use increases torsades de pointes risk",
        "severity": 0.5
    },
    {
        "drug_a": "Fluconazole",
        "drug_b": "Glipizide",
        "type": "additive_hypoglycemia",
        "mechanism": "Fluconazole inhibits CYP2C9 raising glipizide levels causing severe hypoglycemia",
        "severity": 0.6
    },

    # --- Doxycycline (antibiotic) ---
    {
        "drug_a": "Doxycycline",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Doxycycline disrupts gut flora reducing vitamin K production and potentiating warfarin",
        "severity": 0.5
    },
    {
        "drug_a": "Doxycycline",
        "drug_b": "Phenytoin",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin induces doxycycline metabolism reducing antibiotic efficacy to subtherapeutic levels",
        "severity": 0.45
    },
    {
        "drug_a": "Doxycycline",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces doxycycline metabolism reducing antibiotic levels and efficacy",
        "severity": 0.45
    },
    {
        "drug_a": "Doxycycline",
        "drug_b": "Isotretinoin",
        "type": "hepatotoxicity",
        "mechanism": "Both can cause intracranial hypertension (pseudotumor cerebri); concurrent use is contraindicated",
        "severity": 0.8
    },

    # --- Allopurinol (gout) ---
    {
        "drug_a": "Allopurinol",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Allopurinol may inhibit warfarin metabolism increasing anticoagulant effect and INR",
        "severity": 0.4
    },
    {
        "drug_a": "Allopurinol",
        "drug_b": "Azathioprine",
        "type": "reduced_clearance",
        "mechanism": "Allopurinol blocks xanthine oxidase preventing azathioprine breakdown; potentially fatal bone marrow suppression",
        "severity": 0.9
    },
    {
        "drug_a": "Allopurinol",
        "drug_b": "Amoxicillin",
        "type": "reduced_clearance",
        "mechanism": "Concurrent use significantly increases risk of skin rash; mechanism not fully understood",
        "severity": 0.35
    },

    # --- Sildenafil (PDE5 inhibitor) ---
    {
        "drug_a": "Sildenafil",
        "drug_b": "Amiodarone",
        "type": "additive_hypotension",
        "mechanism": "PDE5 inhibitor plus antiarrhythmic with vasodilatory properties; severe hypotension risk",
        "severity": 0.6
    },
    {
        "drug_a": "Sildenafil",
        "drug_b": "Amlodipine",
        "type": "additive_hypotension",
        "mechanism": "PDE5 inhibitor plus calcium channel blocker causes additive vasodilation and hypotension",
        "severity": 0.5
    },
    {
        "drug_a": "Sildenafil",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising sildenafil levels; excessive vasodilation and priapism risk",
        "severity": 0.55
    },

    # === BATCH 4: Expanding to 150 drugs ===

    # --- Mirtazapine (antidepressant) ---
    {
        "drug_a": "Mirtazapine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Mirtazapine increases noradrenergic and serotonergic activity; additive serotonin risk with tramadol",
        "severity": 0.5
    },
    {
        "drug_a": "Mirtazapine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Mirtazapine plus MAOI — contraindicated due to severe serotonin syndrome risk",
        "severity": 0.95
    },
    {
        "drug_a": "Mirtazapine",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Mirtazapine sedation plus benzodiazepine causes additive CNS depression",
        "severity": 0.55
    },
    {
        "drug_a": "Mirtazapine",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Mirtazapine sedation plus benzodiazepine causes additive CNS and respiratory depression",
        "severity": 0.55
    },

    # --- Bupropion (antidepressant/smoking cessation) ---
    {
        "drug_a": "Bupropion",
        "drug_b": "Tramadol",
        "type": "reduced_clearance",
        "mechanism": "Both lower seizure threshold; bupropion inhibits CYP2D6 raising tramadol levels",
        "severity": 0.65
    },
    {
        "drug_a": "Bupropion",
        "drug_b": "Metoprolol",
        "type": "reduced_clearance",
        "mechanism": "Bupropion strongly inhibits CYP2D6 raising metoprolol levels; excessive bradycardia risk",
        "severity": 0.55
    },
    {
        "drug_a": "Bupropion",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Both inhibit CYP2D6; mutual inhibition raises levels of both drugs and lowers seizure threshold",
        "severity": 0.5
    },
    {
        "drug_a": "Bupropion",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Bupropion plus MAOI increases risk of hypertensive crisis — contraindicated",
        "severity": 0.9
    },

    # --- Paroxetine (SSRI) ---
    {
        "drug_a": "Paroxetine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus serotonergic opioid; paroxetine also inhibits CYP2D6 reducing tramadol efficacy",
        "severity": 0.6
    },
    {
        "drug_a": "Paroxetine",
        "drug_b": "Metoprolol",
        "type": "reduced_clearance",
        "mechanism": "Paroxetine potently inhibits CYP2D6 doubling metoprolol levels; severe bradycardia",
        "severity": 0.6
    },
    {
        "drug_a": "Paroxetine",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "SSRIs impair platelet aggregation; additive bleeding risk with anticoagulant",
        "severity": 0.5
    },
    {
        "drug_a": "Paroxetine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus MAOI — contraindicated; potentially fatal serotonin syndrome",
        "severity": 0.95
    },
    {
        "drug_a": "Paroxetine",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SSRI raises syndrome risk",
        "severity": 0.45
    },

    # --- Aripiprazole (antipsychotic) ---
    {
        "drug_a": "Aripiprazole",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2D6 doubling aripiprazole levels; excessive sedation",
        "severity": 0.5
    },
    {
        "drug_a": "Aripiprazole",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising aripiprazole levels; dose reduction needed",
        "severity": 0.5
    },
    {
        "drug_a": "Aripiprazole",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces CYP3A4 reducing aripiprazole levels to subtherapeutic",
        "severity": 0.45
    },

    # --- Olanzapine (antipsychotic) ---
    {
        "drug_a": "Olanzapine",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Antipsychotic plus benzodiazepine causes severe hypotension, respiratory depression, and excessive sedation",
        "severity": 0.7
    },
    {
        "drug_a": "Olanzapine",
        "drug_b": "Ciprofloxacin",
        "type": "reduced_clearance",
        "mechanism": "Ciprofloxacin inhibits CYP1A2 raising olanzapine levels; excessive sedation risk",
        "severity": 0.5
    },
    {
        "drug_a": "Olanzapine",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces CYP1A2 reducing olanzapine levels significantly",
        "severity": 0.45
    },
    {
        "drug_a": "Olanzapine",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits olanzapine metabolism; marketed combination (Symbyax) but requires dose adjustment",
        "severity": 0.4
    },

    # --- Risperidone (antipsychotic) ---
    {
        "drug_a": "Risperidone",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2D6 raising risperidone levels; EPS and prolactin elevation risk",
        "severity": 0.55
    },
    {
        "drug_a": "Risperidone",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces CYP3A4 reducing risperidone levels by 50%",
        "severity": 0.5
    },

    # --- Clozapine (antipsychotic) ---
    {
        "drug_a": "Clozapine",
        "drug_b": "Ciprofloxacin",
        "type": "reduced_clearance",
        "mechanism": "Ciprofloxacin inhibits CYP1A2 causing dangerous clozapine accumulation; seizure and agranulocytosis risk",
        "severity": 0.75
    },
    {
        "drug_a": "Clozapine",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2D6 raising clozapine levels; increased seizure and sedation risk",
        "severity": 0.55
    },
    {
        "drug_a": "Clozapine",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Both cause agranulocytosis; combination is contraindicated due to additive bone marrow suppression risk",
        "severity": 0.85
    },

    # --- Tamoxifen (breast cancer) ---
    {
        "drug_a": "Tamoxifen",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine potently inhibits CYP2D6 blocking tamoxifen conversion to active endoxifen; therapeutic failure",
        "severity": 0.7
    },
    {
        "drug_a": "Tamoxifen",
        "drug_b": "Paroxetine",
        "type": "reduced_clearance",
        "mechanism": "Paroxetine potently inhibits CYP2D6 blocking tamoxifen activation; increased breast cancer recurrence",
        "severity": 0.75
    },
    {
        "drug_a": "Tamoxifen",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Tamoxifen inhibits warfarin metabolism significantly increasing INR and bleeding risk",
        "severity": 0.65
    },

    # --- Metoclopramide (GI motility) ---
    {
        "drug_a": "Metoclopramide",
        "drug_b": "Haloperidol",
        "type": "anticholinergic_burden",
        "mechanism": "Both block dopamine D2 receptors; additive risk of extrapyramidal symptoms and tardive dyskinesia",
        "severity": 0.6
    },
    {
        "drug_a": "Metoclopramide",
        "drug_b": "Quetiapine",
        "type": "anticholinergic_burden",
        "mechanism": "Additive dopamine blockade increases extrapyramidal symptoms and neuroleptic malignant syndrome risk",
        "severity": 0.55
    },
    {
        "drug_a": "Metoclopramide",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Both have serotonergic activity; combined use may increase serotonin syndrome risk",
        "severity": 0.4
    },

    # --- Nifedipine (calcium channel blocker) ---
    {
        "drug_a": "Nifedipine",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising nifedipine levels; severe hypotension risk",
        "severity": 0.6
    },
    {
        "drug_a": "Nifedipine",
        "drug_b": "Phenytoin",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin induces CYP3A4 reducing nifedipine efficacy; nifedipine may raise phenytoin levels",
        "severity": 0.45
    },
    {
        "drug_a": "Nifedipine",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Both metabolized by CYP3A4; nifedipine may raise simvastatin levels increasing myopathy risk",
        "severity": 0.4
    },

    # --- Enalapril (ACE inhibitor) ---
    {
        "drug_a": "Enalapril",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ACE inhibitor plus potassium-sparing diuretic causes additive potassium retention",
        "severity": 0.6
    },
    {
        "drug_a": "Enalapril",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs blunt ACE inhibitor renal protection and reduce GFR",
        "severity": 0.55
    },
    {
        "drug_a": "Enalapril",
        "drug_b": "Potassium Chloride",
        "type": "hyperkalemia_risk",
        "mechanism": "ACE inhibitor retains potassium; supplemental potassium increases hyperkalemia risk",
        "severity": 0.6
    },
    {
        "drug_a": "Enalapril",
        "drug_b": "Trimethoprim",
        "type": "hyperkalemia_risk",
        "mechanism": "Trimethoprim blocks ENaC; combined with ACE inhibitor causes dangerous hyperkalemia",
        "severity": 0.6
    },

    # --- Ramipril (ACE inhibitor) ---
    {
        "drug_a": "Ramipril",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ACE inhibitor plus potassium-sparing diuretic — additive hyperkalemia risk",
        "severity": 0.6
    },
    {
        "drug_a": "Ramipril",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal prostaglandins blunting ACE inhibitor protection",
        "severity": 0.55
    },

    # --- Valsartan (ARB) ---
    {
        "drug_a": "Valsartan",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ARB plus potassium-sparing diuretic — additive potassium retention",
        "severity": 0.6
    },
    {
        "drug_a": "Valsartan",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs blunt ARB renal protective effects and reduce GFR",
        "severity": 0.55
    },
    {
        "drug_a": "Valsartan",
        "drug_b": "Potassium Chloride",
        "type": "hyperkalemia_risk",
        "mechanism": "ARB retains potassium; supplemental potassium increases hyperkalemia risk",
        "severity": 0.6
    },

    # --- Dabigatran (DOAC) ---
    {
        "drug_a": "Dabigatran",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Direct thrombin inhibitor plus antiplatelet synergistically increases bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Dabigatran",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAID impairs platelet function adding to DOAC anticoagulation; GI bleeding risk",
        "severity": 0.55
    },
    {
        "drug_a": "Dabigatran",
        "drug_b": "Verapamil",
        "type": "reduced_clearance",
        "mechanism": "Verapamil inhibits P-glycoprotein increasing dabigatran absorption by 60%; bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Dabigatran",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits P-glycoprotein raising dabigatran levels; major bleeding risk",
        "severity": 0.65
    },

    # --- Dapagliflozin (SGLT2 inhibitor) ---
    {
        "drug_a": "Dapagliflozin",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "SGLT2 inhibitor plus insulin increases hypoglycemia risk; dose reduction needed",
        "severity": 0.5
    },
    {
        "drug_a": "Dapagliflozin",
        "drug_b": "Furosemide",
        "type": "additive_hypotension",
        "mechanism": "Both cause volume depletion; combined use increases dehydration and hypotension risk",
        "severity": 0.5
    },

    # --- Empagliflozin (SGLT2 inhibitor) ---
    {
        "drug_a": "Empagliflozin",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "SGLT2 inhibitor plus insulin increases hypoglycemia risk; dose adjustment required",
        "severity": 0.5
    },
    {
        "drug_a": "Empagliflozin",
        "drug_b": "Furosemide",
        "type": "additive_hypotension",
        "mechanism": "Both promote volume depletion; combined risk of dehydration and acute kidney injury",
        "severity": 0.5
    },

    # --- Sitagliptin (DPP-4 inhibitor) ---
    {
        "drug_a": "Sitagliptin",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "DPP-4 inhibitor enhances incretin effect; combined with insulin increases hypoglycemia",
        "severity": 0.45
    },
    {
        "drug_a": "Sitagliptin",
        "drug_b": "Glipizide",
        "type": "additive_hypoglycemia",
        "mechanism": "DPP-4 inhibitor plus sulfonylurea increases hypoglycemia risk",
        "severity": 0.45
    },

    # --- Pioglitazone (thiazolidinedione) ---
    {
        "drug_a": "Pioglitazone",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "TZD plus insulin increases hypoglycemia risk and fluid retention causing heart failure",
        "severity": 0.55
    },
    {
        "drug_a": "Pioglitazone",
        "drug_b": "Furosemide",
        "type": "additive_kidney_stress",
        "mechanism": "Pioglitazone causes fluid retention counteracting diuretic effect; heart failure exacerbation",
        "severity": 0.45
    },

    # --- Levofloxacin (fluoroquinolone) ---
    {
        "drug_a": "Levofloxacin",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT interval; combined use greatly increases torsades risk",
        "severity": 0.7
    },
    {
        "drug_a": "Levofloxacin",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT; additive risk of cardiac arrhythmia",
        "severity": 0.5
    },
    {
        "drug_a": "Levofloxacin",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Fluoroquinolones disrupt gut flora and may inhibit warfarin metabolism; increased INR",
        "severity": 0.55
    },
    {
        "drug_a": "Levofloxacin",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "Fluoroquinolones cause glucose dysregulation; combined with insulin may cause severe hypoglycemia",
        "severity": 0.45
    },
    {
        "drug_a": "Levofloxacin",
        "drug_b": "Prednisone",
        "type": "reduced_clearance",
        "mechanism": "Fluoroquinolone plus corticosteroid dramatically increases tendon rupture risk",
        "severity": 0.6
    },

    # --- Rifampin (antibiotic/TB) ---
    {
        "drug_a": "Rifampin",
        "drug_b": "Warfarin",
        "type": "reduced_clearance",
        "mechanism": "Rifampin potently induces CYP enzymes dramatically reducing warfarin levels; loss of anticoagulation",
        "severity": 0.8
    },
    {
        "drug_a": "Rifampin",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Rifampin induces CYP3A4 reducing simvastatin to subtherapeutic levels",
        "severity": 0.6
    },
    {
        "drug_a": "Rifampin",
        "drug_b": "Methadone",
        "type": "reduced_clearance",
        "mechanism": "Rifampin induces CYP3A4 causing rapid methadone withdrawal symptoms",
        "severity": 0.75
    },
    {
        "drug_a": "Rifampin",
        "drug_b": "Apixaban",
        "type": "reduced_clearance",
        "mechanism": "Rifampin induces CYP3A4 and P-gp reducing apixaban levels by 50%; loss of anticoagulation",
        "severity": 0.7
    },
    {
        "drug_a": "Rifampin",
        "drug_b": "Fluconazole",
        "type": "reduced_clearance",
        "mechanism": "Rifampin induces fluconazole metabolism reducing antifungal efficacy",
        "severity": 0.5
    },

    # --- Erythromycin (macrolide) ---
    {
        "drug_a": "Erythromycin",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Erythromycin inhibits CYP3A4 raising simvastatin levels; rhabdomyolysis risk",
        "severity": 0.7
    },
    {
        "drug_a": "Erythromycin",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; combined use significantly increases torsades risk",
        "severity": 0.65
    },
    {
        "drug_a": "Erythromycin",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Erythromycin inhibits CYP3A4 and disrupts gut flora; increased warfarin effect and INR",
        "severity": 0.55
    },
    {
        "drug_a": "Erythromycin",
        "drug_b": "Digoxin",
        "type": "reduced_clearance",
        "mechanism": "Erythromycin inhibits P-gp and kills gut bacteria that inactivate digoxin; toxicity risk",
        "severity": 0.65
    },
    {
        "drug_a": "Erythromycin",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Erythromycin inhibits CYP3A4 causing toxic carbamazepine accumulation",
        "severity": 0.65
    },

    # --- Cyclosporine (immunosuppressant) ---
    {
        "drug_a": "Cyclosporine",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Cyclosporine inhibits CYP3A4 and OATP1B1 dramatically raising statin levels; rhabdomyolysis",
        "severity": 0.8
    },
    {
        "drug_a": "Cyclosporine",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising cyclosporine to nephrotoxic levels",
        "severity": 0.7
    },
    {
        "drug_a": "Cyclosporine",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs plus cyclosporine causes synergistic nephrotoxicity",
        "severity": 0.65
    },
    {
        "drug_a": "Cyclosporine",
        "drug_b": "Potassium Chloride",
        "type": "hyperkalemia_risk",
        "mechanism": "Cyclosporine causes potassium retention; supplemental potassium adds to hyperkalemia risk",
        "severity": 0.55
    },
    {
        "drug_a": "Cyclosporine",
        "drug_b": "Digoxin",
        "type": "reduced_clearance",
        "mechanism": "Cyclosporine inhibits P-gp reducing digoxin clearance; toxicity risk",
        "severity": 0.6
    },

    # --- Tacrolimus (immunosuppressant) ---
    {
        "drug_a": "Tacrolimus",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising tacrolimus to nephrotoxic levels",
        "severity": 0.75
    },
    {
        "drug_a": "Tacrolimus",
        "drug_b": "Fluconazole",
        "type": "reduced_clearance",
        "mechanism": "Fluconazole inhibits CYP3A4 and CYP2C9 raising tacrolimus levels; nephrotoxicity",
        "severity": 0.7
    },
    {
        "drug_a": "Tacrolimus",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs plus tacrolimus causes synergistic nephrotoxicity",
        "severity": 0.6
    },
    {
        "drug_a": "Tacrolimus",
        "drug_b": "Potassium Chloride",
        "type": "hyperkalemia_risk",
        "mechanism": "Tacrolimus causes potassium retention; supplemental potassium increases hyperkalemia risk",
        "severity": 0.55
    },

    # --- Clopidogrel + PPI interactions (expanded) ---
    {
        "drug_a": "Clopidogrel",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2C19 reducing clopidogrel activation; diminished antiplatelet effect",
        "severity": 0.5
    },

    # --- Sumatriptan (migraine) ---
    {
        "drug_a": "Sumatriptan",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Triptan plus SSRI increases serotonin; FDA advisory for serotonin syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Sumatriptan",
        "drug_b": "Fluoxetine",
        "type": "serotonin_increase",
        "mechanism": "Triptan plus SSRI increases serotonin syndrome risk; FDA advisory",
        "severity": 0.45
    },
    {
        "drug_a": "Sumatriptan",
        "drug_b": "Venlafaxine",
        "type": "serotonin_increase",
        "mechanism": "Triptan plus SNRI increases serotonin syndrome risk",
        "severity": 0.5
    },
    {
        "drug_a": "Sumatriptan",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Triptan plus MAOI — contraindicated; severe serotonin syndrome and hypertensive crisis",
        "severity": 0.9
    },

    # --- Chlorthalidone (thiazide-like diuretic) ---
    {
        "drug_a": "Chlorthalidone",
        "drug_b": "Lithium",
        "type": "reduced_clearance",
        "mechanism": "Thiazide-like diuretics reduce lithium renal clearance causing toxic accumulation",
        "severity": 0.7
    },
    {
        "drug_a": "Chlorthalidone",
        "drug_b": "Digoxin",
        "type": "additive_kidney_stress",
        "mechanism": "Thiazide-induced hypokalemia potentiates digoxin cardiac toxicity",
        "severity": 0.55
    },

    # --- Ezetimibe (cholesterol) ---
    {
        "drug_a": "Ezetimibe",
        "drug_b": "Cyclosporine",
        "type": "reduced_clearance",
        "mechanism": "Cyclosporine increases ezetimibe levels; ezetimibe also raises cyclosporine exposure",
        "severity": 0.5
    },

    # --- Hydroxychloroquine (autoimmune) ---
    {
        "drug_a": "Hydroxychloroquine",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; additive risk of torsades de pointes",
        "severity": 0.65
    },
    {
        "drug_a": "Hydroxychloroquine",
        "drug_b": "Digoxin",
        "type": "reduced_clearance",
        "mechanism": "Hydroxychloroquine inhibits P-gp raising digoxin levels; cardiac toxicity risk",
        "severity": 0.55
    },
    {
        "drug_a": "Hydroxychloroquine",
        "drug_b": "Metformin",
        "type": "additive_hypoglycemia",
        "mechanism": "Hydroxychloroquine can lower blood glucose; additive hypoglycemia with metformin",
        "severity": 0.4
    },

    # --- Colchicine (gout) ---
    {
        "drug_a": "Colchicine",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 and P-gp causing fatal colchicine toxicity — FDA warning",
        "severity": 0.85
    },
    {
        "drug_a": "Colchicine",
        "drug_b": "Cyclosporine",
        "type": "reduced_clearance",
        "mechanism": "Cyclosporine inhibits P-gp raising colchicine levels; myopathy and multi-organ failure risk",
        "severity": 0.75
    },
    {
        "drug_a": "Colchicine",
        "drug_b": "Atorvastatin",
        "type": "reduced_clearance",
        "mechanism": "Both metabolized by CYP3A4; combined use increases rhabdomyolysis risk",
        "severity": 0.5
    },

    # --- Spironolactone + Digoxin (important cross-link) ---
    {
        "drug_a": "Spironolactone",
        "drug_b": "Digoxin",
        "type": "reduced_clearance",
        "mechanism": "Spironolactone reduces digoxin renal clearance and interferes with digoxin assay measurement",
        "severity": 0.5
    },

    # --- Metformin + Contrast Dye (common clinical scenario) ---
    {
        "drug_a": "Metformin",
        "drug_b": "Iodinated Contrast",
        "type": "additive_kidney_stress",
        "mechanism": "Iodinated contrast can cause acute kidney injury; metformin accumulates causing lactic acidosis",
        "severity": 0.65
    },

    # --- Theophylline (asthma/COPD) ---
    {
        "drug_a": "Theophylline",
        "drug_b": "Ciprofloxacin",
        "type": "reduced_clearance",
        "mechanism": "Ciprofloxacin inhibits CYP1A2 raising theophylline to toxic levels; seizures and arrhythmia",
        "severity": 0.7
    },
    {
        "drug_a": "Theophylline",
        "drug_b": "Erythromycin",
        "type": "reduced_clearance",
        "mechanism": "Erythromycin inhibits CYP3A4 raising theophylline levels; toxicity risk",
        "severity": 0.6
    },
    {
        "drug_a": "Theophylline",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine induces CYP1A2 reducing theophylline levels; loss of bronchodilation",
        "severity": 0.45
    },
    {
        "drug_a": "Theophylline",
        "drug_b": "Phenytoin",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin induces theophylline metabolism; theophylline reduces phenytoin levels; mutual antagonism",
        "severity": 0.45
    },

    # === BATCH 5: Final expansion to 150 drugs ===

    # --- Ticagrelor (antiplatelet) ---
    {
        "drug_a": "Ticagrelor",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Dual antiplatelet therapy significantly increases bleeding; aspirin doses above 100mg reduce ticagrelor efficacy",
        "severity": 0.55
    },
    {
        "drug_a": "Ticagrelor",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising ticagrelor levels; increased bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Ticagrelor",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Ticagrelor inhibits CYP3A4 raising simvastatin levels; myopathy risk",
        "severity": 0.5
    },
    {
        "drug_a": "Ticagrelor",
        "drug_b": "Digoxin",
        "type": "reduced_clearance",
        "mechanism": "Ticagrelor inhibits P-glycoprotein raising digoxin levels",
        "severity": 0.5
    },

    # --- Candesartan (ARB) ---
    {
        "drug_a": "Candesartan",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ARB plus potassium-sparing diuretic — additive potassium retention risk",
        "severity": 0.6
    },
    {
        "drug_a": "Candesartan",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs blunt ARB renal protective effects and reduce GFR",
        "severity": 0.55
    },

    # --- Atenolol (beta-blocker) ---
    {
        "drug_a": "Atenolol",
        "drug_b": "Verapamil",
        "type": "additive_hypotension",
        "mechanism": "Beta-blocker plus non-dihydropyridine CCB causes severe bradycardia and AV block",
        "severity": 0.75
    },
    {
        "drug_a": "Atenolol",
        "drug_b": "Diltiazem",
        "type": "additive_hypotension",
        "mechanism": "Beta-blocker plus non-dihydropyridine CCB causes severe bradycardia and heart block",
        "severity": 0.7
    },
    {
        "drug_a": "Atenolol",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "Beta-blockers mask hypoglycemia symptoms and impair glucose recovery",
        "severity": 0.5
    },

    # --- Bisoprolol (beta-blocker) ---
    {
        "drug_a": "Bisoprolol",
        "drug_b": "Verapamil",
        "type": "additive_hypotension",
        "mechanism": "Beta-blocker plus non-dihydropyridine CCB — severe bradycardia risk",
        "severity": 0.75
    },
    {
        "drug_a": "Bisoprolol",
        "drug_b": "Diltiazem",
        "type": "additive_hypotension",
        "mechanism": "Beta-blocker plus non-dihydropyridine CCB — AV block and bradycardia risk",
        "severity": 0.7
    },

    # --- Sotalol (antiarrhythmic/beta-blocker) ---
    {
        "drug_a": "Sotalol",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT; combined use is contraindicated due to torsades risk",
        "severity": 0.85
    },
    {
        "drug_a": "Sotalol",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; additive cardiac arrhythmia risk",
        "severity": 0.55
    },
    {
        "drug_a": "Sotalol",
        "drug_b": "Ciprofloxacin",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT; fluoroquinolone adds to sotalol cardiac risk",
        "severity": 0.55
    },
    {
        "drug_a": "Sotalol",
        "drug_b": "Furosemide",
        "type": "additive_kidney_stress",
        "mechanism": "Furosemide-induced hypokalemia increases sotalol QT prolongation and arrhythmia risk",
        "severity": 0.6
    },

    # --- Topiramate (epilepsy/migraine) ---
    {
        "drug_a": "Topiramate",
        "drug_b": "Valproic Acid",
        "type": "hepatotoxicity",
        "mechanism": "Combined use increases hyperammonemia risk; both can cause metabolic acidosis",
        "severity": 0.55
    },
    {
        "drug_a": "Topiramate",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "Both can cause metabolic acidosis; combined use increases lactic acidosis risk",
        "severity": 0.45
    },
    {
        "drug_a": "Topiramate",
        "drug_b": "Lithium",
        "type": "reduced_clearance",
        "mechanism": "Topiramate may alter lithium levels; monitoring required",
        "severity": 0.35
    },

    # --- Levetiracetam (epilepsy) ---
    {
        "drug_a": "Levetiracetam",
        "drug_b": "Carbamazepine",
        "type": "reduced_clearance",
        "mechanism": "Carbamazepine may reduce levetiracetam levels through enzyme induction",
        "severity": 0.35
    },

    # --- Duloxetine expanded ---
    {
        "drug_a": "Duloxetine",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "SNRIs impair platelet serotonin uptake; additive bleeding with anticoagulant",
        "severity": 0.5
    },
    {
        "drug_a": "Duloxetine",
        "drug_b": "Metoprolol",
        "type": "reduced_clearance",
        "mechanism": "Duloxetine inhibits CYP2D6 raising metoprolol levels; bradycardia risk",
        "severity": 0.5
    },

    # --- Fentanyl (opioid) ---
    {
        "drug_a": "Fentanyl",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine — FDA black box warning; synergistic respiratory depression",
        "severity": 0.9
    },
    {
        "drug_a": "Fentanyl",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine — FDA black box warning for fatal respiratory depression",
        "severity": 0.9
    },
    {
        "drug_a": "Fentanyl",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression risk",
        "severity": 0.6
    },
    {
        "drug_a": "Fentanyl",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising fentanyl levels; fatal respiratory depression risk",
        "severity": 0.75
    },
    {
        "drug_a": "Fentanyl",
        "drug_b": "Fluconazole",
        "type": "reduced_clearance",
        "mechanism": "Fluconazole inhibits CYP3A4 raising fentanyl levels; respiratory depression risk",
        "severity": 0.65
    },
    {
        "drug_a": "Fentanyl",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Fentanyl has serotonergic activity; combined with SSRI increases serotonin syndrome risk",
        "severity": 0.5
    },
    {
        "drug_a": "Fentanyl",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Fentanyl plus MAOI — potentially fatal serotonin syndrome; contraindicated",
        "severity": 0.9
    },

    # --- Dexamethasone (corticosteroid) ---
    {
        "drug_a": "Dexamethasone",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "Corticosteroid plus NSAID dramatically increases GI ulceration and bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Dexamethasone",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Dexamethasone can both increase and decrease warfarin effect; unpredictable INR changes",
        "severity": 0.5
    },
    {
        "drug_a": "Dexamethasone",
        "drug_b": "Insulin",
        "type": "reduced_clearance",
        "mechanism": "Corticosteroids significantly raise blood glucose requiring insulin dose increases",
        "severity": 0.5
    },
    {
        "drug_a": "Dexamethasone",
        "drug_b": "Phenytoin",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin induces CYP3A4 reducing dexamethasone efficacy; dexamethasone may alter phenytoin levels",
        "severity": 0.45
    },

    # --- Linagliptin (DPP-4 inhibitor) ---
    {
        "drug_a": "Linagliptin",
        "drug_b": "Insulin",
        "type": "additive_hypoglycemia",
        "mechanism": "DPP-4 inhibitor enhances incretin; additive hypoglycemia with insulin",
        "severity": 0.45
    },
    {
        "drug_a": "Linagliptin",
        "drug_b": "Rifampin",
        "type": "reduced_clearance",
        "mechanism": "Rifampin induces P-gp reducing linagliptin efficacy below therapeutic levels",
        "severity": 0.5
    },

    # --- Febuxostat (gout) ---
    {
        "drug_a": "Febuxostat",
        "drug_b": "Azathioprine",
        "type": "reduced_clearance",
        "mechanism": "Febuxostat inhibits xanthine oxidase preventing azathioprine breakdown; bone marrow toxicity",
        "severity": 0.85
    },
    {
        "drug_a": "Febuxostat",
        "drug_b": "Theophylline",
        "type": "reduced_clearance",
        "mechanism": "Febuxostat may inhibit theophylline metabolism via xanthine oxidase pathway",
        "severity": 0.4
    },

    # --- Warfarin + Vitamin K (important clinical) ---
    {
        "drug_a": "Warfarin",
        "drug_b": "Vitamin K",
        "type": "reduced_clearance",
        "mechanism": "Vitamin K directly antagonizes warfarin effect; high-dose Vitamin K reverses anticoagulation",
        "severity": 0.6
    },

    # --- Ceftriaxone (antibiotic) ---
    {
        "drug_a": "Ceftriaxone",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Ceftriaxone disrupts vitamin K-producing gut flora potentiating warfarin",
        "severity": 0.45
    },

    # --- Gentamicin (aminoglycoside) ---
    {
        "drug_a": "Gentamicin",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "Both are nephrotoxic and ototoxic; combined use dramatically increases permanent hearing loss risk",
        "severity": 0.7
    },
    {
        "drug_a": "Gentamicin",
        "drug_b": "Vancomycin",
        "type": "reduces_kidney_function",
        "mechanism": "Both nephrotoxic; concurrent use significantly increases acute kidney injury risk",
        "severity": 0.7
    },
    {
        "drug_a": "Gentamicin",
        "drug_b": "Cyclosporine",
        "type": "reduces_kidney_function",
        "mechanism": "Additive nephrotoxicity; both drugs concentrate in renal tubular cells",
        "severity": 0.65
    },

    # --- Vancomycin (antibiotic) ---
    {
        "drug_a": "Vancomycin",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "Vancomycin nephrotoxicity worsened by loop diuretic-induced volume depletion",
        "severity": 0.55
    },

    # --- Amphotericin B (antifungal) ---
    {
        "drug_a": "Amphotericin B",
        "drug_b": "Gentamicin",
        "type": "reduces_kidney_function",
        "mechanism": "Both highly nephrotoxic; combined use dramatically increases kidney failure risk",
        "severity": 0.8
    },
    {
        "drug_a": "Amphotericin B",
        "drug_b": "Cyclosporine",
        "type": "reduces_kidney_function",
        "mechanism": "Synergistic nephrotoxicity; both concentrate in renal tissue",
        "severity": 0.75
    },
    {
        "drug_a": "Amphotericin B",
        "drug_b": "Digoxin",
        "type": "additive_kidney_stress",
        "mechanism": "Amphotericin B causes hypokalemia which potentiates digoxin cardiac toxicity",
        "severity": 0.6
    },

    # --- Nitrofurantoin (UTI antibiotic) ---
    {
        "drug_a": "Nitrofurantoin",
        "drug_b": "Magnesium Hydroxide",
        "type": "reduced_clearance",
        "mechanism": "Antacids reduce nitrofurantoin absorption reducing antibacterial efficacy",
        "severity": 0.4
    },

    # --- Tadalafil (PDE5 inhibitor) ---
    {
        "drug_a": "Tadalafil",
        "drug_b": "Amlodipine",
        "type": "additive_hypotension",
        "mechanism": "PDE5 inhibitor plus calcium channel blocker causes additive vasodilation and hypotension",
        "severity": 0.5
    },
    {
        "drug_a": "Tadalafil",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising tadalafil levels; hypotension and priapism risk",
        "severity": 0.5
    },

    # --- Methylphenidate (ADHD) ---
    {
        "drug_a": "Methylphenidate",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Methylphenidate plus MAOI — contraindicated; hypertensive crisis risk",
        "severity": 0.85
    },
    {
        "drug_a": "Methylphenidate",
        "drug_b": "Phenytoin",
        "type": "reduced_clearance",
        "mechanism": "Methylphenidate inhibits phenytoin metabolism raising levels; toxicity risk",
        "severity": 0.45
    },
    {
        "drug_a": "Methylphenidate",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Methylphenidate may inhibit warfarin metabolism increasing INR",
        "severity": 0.35
    },

    # --- Amphetamine (ADHD) ---
    {
        "drug_a": "Amphetamine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Amphetamine plus MAOI — contraindicated; potentially fatal hypertensive crisis and serotonin syndrome",
        "severity": 0.95
    },
    {
        "drug_a": "Amphetamine",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Amphetamine releases serotonin; combined with SSRI increases serotonin syndrome risk",
        "severity": 0.45
    },

    # --- Atomoxetine (ADHD) ---
    {
        "drug_a": "Atomoxetine",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine potently inhibits CYP2D6 raising atomoxetine levels 6-8 fold; cardiovascular risk",
        "severity": 0.6
    },
    {
        "drug_a": "Atomoxetine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Atomoxetine plus MAOI — contraindicated; risk of serious cardiovascular events",
        "severity": 0.85
    },

    # --- Zolpidem (sleep) ---
    {
        "drug_a": "Zolpidem",
        "drug_b": "Oxycodone",
        "type": "cns_depression",
        "mechanism": "Sedative-hypnotic plus opioid — additive CNS and respiratory depression",
        "severity": 0.7
    },
    {
        "drug_a": "Zolpidem",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Dual sedative-hypnotics cause excessive CNS depression and next-day impairment",
        "severity": 0.6
    },
    {
        "drug_a": "Zolpidem",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising zolpidem levels; excessive sedation",
        "severity": 0.45
    },

    # --- Lorazepam (benzodiazepine) ---
    {
        "drug_a": "Lorazepam",
        "drug_b": "Oxycodone",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus opioid — FDA black box warning for respiratory depression",
        "severity": 0.85
    },
    {
        "drug_a": "Lorazepam",
        "drug_b": "Morphine",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus opioid — FDA black box warning for fatal respiratory depression",
        "severity": 0.9
    },
    {
        "drug_a": "Lorazepam",
        "drug_b": "Fentanyl",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus potent opioid — extremely high risk of fatal respiratory depression",
        "severity": 0.9
    },

    # --- Budesonide (corticosteroid, inhaled/oral) ---
    {
        "drug_a": "Budesonide",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising budesonide levels; Cushing syndrome risk",
        "severity": 0.55
    },

    # --- Montelukast (asthma) ---
    {
        "drug_a": "Montelukast",
        "drug_b": "Phenytoin",
        "type": "reduced_clearance",
        "mechanism": "Phenytoin induces CYP3A4 reducing montelukast levels and asthma control",
        "severity": 0.4
    },

    # --- Ranolazine (angina) ---
    {
        "drug_a": "Ranolazine",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Ranolazine inhibits CYP3A4 raising simvastatin levels; rhabdomyolysis risk",
        "severity": 0.55
    },
    {
        "drug_a": "Ranolazine",
        "drug_b": "Digoxin",
        "type": "reduced_clearance",
        "mechanism": "Ranolazine inhibits P-glycoprotein raising digoxin levels; toxicity risk",
        "severity": 0.5
    },

    # --- Dronedarone (antiarrhythmic) ---
    {
        "drug_a": "Dronedarone",
        "drug_b": "Digoxin",
        "type": "reduced_clearance",
        "mechanism": "Dronedarone inhibits P-gp raising digoxin levels 2.5-fold; reduce digoxin dose by 50%",
        "severity": 0.7
    },
    {
        "drug_a": "Dronedarone",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Dronedarone inhibits CYP3A4 raising simvastatin levels; rhabdomyolysis risk",
        "severity": 0.6
    },
    {
        "drug_a": "Dronedarone",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Dronedarone inhibits CYP2C9 raising warfarin levels and INR",
        "severity": 0.55
    },

    # === BATCH 6: Final 15+ drugs ===

    # --- Ketoconazole (antifungal) ---
    {
        "drug_a": "Ketoconazole",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Ketoconazole potently inhibits CYP3A4 raising simvastatin to dangerous levels; rhabdomyolysis — contraindicated",
        "severity": 0.85
    },
    {
        "drug_a": "Ketoconazole",
        "drug_b": "Fentanyl",
        "type": "reduced_clearance",
        "mechanism": "Ketoconazole inhibits CYP3A4 raising fentanyl levels; fatal respiratory depression risk",
        "severity": 0.8
    },
    {
        "drug_a": "Ketoconazole",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Ketoconazole inhibits CYP3A4 increasing warfarin levels and bleeding risk",
        "severity": 0.6
    },

    # --- Grapefruit (food interaction, clinically significant) ---
    {
        "drug_a": "Grapefruit Juice",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Grapefruit inhibits intestinal CYP3A4 raising simvastatin levels up to 16-fold; rhabdomyolysis risk",
        "severity": 0.7
    },
    {
        "drug_a": "Grapefruit Juice",
        "drug_b": "Fentanyl",
        "type": "reduced_clearance",
        "mechanism": "Grapefruit inhibits CYP3A4 raising fentanyl absorption; respiratory depression risk",
        "severity": 0.55
    },
    {
        "drug_a": "Grapefruit Juice",
        "drug_b": "Cyclosporine",
        "type": "reduced_clearance",
        "mechanism": "Grapefruit inhibits CYP3A4 raising cyclosporine levels; nephrotoxicity",
        "severity": 0.6
    },

    # --- Nabumetone (NSAID) ---
    {
        "drug_a": "Nabumetone",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "NSAID plus anticoagulant increases GI bleeding and inhibits platelet function",
        "severity": 0.6
    },
    {
        "drug_a": "Nabumetone",
        "drug_b": "Lisinopril",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal prostaglandins blunting ACE inhibitor renal protection",
        "severity": 0.5
    },

    # --- Amikacin (aminoglycoside) ---
    {
        "drug_a": "Amikacin",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "Both nephrotoxic and ototoxic; loop diuretics increase aminoglycoside toxicity",
        "severity": 0.7
    },
    {
        "drug_a": "Amikacin",
        "drug_b": "Vancomycin",
        "type": "reduces_kidney_function",
        "mechanism": "Both nephrotoxic; combined use significantly increases acute kidney injury risk",
        "severity": 0.7
    },

    # --- Clindamycin (antibiotic) ---
    {
        "drug_a": "Clindamycin",
        "drug_b": "Erythromycin",
        "type": "reduced_clearance",
        "mechanism": "Both bind 50S ribosomal subunit antagonistically; therapeutic antagonism reduces efficacy",
        "severity": 0.5
    },
    {
        "drug_a": "Clindamycin",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Clindamycin disrupts gut flora reducing vitamin K; potentiates warfarin effect",
        "severity": 0.45
    },

    # --- Nortriptyline (TCA) ---
    {
        "drug_a": "Nortriptyline",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2D6 raising nortriptyline to toxic levels; cardiac arrhythmia risk",
        "severity": 0.65
    },
    {
        "drug_a": "Nortriptyline",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "TCA plus MAOI — potentially fatal serotonin syndrome and hypertensive crisis; contraindicated",
        "severity": 0.9
    },
    {
        "drug_a": "Nortriptyline",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "TCA plus benzodiazepine causes additive sedation and respiratory depression",
        "severity": 0.55
    },
    {
        "drug_a": "Nortriptyline",
        "drug_b": "Diphenhydramine",
        "type": "anticholinergic_burden",
        "mechanism": "Both high anticholinergic; additive dry mouth, urinary retention, confusion, delirium in elderly",
        "severity": 0.55
    },

    # --- Ranitidine/Famotidine (H2 blockers) ---
    {
        "drug_a": "Famotidine",
        "drug_b": "Clopidogrel",
        "type": "reduced_clearance",
        "mechanism": "H2 blocker may mildly reduce clopidogrel activation (less than PPIs); preferred alternative",
        "severity": 0.2
    },
    {
        "drug_a": "Famotidine",
        "drug_b": "Dasatinib",
        "type": "reduced_clearance",
        "mechanism": "H2 blockers raise gastric pH reducing dasatinib absorption and efficacy",
        "severity": 0.55
    },

    # --- Dasatinib (tyrosine kinase inhibitor) ---
    {
        "drug_a": "Dasatinib",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "PPIs raise gastric pH reducing dasatinib solubility and absorption; therapeutic failure",
        "severity": 0.65
    },

    # --- Imatinib (tyrosine kinase inhibitor) ---
    {
        "drug_a": "Imatinib",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Imatinib inhibits CYP3A4 raising simvastatin levels; myopathy risk",
        "severity": 0.55
    },
    {
        "drug_a": "Imatinib",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Imatinib inhibits CYP2C9 and CYP3A4 raising warfarin levels; switch to LMWH recommended",
        "severity": 0.6
    },

    # --- Methotrexate + expanded ---
    {
        "drug_a": "Methotrexate",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "PPIs inhibit renal tubular secretion of methotrexate increasing toxic accumulation",
        "severity": 0.55
    },

    # --- Flecainide (antiarrhythmic) ---
    {
        "drug_a": "Flecainide",
        "drug_b": "Amiodarone",
        "type": "reduced_clearance",
        "mechanism": "Amiodarone inhibits CYP2D6 raising flecainide levels; proarrhythmic toxicity risk",
        "severity": 0.65
    },
    {
        "drug_a": "Flecainide",
        "drug_b": "Fluoxetine",
        "type": "reduced_clearance",
        "mechanism": "Fluoxetine inhibits CYP2D6 raising flecainide levels; cardiac arrhythmia risk",
        "severity": 0.6
    },
    {
        "drug_a": "Flecainide",
        "drug_b": "Verapamil",
        "type": "additive_hypotension",
        "mechanism": "Both have negative inotropic effects; combined use may cause heart failure and severe bradycardia",
        "severity": 0.7
    },

    # --- Minocycline (antibiotic) ---
    {
        "drug_a": "Minocycline",
        "drug_b": "Isotretinoin",
        "type": "hepatotoxicity",
        "mechanism": "Both can cause intracranial hypertension (pseudotumor cerebri); combination is contraindicated",
        "severity": 0.8
    },
    {
        "drug_a": "Minocycline",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Tetracyclines disrupt gut flora and may impair vitamin K synthesis; potentiates warfarin",
        "severity": 0.45
    },

    # --- Pregnenolone / DHEA (supplement) ---
    {
        "drug_a": "DHEA",
        "drug_b": "Tamoxifen",
        "type": "reduced_clearance",
        "mechanism": "DHEA is a hormonal precursor that may counteract tamoxifen anti-estrogen effects",
        "severity": 0.5
    },

    # --- Iron Supplements ---
    {
        "drug_a": "Ferrous Sulfate",
        "drug_b": "Levothyroxine",
        "type": "reduced_clearance",
        "mechanism": "Iron chelates levothyroxine in the GI tract reducing absorption by up to 75%; separate by 4 hours",
        "severity": 0.55
    },
    {
        "drug_a": "Ferrous Sulfate",
        "drug_b": "Ciprofloxacin",
        "type": "reduced_clearance",
        "mechanism": "Iron chelates fluoroquinolones reducing antibiotic absorption and efficacy; separate by 2 hours",
        "severity": 0.55
    },

    # --- Calcium Carbonate (supplement/antacid) ---
    {
        "drug_a": "Calcium Carbonate",
        "drug_b": "Levothyroxine",
        "type": "reduced_clearance",
        "mechanism": "Calcium chelates levothyroxine reducing absorption; separate by 4 hours",
        "severity": 0.5
    },
    {
        "drug_a": "Calcium Carbonate",
        "drug_b": "Ciprofloxacin",
        "type": "reduced_clearance",
        "mechanism": "Calcium chelates fluoroquinolones reducing antibiotic absorption; separate by 2 hours",
        "severity": 0.5
    },
    {
        "drug_a": "Calcium Carbonate",
        "drug_b": "Alendronate",
        "type": "reduced_clearance",
        "mechanism": "Calcium interferes with alendronate absorption; take alendronate on empty stomach 30 minutes before calcium",
        "severity": 0.5
    },

    # --- Alendronate (bisphosphonate for osteoporosis) ---
    {
        "drug_a": "Alendronate",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "Bisphosphonate plus NSAID dramatically increases GI ulceration and esophageal erosion risk",
        "severity": 0.55
    },
    {
        "drug_a": "Alendronate",
        "drug_b": "Prednisone",
        "type": "reduces_kidney_function",
        "mechanism": "Corticosteroids cause bone loss counteracting bisphosphonate effect; GI toxicity additive",
        "severity": 0.4
    }
];
