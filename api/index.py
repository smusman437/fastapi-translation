# api/index.py
from pathlib import Path

from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi import Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, Response
from pydantic import BaseModel
import httpx
from mangum import Mangum

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


# Templates path: project root (parent of api/) so it works on Vercel serverless
BASE_DIR = Path(__file__).resolve().parent.parent
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))


@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/translate/")
async def translate(request: TranslationRequest):
    """Simple rule-based or API-based translation for demo purposes"""
    try:
        # Option 1: Use a free translation API like MyMemory
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.mymemory.translated.net/get?q={request.text}&langpair=en|tr",
                timeout=10.0
            )

            if response.status_code == 200:
                result = response.json()
                translated_text = result["responseData"]["translatedText"]
                return {"translated_text": translated_text}
            else:
                # Fallback: Simple word replacement (for demo)
                simple_translations = {
                    "hello": "merhaba",
                    "goodbye": "hoşçakal",
                    "thank you": "teşekkür ederim",
                    "yes": "evet",
                    "no": "hayır",
                    "please": "lütfen",
                    "sorry": "özür dilerim"
                }

                text = request.text.lower()
                for en, tr in simple_translations.items():
                    text = text.replace(en, tr)

                return {"translated_text": text}

    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Translation error: {str(e)}")


@app.post("/translate-and-speak/")
async def translate_and_speak(request: TranslationRequest):
    """Translate and return text for client-side TTS"""
    try:
        # Get translation
        translation_response = await translate(request)
        translated_text = translation_response["translated_text"]

        # Return a simple audio response (you could use Web Speech API on frontend)
        # For now, return the text and let the frontend handle TTS
        return {"translated_text": translated_text, "audio_url": None}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

# Vercel serverless handler: Mangum adapts Lambda-style (event, context) to ASGI for FastAPI
handler = Mangum(app, lifespan="off")
