# English to Turkish Translation API

This is a FastAPI application that translates English text to Turkish using a fine-tuned Hugging Face model.


## Requirements

- Python 3.7 or higher
- FastAPI
- Uvicorn
- Transformers
- Torch
- SentencePiece

## Installation

1. **Set up a Virtual Environment**:

   Create a new directory for the project and navigate into it. Then, set up a virtual environment to manage dependencies.
   <br>```mkdir fastapi-translation```<br>
   <br>```cd fastapi-translation```<br>
   <br>```python3 -m venv venv```<br>
   <br>```source venv/bin/activate  # On Windows: venv\Scripts\activate```<br>


3. **Install Required Libraries**:

   Use pip to install the necessary packages for the application.
  <br> ```pip install fastapi uvicorn transformers torch sentencepiece```<br>

## Running the Application

To run the FastAPI application, use the following command in your terminal:

<br>```uvicorn main:app --reload```<br>
Once the server starts, you should see output indicating it is running, typically at http://127.0.0.1:8000.

Testing the API
Using cURL
Open a new terminal window and run the following cURL command to test the translation API:


<br>```curl -X POST "http://127.0.0.1:8000/translate/" -H "Content-Type: application/json" -d '{"text":"Hello, how are you?"}'```<br>
Expected Response
You should receive a response like this:

{
  "translated_text": "Merhaba, nasılsın?"
}
