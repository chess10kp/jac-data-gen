import from ..services.recognition { recognize_lego_frame, get_llm_color }
import from byllm.lib { Image }

def:pub CountdownApp() -> JsxElement {
    has analyzing: bool = False;
    has status: str = "Camera ready";
    has permission: str = "Idle";
    has camera_active: bool = False;
    has captured_frame: str = "";
    has active_name: str = "No result yet";
    has active_confidence: str = "";
    has active_notes: str = "Start the webcam and capture a snapshot to identify a LEGO part.";
    has active_part_id: str = "—";
    has active_years: str = "Unknown";
    has active_years_start: str = "";
    has active_years_end: str = "";
    has active_years_source: str = "BrickLink";
    has active_release_range: str = "Unknown";
    has active_known_colors: list = [];
    has active_known_colors_label: str = "Unknown";
    has active_known_colors_source: str = "BrickLink";
    has active_bricklink_url: str = "";
    has provider: str = "Brickognize";
    has payload_text: str = "image/png · 0 bytes";
    has candidate_text: str = "0 matches returned";
    has llm_predict_color: str = "Unknown";

    def get_video() -> any {
        return document.getElementById("scanner-video");
    }

    def get_canvas() -> any {
        return document.getElementById("scanner-canvas");
    }

    def normalize_known_colors(payload: any) -> list {
        if payload == None {
            return [];
        }

        if payload and payload.length != None {
            normalized = [];
            for item in payload {
                color_name = str(item).strip();
                if color_name != "" and color_name not in normalized {
                    normalized = normalized + [color_name];
                }
            }
            return normalized;
        }

        raw_text = str(payload).strip();
        if raw_text == "" {
            return [];
        }

        normalized_text = raw_text.replace(" / ", ",").replace("|", ",").replace(";", ",");
        colors = [];
        for piece in normalized_text.split(",") {
            color_name = piece.strip();
            if color_name != "" and color_name not in colors {
                colors = colors + [color_name];
            }
        }
        return colors;
    }

    def clear_stream() -> None {
        stream: any = globalThis.__legoScannerStream;
        if stream {
            for track in stream.getTracks() {
                track.stop();
            }
        }
        video = get_video();
        if video {
            try {
                video.pause();
            } except Exception {
            }
            video.srcObject = None;
        }
        globalThis.__legoScannerStream = None;
        camera_active = False;
    }

    async def start_camera() -> None {
        try {
            permission = "Requesting";
            status = "Requesting webcam access...";
            camera_active = False;

            media_devices: any = (navigator as any).mediaDevices;
            if not media_devices or not media_devices.getUserMedia {
                permission = "Unavailable";
                status = "This browser does not support webcam access";
                return;
            }

            clear_stream();

            video = get_video();
            if not video {
                permission = "Unavailable";
                status = "Video element not found";
                return;
            }

            video.muted = True;
            video.autoplay = True;
            video.playsInline = True;
            video.setAttribute("autoplay", "true");
            video.setAttribute("muted", "true");
            video.setAttribute("playsinline", "true");

            stream: any = await media_devices.getUserMedia({"video": True, "audio": False});
            if not stream {
                permission = "Unavailable";
                status = "Unable to create webcam stream";
                return;
            }

            tracks: any = stream.getVideoTracks();
            if not tracks or len(tracks) == 0 {
                clear_stream();
                permission = "Unavailable";
                status = "No video track available";
                return;
            }

            video.srcObject = stream;
            globalThis.__legoScannerStream = stream;

            try {
                await video.play();
            } except Exception {
            }

            permission = "Granted";
            camera_active = True;
            status = "Webcam active";
        } except Exception as e {
            clear_stream();
            permission = "Denied";
            status = "Unable to start webcam: " + str(e);
        }
    }

    def stop_camera() -> None {
        clear_stream();
        permission = "Stopped";
        status = "Camera stopped";
    }

    async def analyze_frame(frame_data: str) -> None {
        analyzing = True;
        status = "Analyzing snapshot...";
        try {
            result = await recognize_lego_frame(frame_data);
            if result and result["success"] {
                match_info = result["active_match"] or {};
                telemetry = result["telemetry"] or {};
                years_info = (match_info and match_info["years_released"]) or {};
                known_colors_info = (match_info and match_info["known_colors"]) or {};
                active_name = str((match_info and match_info["name"]) or "Unknown part");
                active_confidence = str((match_info and match_info["confidence"]) or "");
                active_notes = str((match_info and match_info["notes"]) or "Recognition complete.");
                active_part_id = str((match_info and match_info["specific_part_number"]) or (match_info and match_info["part_id"]) or "—");
                years_label = (years_info and years_info["label"]) or (match_info and match_info["years_released_label"]) or "Unknown";
                years_start = (years_info and years_info["start"]) or (match_info and match_info["years_released_start"]) or "";
                years_end = (years_info and years_info["end"]) or (match_info and match_info["years_released_end"]) or "";
                active_years = str(years_label);
                active_years_start = str(years_start);
                active_years_end = str(years_end);
                if years_start != "" and years_end != "" {
                    active_release_range = str((years_start == years_end) and years_start or (str(years_start) + " → " + str(years_end)));
                } elif years_start != "" {
                    active_release_range = str(years_start);
                } else {
                    active_release_range = "Unknown";
                }
                active_years_source = str((years_info and years_info["source"]) or (match_info and match_info["years_released_source"]) or "BrickLink");
                active_known_colors = normalize_known_colors((known_colors_info and known_colors_info["items"]) or (known_colors_info and known_colors_info["label"]) or []);
                active_known_colors_source = str((known_colors_info and known_colors_info["source"]) or "BrickLink");
                active_bricklink_url = str(match_info["bricklink_url"] or "");
                provider = str(telemetry["provider"] or "Brickognize");
                payload_text = str(telemetry["mime_type"] or "image/png") + " · " + str(telemetry["bytes"] or 0) + " bytes";
                candidate_text = str(telemetry["candidate_count"] or 0) + " matches returned";
                llm_predict_color = "Unknown";
                status = "Analysis complete";
            } else {
                status = str((result and result["error"]) or "Recognition failed");
            }
        } except Exception as e {
            status = "Recognition failed: " + str(e);
        }
        analyzing = False;
    }

    async def capture_frame() -> None {
        if analyzing {
            status = "Recognition already in progress";
            return;
        }
        video = get_video();
        canvas = get_canvas();
        if not video or not canvas {
            status = "Camera surface not ready";
            return;
        }
        if not video.srcObject or not camera_active {
            status = "Start the webcam first";
            return;
        }
        width = int(video.videoWidth or 640);
        height = int(video.videoHeight or 480);
        canvas.width = width;
        canvas.height = height;
        context = canvas.getContext("2d");
        if not context {
            status = "Unable to capture snapshot";
            return;
        }
        context.drawImage(video, 0, 0, width, height);
        frame_data = canvas.toDataURL("image/png");
        captured_frame = frame_data;
        await analyze_frame(frame_data);
        llm_predict_color = await get_llm_color(frame_data, active_known_colors);
    }

    return (
        <div className="mx-auto grid max-w-6xl gap-6 px-4 py-6 lg:grid-cols-[1.2fr_0.8fr]">
            <section className="rounded-3xl border border-border/90 bg-card/95 p-6 shadow-card backdrop-blur sm:p-8">
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                        <p className="text-sm font-medium tracking-wide text-sky-200">LEGO recognition</p>
                        <h1 className="mt-1 text-3xl font-semibold text-white sm:text-4xl">Minimal scanner</h1>
                    </div>
                    <div className="rounded-full border border-slate-600 bg-slate-900/80 px-3 py-1 text-sm font-medium text-slate-100">{permission}</div>
                </div>

                <p className="mt-4 max-w-2xl text-sm leading-6 text-slate-300">Use the webcam, capture a snapshot, and send the image to Brickognize for part recognition. After the piece is identified, BrickLink is used to look up the known color variants and release-year details for that part.</p>

                <div className="mt-6 overflow-hidden rounded-2xl border border-slate-700 bg-black shadow-inner shadow-black/30">
                    <div className="relative min-h-80 bg-neutral-950">
                        <video id="scanner-video" className="h-full min-h-80 w-full object-cover" autoPlay={True} muted={True} playsInline={True}></video>
                        {not camera_active and (<div className="absolute inset-0 flex items-center justify-center bg-black/60 px-6 text-center text-sm text-white/80">
                            Start the webcam to preview the live camera feed.
                        </div>)}
                    </div>
                </div>

                <canvas id="scanner-canvas" className="hidden"></canvas>

                <div className="mt-5 flex flex-wrap gap-3">
                    <button className="rounded-xl bg-primary px-4 py-2.5 text-sm font-semibold text-primary-foreground transition hover:bg-sky-300 focus:outline-none focus:ring-2 focus:ring-sky-300/40" onClick={start_camera}>Start webcam</button>
                    <button className="rounded-xl border border-slate-600 bg-slate-900/80 px-4 py-2.5 text-sm font-medium text-slate-100 transition hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-sky-300/30 disabled:cursor-not-allowed disabled:opacity-60" onClick={capture_frame} disabled={analyzing or (not camera_active)}>{analyzing and "Analyzing..." or "Capture snapshot"}</button>
                    <button className="rounded-xl border border-slate-600 bg-slate-950/80 px-4 py-2.5 text-sm font-medium text-slate-200 transition hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-sky-300/30" onClick={stop_camera}>Stop webcam</button>
                </div>

                <div className="mt-4 rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-slate-300">
                    <span className="mr-2 font-semibold text-white">Status:</span>{status}
                </div>
            </section>

            <section className="flex flex-col gap-6">
                <div className="rounded-3xl border border-border/90 bg-card/95 p-6 shadow-soft backdrop-blur">
                    <p className="text-sm font-medium tracking-wide text-sky-200">Result</p>
                    <h2 className="mt-1 text-2xl font-semibold text-white">Top match</h2>
                    <div className="grid w-full mt-4 rounded-2xl border border-slate-700 bg-slate-950/70 p-4">
                        <div className="flex items-start justify-between gap-3">
                            <div>
                                <p className="grid w-full grid-cols-[1fr_auto] items-center text-xs uppercase tracking-[0.2em] text-slate-400">
                                    <span>Detected part</span>
                                    {active_confidence and (<span className="rounded-full border border-slate-600 bg-slate-900/90 px-3 py-1 text-sm font-semibold normal-case tracking-normal text-white">
                                        {active_confidence}
                                    </span>)}
                                </p>
                                
                                <h3 className="mt-1 text-lg font-semibold text-white">{active_name}</h3>
                                <div className="mt-3 flex flex-wrap gap-2">
                                    <div className="inline-flex items-center gap-2 rounded-full border border-violet-400/30 bg-violet-400/10 px-3 py-1.5 text-sm text-violet-100">
                                        <span className="text-[11px] font-medium uppercase tracking-wide text-violet-200/80">Years</span>
                                        <span className="font-semibold text-violet-50">{str(active_years)}</span>
                                    </div>
                                    <div className="inline-flex items-center gap-2 rounded-full border border-violet-400/30 bg-violet-400/10 px-3 py-1.5 text-sm text-violet-100">
                                        <span className="text-[11px] font-medium uppercase tracking-wide text-violet-200/80">Color Estimate:</span>
                                        <span className="font-semibold text-violet-50"> {llm_predict_color}</span>
                                    </div>
                                    
                                </div>
                                <div className="mt-2 flex flex-wrap gap-4 text-xs text-slate-400">
                                </div>
                                {len(active_known_colors) > 0 and (<div className="mt-4 rounded-2xl border border-cyan-400/20 bg-cyan-400/5 p-4">
                                    <div className="flex flex-wrap items-start justify-between gap-3">
                                        <div>
                                            <p className="text-xs uppercase tracking-[0.2em] text-cyan-200/80">BrickLink known colors</p>
                                            <p className="mt-1 text-sm text-slate-300">Available official color variants for this part.</p>
                                        </div>
                                        <div className="inline-flex items-center gap-2 rounded-full border border-cyan-400/25 bg-slate-950/60 px-3 py-1.5 text-xs font-semibold text-cyan-100">
                                            <span>{str(len(active_known_colors))} listed</span>
                                            <span className="h-1 w-1 rounded-full bg-cyan-200/70"></span>
                                        </div>
                                    </div>
                                    <div className="mt-4 flex flex-wrap gap-2.5">
                                        {len(active_known_colors) > 0 and ([<span key={color_name} className="inline-flex items-center rounded-full border border-cyan-300/30 bg-cyan-300/12 px-3.5 py-1.5 text-sm font-semibold text-cyan-50 shadow-sm shadow-cyan-950/20">{str(color_name)}</span> for color_name in active_known_colors])}
                                        {len(active_known_colors) == 0 and (<div className="w-full rounded-xl border border-dashed border-slate-600 bg-slate-950/50 px-3 py-3 text-sm text-slate-300">No known colors were returned from BrickLink.</div>)}
                                    </div>
                                </div>)}
                            </div>
                            
                        </div>
                        
                        <p className="mt-3 text-sm leading-6 text-slate-300">{active_notes}</p>
                        <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-2">
                            <div className="rounded-2xl border border-slate-700 bg-slate-900/80 p-4 text-sm text-slate-300">
                                <p className="font-medium text-white">Part ID</p>
                                <p className="mt-1 text-base font-semibold text-white">{str(active_part_id)}</p>
                                <p className="mt-1 text-xs text-slate-400">Catalog reference</p>
                            </div>
                            <div className="rounded-2xl border border-slate-700 bg-slate-900/80 p-4 text-sm text-slate-300">
                                <p className="font-medium text-white">Release range</p>
                                <p className="mt-1 text-base font-semibold text-white">{str(active_release_range)}</p>
                                <p className="mt-1 text-xs text-slate-400">Start and end years</p>
                            </div>
                        </div>
                        <div className="mt-4 rounded-2xl border border-slate-700 bg-slate-900/80 p-4">
                            <div className="flex flex-wrap items-center justify-between gap-3">
                                <div>
                                    <p className="text-xs uppercase tracking-[0.2em] text-slate-400">Detection details</p>
                                    <p className="mt-1 text-sm text-slate-300">Recognition provider, release metadata, and catalog lookup for the detected LEGO part.</p>
                                </div>
                                <span className="rounded-full border border-slate-600 bg-slate-950/80 px-3 py-1 text-xs font-medium text-slate-100">{provider}</span>
                            </div>
                            <div className="mt-4 grid gap-3 sm:grid-cols-2">
                                <div className="rounded-2xl bg-slate-950/70 p-4 text-sm text-slate-300">
                                    <p className="font-medium text-white">Recognition summary</p>
                                    <p className="mt-2">Confidence: <span className="font-semibold text-white">{active_confidence}</span></p>
                                    <p className="mt-1">Known colors source: <span className="font-semibold text-white">{active_known_colors_source}</span></p>
                                </div>
                                <div className="rounded-2xl bg-slate-950/70 p-4 text-sm text-slate-300">
                                    <p className="font-medium text-white">Catalog summary</p>
                                    <p className="mt-2">Years source: <span className="font-semibold text-white">{active_years_source}</span></p>
                                    <p className="mt-1">BrickLink lookup: <span className="font-semibold text-white">{active_bricklink_url != "" and "Available" or "Unavailable"}</span></p>
                                </div>
                            </div>
                            {active_bricklink_url != "" and (<a href={active_bricklink_url} target="_blank" rel="noreferrer" className="mt-4 inline-flex rounded-xl border border-slate-600 bg-slate-950/80 px-4 py-2 text-sm font-medium text-slate-100 transition hover:bg-slate-800">
                                Open on BrickLink
                            </a>)}
                        </div>
                    </div>
                </div>

                <div className="rounded-3xl border border-border/90 bg-card/95 p-6 shadow-soft backdrop-blur">
                    <p className="text-sm font-medium tracking-wide text-sky-200">Snapshot</p>
                    <h2 className="mt-1 text-2xl font-semibold text-white">Latest capture</h2>
                    <div className="mt-4 overflow-hidden rounded-2xl border border-slate-700 bg-slate-950/70">
                        {captured_frame != "" and (<img src={captured_frame} alt="Captured LEGO frame" className="h-64 w-full object-cover" />)}
                        {captured_frame == "" and (<div className="flex h-64 items-center justify-center px-6 text-center text-sm text-slate-300">No snapshot captured yet.</div>)}
                    </div>
                    <div className="mt-4 grid gap-3">
                        <div className="rounded-2xl border border-slate-700 bg-slate-900/80 p-4 text-sm text-slate-300">
                            <p className="font-medium text-white">Provider</p>
                            <p className="mt-1">{provider}</p>
                        </div>
                        <div className="rounded-2xl border border-slate-700 bg-slate-900/80 p-4 text-sm text-slate-300">
                            <p className="font-medium text-white">Payload</p>
                            <p className="mt-1">{payload_text}</p>
                        </div>
                        <div className="rounded-2xl border border-slate-700 bg-slate-900/80 p-4 text-sm text-slate-300">
                            <p className="font-medium text-white">Matches</p>
                            <p className="mt-1">{candidate_text}</p>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
}
