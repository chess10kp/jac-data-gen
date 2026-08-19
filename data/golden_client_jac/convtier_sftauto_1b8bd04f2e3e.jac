def get_ages(api_endpoints: Any) -> object {
    ages = [];
    for endpoint in api_endpoints {
        response = requests.get(endpoint);
        data = response.json();
        age = data['data']['age'];
        ages.append(age);
        friends = data['data']['friends'];
        for friend in friends {
            age = friend['age'];
            ages.append(age);
        }
    }
    return ages;
}



with entry {
    print(get_ages([]));
}
