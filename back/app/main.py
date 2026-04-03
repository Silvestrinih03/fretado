from fastapi import FastAPI
from app.api.routes.register import router as register_router

app = FastAPI(title="Fretado API")

app.include_router(register_router)

@app.get("/")
def root():
    return {"message": "Fretado API is running"}