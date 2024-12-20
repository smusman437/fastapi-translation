

from fastapi import FastAPI, Response
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, VitsModel,  AutoProcessor
import torch

import scipy.io.wavfile as wavfile
import io
import numpy as np

app = FastAPI()

# Translation model setup
model_name = "ckartal/english-to-turkish-finetuned-model"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSeq2SeqLM.from_pretrained(model_name)

# TTS model setup - using Facebook's NVIDIA/tts_models for Turkish
tts_model_name = "facebook/mms-tts-tur"
processor = AutoProcessor.from_pretrained(tts_model_name)
tts_model = VitsModel.from_pretrained(tts_model_name)


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


@app.post("/translate-and-speak/")
async def translate_and_speak(request: TranslationRequest):
    # First translate the text
    inputs = tokenizer.encode(request.text, return_tensors="pt")
    with torch.no_grad():
        outputs = model.generate(
            inputs, max_length=40, num_beams=4, early_stopping=True)
    translated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

    # Then convert to speech
    inputs = processor(text=translated_text, return_tensors="pt")

    with torch.no_grad():
        speech = tts_model(
            input_ids=inputs["input_ids"],
            attention_mask=inputs["attention_mask"],
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
