# Root entrypoint for Vercel — FastAPI app (ASGI)
from pathlib import Path

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
import httpx

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class TranslationRequest(BaseModel):
    text: str


# CWD on Vercel is project root; templates live in ./templates
BASE_DIR = Path(__file__).resolve().parent
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))


@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/translate/")
async def translate(request: TranslationRequest):
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.mymemory.translated.net/get?q={request.text}&langpair=en|tr",
                timeout=10.0,
            )
            if response.status_code == 200:
                result = response.json()
                translated_text = result["responseData"]["translatedText"]
                return {"translated_text": translated_text}
        simple_translations = {
            "hello": "merhaba",
            "goodbye": "hoşçakal",
            "thank you": "teşekkür ederim",
            "yes": "evet",
            "no": "hayır",
            "please": "lütfen",
            "sorry": "özür dilerim",
        }
        text = request.text.lower()
        for en, tr in simple_translations.items():
            text = text.replace(en, tr)
        return {"translated_text": text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Translation error: {str(e)}")


@app.post("/translate-and-speak/")
async def translate_and_speak(request: TranslationRequest):
    try:
        translation_response = await translate(request)
        translated_text = translation_response["translated_text"]
        return {"translated_text": translated_text, "audio_url": None}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")
