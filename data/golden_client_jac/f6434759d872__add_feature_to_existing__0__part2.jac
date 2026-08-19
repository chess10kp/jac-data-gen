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
}

glob llm = MyCustomModel(model_name="my-custom-model");

def generate(prompt: str) -> str by llm();
def classify(prompt: str) -> str by llm();
