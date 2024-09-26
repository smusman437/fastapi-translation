from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline

# Initialize FastAPI
app = FastAPI()

# Load the English to Turkish translation model
model_name = "ckartal/english-to-turkish-finetuned-model"
translator = pipeline("translation_en_to_tr", model=model_name)

# Define request model


class TranslationRequest(BaseModel):
    text: str

# Define API endpoint


@app.post("/translate/")
async def translate(request: TranslationRequest):
    # Perform translation
    result = translator(request.text)
    return {"translated_text": result[0]['translation_text']}
