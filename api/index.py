# api/index.py
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi import Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, Response
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, VitsModel, AutoProcessor
import torch
import scipy.io.wavfile as wavfile
import io
import numpy as np

app = FastAPI()

# Global variables for models (loaded once)
tokenizer = None
model = None
processor = None
tts_model = None


def load_models():
    """Load models only when needed (lazy loading)"""
    global tokenizer, model, processor, tts_model

    if tokenizer is None:
        # Translation model setup
        model_name = "ckartal/english-to-turkish-finetuned-model"
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        model = AutoModelForSeq2SeqLM.from_pretrained(model_name)

        # TTS model setup
        tts_model_name = "facebook/mms-tts-tur"
        processor = AutoProcessor.from_pretrained(tts_model_name)
        tts_model = VitsModel.from_pretrained(tts_model_name)


class TranslationRequest(BaseModel):
    text: str


templates = Jinja2Templates(directory="templates")


@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/translate/")
async def translate(request: TranslationRequest):
    load_models()  # Load models on first request

    inputs = tokenizer.encode(request.text, return_tensors="pt")
    with torch.no_grad():
        outputs = model.generate(
            inputs, max_length=40, num_beams=4, early_stopping=True)
    translated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return {"translated_text": translated_text}


@app.post("/translate-and-speak/")
async def translate_and_speak(request: TranslationRequest):
    load_models()  # Load models on first request

    # First translate the text
    inputs = tokenizer.encode(request.text, return_tensors="pt")
    with torch.no_grad():
        outputs = model.generate(
            inputs, max_length=40, num_beams=4, early_stopping=True)
    translated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

    # Then convert to speech
    tts_inputs = processor(text=translated_text, return_tensors="pt")

    with torch.no_grad():
        speech = tts_model(
            input_ids=tts_inputs["input_ids"],
            attention_mask=tts_inputs["attention_mask"],
            return_dict=False,
        )[0]

    # Convert speech tensor to audio file
    speech = speech.squeeze().numpy()

    # Normalize audio
    speech = speech / np.abs(speech).max()
    # Convert to 16-bit PCM
    speech = (speech * 32767).astype(np.int16)

    # Save to bytes buffer
    buffer = io.BytesIO()
    wavfile.write(buffer, 22050, speech)  # 22050 is the sampling rate
    buffer.seek(0)

    return Response(
        content=buffer.getvalue(),
        media_type="audio/wav"
    )

# Vercel serverless handler


def handler(event, context):
    return app(event, context)
