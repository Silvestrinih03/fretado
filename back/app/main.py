from fastapi import FastAPI
from app.api.routes.register import router as register_router
from app.api.routes.auth import router as auth_router
from app.api.routes.user import router as user_router
from app.api.routes.vehicle import router as vehicle_router
from app.api.routes.vehicle_catalog import router as vehicle_catalog_router
from app.api.routes.vehicle_type import router as vehicle_type_router
from app.api.routes.driver_license_category import router as driver_license_category_router
from app.api.routes.driver_document import router as driver_document_router

app = FastAPI(title="Fretado API")

app.include_router(register_router)
app.include_router(auth_router)
app.include_router(user_router)
app.include_router(vehicle_router)
app.include_router(vehicle_catalog_router)
app.include_router(vehicle_type_router)
app.include_router(driver_license_category_router)
app.include_router(driver_document_router)

@app.get("/")
def root():
    return {"message": "Fretado API is running"}
