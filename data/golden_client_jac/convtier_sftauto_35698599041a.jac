def extract_domain_name(url: Any) -> object {
    try {
        parsed_url = urlparse(url);
        domain = (
            parsed_url.netloc.split(".")[-2] + "." + parsed_url.netloc.split(".")[-1]
        );
        return domain;
    } except Exception as e {
        return "";
    }
}



with entry {
    print(extract_domain_name('hello'));
}
