import from byllm.lib { Model, ModelPool }
import os;

glob llm = ModelPool(
    models=[
        Model(model_name="gemini/gemini-2.5-flash", api_key=os.getenv("KEY_1", "")),
        Model(model_name="gemini/gemini-2.5-flash", api_key=os.getenv("KEY_2", "")),
        Model(model_name="gemini/gemini-2.5-flash", api_key=os.getenv("KEY_3", "")),
        Model(model_name="gemini/gemini-2.5-flash", api_key=os.getenv("KEY_4", "")),
    ],
    strategy="simple-shuffle",
);
