from fastapi import FastAPI
from app.api.routes.register import router as register_router
from app.api.routes.auth import router as auth_router
from app.api.routes.user import router as user_router

app = FastAPI(title="Fretado API")

app.include_router(register_router)
app.include_router(auth_router)
app.include_router(user_router)

@app.get("/")
def root():
    return {"message": "Fretado API is running"}