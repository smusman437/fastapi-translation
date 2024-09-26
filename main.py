

from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import torch

app = FastAPI()

model_name = "ckartal/english-to-turkish-finetuned-model"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSeq2SeqLM.from_pretrained(model_name)


class TranslationRequest(BaseModel):
    text: str


@app.post("/translate/")
async def translate(request: TranslationRequest):
    inputs = tokenizer.encode(request.text, return_tensors="pt")
    with torch.no_grad():
        outputs = model.generate(
            inputs, max_length=40, num_beams=4, early_stopping=True)
    translated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return {"translated_text": translated_text}
