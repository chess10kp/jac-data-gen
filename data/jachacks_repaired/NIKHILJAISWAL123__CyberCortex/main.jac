import from graph {CyberGraph}
import from agents {ScannerWalker, CoordinatorWalker}
import from fastapi {FastAPI, Request}
import from fastapi.responses {HTMLResponse, JSONResponse}
import from fastapi.middleware.cors {CORSMiddleware}
import uvicorn;
import os;

obj AppServer {
    has app: FastAPI = FastAPI(title="CyberCortex Jaclang Backend");
    has cg: CyberGraph = CyberGraph();

    def init {
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        );
        self.setup_routes();
    }

    def setup_routes {
        @self.app.get("/", response_class=HTMLResponse)
        def read_root() -> HTMLResponse {
            with open("index.html", "r") as f {
                return HTMLResponse(content=f.read(), status_code=200);
            }
        }

        @self.app.post("/api/scan")
        def run_scan() -> JSONResponse {
            scanner = ScannerWalker();
            self.cg.start_node spawn scanner;
            return JSONResponse(content={"status": "success", "results": scanner.scan_results});
        }
    }

    def run {
        uvicorn.run(self.app, host="0.0.0.0", port=8000);
    }
}

with entry {
    server = AppServer();
    server.run();
}
