# test_translation.py
import requests
import sounddevice as sd
import soundfile as sf
import io
import numpy as np


def translate_and_play(text):
    # Send request to the API
    print("Translating and generating speech...")
    response = requests.post(
        "http://127.0.0.1:8000/translate-and-speak/",
        json={"text": text}
    )

    if response.status_code == 200:
        # Load the audio data
        print("Playing audio...")
        audio_data, samplerate = sf.read(io.BytesIO(response.content))

        # Play the audio
        sd.play(audio_data, samplerate)
        sd.wait()  # Wait until audio is finished playing
    else:
        print(f"Error: {response.status_code}")
        print(response.text)


if __name__ == "__main__":
    while True:
        # Example usage
        text = input("\nEnter text to translate and speak (or 'q' to quit): ")
        if text.lower() == 'q':
            break
        translate_and_play(text)
