import asyncio
import sys

# We'll keep this patch as a safeguard, but the new structure makes it less critical.
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

import os
import base64
from dotenv import load_dotenv
from fastapi import FastAPI, Request, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, HttpUrl
# --- CHANGE 1: Import the SYNCHRONOUS version of Playwright ---
from playwright.sync_api import sync_playwright
from openai import AsyncOpenAI

load_dotenv()

app = FastAPI()
client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

class URLPair(BaseModel):
    url_a: HttpUrl
    url_b: HttpUrl

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/", response_class=HTMLResponse)
async def serve_frontend(request: Request):
    with open("static/index.html") as f:
        return HTMLResponse(content=f.read(), status_code=200)

# --- CHANGE 2: Make this a REGULAR function (def, not async def) ---
def run_playwright_and_get_screenshots(url_a: str, url_b: str) -> tuple[bytes, bytes]:
    """This function is now synchronous and will be run in a separate thread."""
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        page.set_viewport_size({"width": 1920, "height": 1080})
        
        page.goto(url_a, wait_until="networkidle")
        screenshot_a_bytes = page.screenshot(full_page=True)
        
        page.goto(url_b, wait_until="networkidle")
        screenshot_b_bytes = page.screenshot(full_page=True)
        
        browser.close()
        return screenshot_a_bytes, screenshot_b_bytes

# --- Main API Endpoint (no changes here) ---
@app.post("/analyze")
async def analyze_urls(payload: URLPair):
    try:
        # Now, asyncio.to_thread is being used correctly with a synchronous function.
        screenshot_a_bytes, screenshot_b_bytes = await asyncio.to_thread(
            run_playwright_and_get_screenshots, str(payload.url_a), str(payload.url_b)
        )

        base64_image_a = base64.b64encode(screenshot_a_bytes).decode("utf-8")
        base64_image_b = base64.b64encode(screenshot_b_bytes).decode("utf-8")

        response = await client.chat.completions.create(
            model="gpt-4-turbo",
            messages=[
                {
                    "role": "system",
                    "content": "You are an expert Quality Assurance (QA) Analyst. Your task is to analyze two screenshots of a webpage, one 'before' (Image A) and one 'after' (Image B), and provide a detailed report of the visual differences. Focus on layout, content, and styling changes. Identify potential bugs or visual regressions in the 'after' image. Structure your response in clear, concise Markdown."
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Please analyze the visual differences between these two webpage screenshots. Image A is the 'before' state, and Image B is the 'after' state. Provide a summary of changes and flag any potential visual bugs in Image B."
                        },
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/png;base64,{base64_image_a}"}
                        },
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/png;base64,{base64_image_b}"}
                        }
                    ]
                }
            ],
            max_tokens=1024,
        )
        
        ai_analysis = response.choices[0].message.content
        return {"analysis": ai_analysis}

    except Exception as e:
        print(f"An error occurred: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"An internal error occurred. Could not process the request. Error: {str(e)}"
        )