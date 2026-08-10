"""Creates dictionary to rename variables for summary statistics table.

    :return:            dic
    """
def dictionary_table1() -> object {
    dic = {
        "gewinn_norm": "Rank improvement (normalized)",
        "listenplatz_norm": "Initial list rank (normalized)",
        "age": "Age",
        'non_university_phd': "High school",
        'university': 'University',
        'phd': 'Phd',
        'architect': 'Architect',
        'businessmanwoman': "Businesswoman/-man",
        'engineer': "Engineer",
        'lawyer': "Lawyer",
        'civil_administration': "Civil administration",
        "teacher": "Teacher",
        'employed': "Employed",
        'selfemployed': "Self-employed",
        "student": "Student",
        'retired': "Retired",
        'housewifehusband': "Housewife/-husband"
    };
    return dic;
}