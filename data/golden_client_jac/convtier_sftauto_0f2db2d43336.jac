def process_languages(languages: Any) -> object {
    features_set = `set();
    language_features = {};
    for (language, features) in languages {
        unique_features = `set(features);
        features_set.update(unique_features);
        language_features[language] = sorted(unique_features);
    }
    sorted_features = sorted(features_set);
    for language in language_features {
        language_features[language] = sorted(language_features[language]);
    }
    return language_features;
}



with entry {
    print(process_languages([]));
}
