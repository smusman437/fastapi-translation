
# test_translation.py
import requests
import sounddevice as sd
import soundfile as sf
import io
import numpy as np


def translate_and_play(text, speed_factor=0.8):  # Simple parameter definition
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

        # Play the audio at slower speed by adjusting the sample rate
        adjusted_samplerate = int(samplerate * speed_factor)
        print(f"Playing at {speed_factor*100}% speed...")
        sd.play(audio_data, adjusted_samplerate)
        sd.wait()  # Wait until audio is finished playing
    else:
        print(f"Error: {response.status_code}")
        print(response.text)


if __name__ == "__main__":
    # Set speed factor (0.8 = 80% speed, makes it slower)
    speed_factor = 0.7  # Made it a bit slower

    print(f"Speed set to {speed_factor*100}% of normal speed")
    while True:
        # Example usage
        text = input("\nEnter text to translate and speak (or 'q' to quit): ")
        if text.lower() == 'q':
            break
        translate_and_play(text, speed_factor)
