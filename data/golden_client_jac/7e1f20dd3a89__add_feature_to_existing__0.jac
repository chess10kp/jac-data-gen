def embed(text: str) -> object {
        client = OpenAI(api_key=self.api_key);
        return client.embeddings.create(model="text-embedding-3-small", input=text);
    }
