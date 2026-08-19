import from byllm.llm { BaseLLM }
import from openai { OpenAI }

obj MyCustomModel(BaseLLM) {
    has model_name: str;
    has api_key: str = "";
    has config: dict = {};

    def post_init() {
        super().__init__(model_name=self.model_name, **self.config);
    }

    def model_call_no_stream(params: dict) -> object {
        client = OpenAI(api_key=self.api_key);
        return client.chat.completions.create(**params);
    }

    def model_call_with_stream(params: dict) -> object {
        client = OpenAI(api_key=self.api_key);
        return client.chat.completions.create(stream=True, **params);
    }

    def embed(text: str) -> object {
        client = OpenAI(api_key=self.api_key);
        return client.embeddings.create(model="text-embedding-3-small", input=text);
    }
}
