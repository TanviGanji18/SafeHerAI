"""
SafeHer AI - FastAPI Main Application
=====================================
Application entrypoint configuring the FastAPI application, CORS policies,
exception handlers, and route controllers.
"""

import os
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.exceptions import RequestValidationError

from .api.routes import router as api_router
from .services.route_service import RouteSafetyService

# Create FastAPI application
app = FastAPI(
    title="SafeHer AI – Women Safety & Route Recommendation API",
    description=(
        "SafeHer AI is an analytical women-safety and safer route recommendation system "
        "for Hyderabad, India. Evaluates travel routes using genuine spatial infrastructure "
        "(police stations, hospitals, public transit, accident black spots) and official "
        "Hyderabad City Police annual crime review statistics."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ==============================================================================
# CORS Configuration
# ==============================================================================
# Development origins permitted to communicate with this backend.
# In production, this should be restricted strictly to verified mobile/web domains.
DEVELOPMENT_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:8080",
    "http://10.0.2.2",         # Android Studio emulator host loopback
    "http://10.0.2.2:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=DEVELOPMENT_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


# ==============================================================================
# Exception Handlers
# ==============================================================================
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """
    Returns clean, structured JSON validation errors without exposing internal
    framework internals or filesystem traces.
    """
    errors = []
    for err in exc.errors():
        field = " -> ".join(str(loc) for loc in err.get("loc", []))
        msg = err.get("msg", "Invalid value")
        errors.append({"field": field, "message": msg})

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "message": "The supplied route request contains invalid or malformed data.",
            "details": errors,
        },
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """
    Catches unhandled server exceptions and returns sanitized JSON responses
    preventing disclosure of Python stack traces or file paths.
    """
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal Server Error",
            "message": "An unexpected error occurred during processing. Please verify request parameters.",
        },
    )


# ==============================================================================
# Startup Pre-warming
# ==============================================================================
@app.on_event("startup")
async def startup_event():
    """
    Pre-warms the spatial data loader at startup so that verified datasets
    are loaded into memory before the first user request arrives.
    """
    try:
        RouteSafetyService.get_scorer()
    except Exception as e:
        print(f"[SafeHer AI] Warning during spatial data initialization: {e}")


# ==============================================================================
# Route Registration
# ==============================================================================
app.include_router(api_router)

STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(STATIC_DIR):
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/", include_in_schema=False)
async def root():
    """Serves the interactive SafeHer AI web client."""
    index_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {
        "service": "SafeHer AI Backend API",
        "documentation": "/docs",
        "health_check": "/health",
        "score_endpoint": "/api/v1/safety/score",
        "routes_plan": "/api/v1/routes/plan",
    }


@app.get("/app", include_in_schema=False)
async def web_app():
    """Direct route to the interactive web client."""
    index_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {"error": "Web application interface not found."}
