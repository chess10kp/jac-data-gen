"""Jac-authored webview preload telemetry runtime."""

import from 'electron' { ipcRenderer }

"""R: Install page-side telemetry capture for the browser webview.
M: Records rich interaction, DOM, network, session, and semantic page telemetry.
E: Sensitive field values are redacted before they leave the page context; only page-visible cookies/storage are accessible.
"""
def:pub installWebviewPreload() -> None {
    INPUT_DEBOUNCE_MS = 350;
    SCROLL_THROTTLE_MS = 450;
    MAX_ITEMS = 8;
    SENSITIVE_HINTS = [
        "password",
        "passcode",
        "token",
        "secret",
        "auth",
        "session",
        "cookie",
        "credit",
        "card",
        "ssn"
    ];

    pendingInputTimers = Reflect.construct(WeakMap, []);
    pendingScrollTimer = None;
    pendingMutationTimer = None;
    lastSemanticSignature = "";
    lastSessionSignature = "";
    lastScrollSignature = "";

    def truncateText(value: any, maxLen: any = 240) -> str {
        text = str(value or "").trim();  # jac:ignore[E1030]
        if len(text) > maxLen {  # jac:ignore[E1053]
            return text.slice(0, maxLen);  # jac:ignore[E1002,E1032]
        }
        return text;  # jac:ignore[E1002]
    }

    def containsSensitiveHint(value: any) -> bool {
        haystack = str(value or "").toLowerCase();  # jac:ignore[E1030]
        for hint in SENSITIVE_HINTS {
            if haystack.includes(hint) {  # jac:ignore[E1032]
                return True;
            }
        }
        return False;
    }

    def emitObservation(eventType: any, target: any = {}, value: any = "", meta: any = {}, extras: any = {}) -> None {
        payload = {
            "type": str(eventType or "unknown"),
            "url": window.location.href,
            "target": target,
            "value": str(value or ""),
            "meta": meta
        };

        if extras and typeof(extras) == "object" {
            extraKeys = Object.keys(extras);
            for key in extraKeys {
                payload[key] = extras[key];
            }
        }

        ipcRenderer.sendToHost("observation:event", payload);
    }

    def elementText(element: any) -> str {
        if not element {
            return "";
        }
        innerText = truncateText(element.innerText or element.textContent or "", 160);
        if innerText {
            return innerText;
        }
        fallback = element.getAttribute("value") or element.getAttribute("alt") or element.getAttribute("title") or "";
        return truncateText(fallback, 160);
    }

    def elementLabel(element: any) -> str {
        if not element {
            return "";
        }

        ariaLabel = truncateText(element.getAttribute("aria-label") or "", 140);
        if ariaLabel {
            return ariaLabel;
        }

        fieldId = truncateText(element.id or "", 120);
        if fieldId {
            labelNode = document.querySelector("label[for=\"" + CSS.escape(fieldId) + "\"]");  # jac:ignore[E1032,E1055]
            if labelNode {
                labelText = truncateText(labelNode.innerText or labelNode.textContent or "", 140);  # jac:ignore[E1030]
                if labelText {
                    return labelText;
                }
            }
        }

        parentLabel = element.closest("label");
        if parentLabel {
            parentText = truncateText(parentLabel.innerText or parentLabel.textContent or "", 140);
            if parentText {
                return parentText;
            }
        }

        return truncateText(element.getAttribute("placeholder") or "", 140);
    }

    def targetPath(element: any) -> str {
        if not element or not element.tagName {
            return "";
        }

        parts = [];
        current = element;
        depth = 0;

        while current and current.tagName and depth < 6 {
            part = str(current.tagName or "").toLowerCase();  # jac:ignore[E1030]
            if current.id {
                part = part + "#" + truncateText(current.id, 32);  # jac:ignore[E1055]
            } elif current.classList and current.classList.length > 0 {
                className = truncateText(current.classList[0] or "", 24);
                if className {
                    part = part + "." + className;  # jac:ignore[E1055]
                }
            }
            parts.unshift(part);  # jac:ignore[E1030]
            current = current.parentElement;
            depth = depth + 1;
        }

        return parts.join(" > ");  # jac:ignore[E1002,E1030]
    }

    def htmlExcerpt(element: any, maxLen: any = 1200) -> str {
        if not element or not element.outerHTML {
            return "";
        }
        return truncateText(element.outerHTML or "", maxLen);
    }

    def summarizeButtons(maxItems: any = MAX_ITEMS) -> any {
        results = [];
        nodes = document.querySelectorAll("button,[role='button'],input[type='submit'],input[type='button']");
        count = 0;
        for node in nodes {  # jac:ignore[E1022]
            if count >= maxItems {
                break;
            }
            text = elementText(node);
            label = elementLabel(node);
            if not text and not label {
                continue;
            }
            results.push({  # jac:ignore[E1030]
                "text": text,
                "label": label,
                "path": targetPath(node)
            });
            count = count + 1;
        }
        return results;
    }

    def summarizeLinks(maxItems: any = MAX_ITEMS) -> any {
        results = [];
        nodes = document.querySelectorAll("a[href]");
        count = 0;
        for node in nodes {  # jac:ignore[E1022]
            if count >= maxItems {
                break;
            }
            text = elementText(node);
            href = truncateText(node.href or "", 240);  # jac:ignore[E1032]
            if not text and not href {
                continue;
            }
            results.push({  # jac:ignore[E1030]
                "text": text,
                "href": href,
                "path": targetPath(node)
            });
            count = count + 1;
        }
        return results;
    }

    def summarizeForms(maxItems: any = 4) -> any {
        results = [];
        forms = document.querySelectorAll("form");
        count = 0;
        for form in forms {  # jac:ignore[E1022]
            if count >= maxItems {
                break;
            }
            fields = form.querySelectorAll("input,textarea,select");  # jac:ignore[E1032]
            submit = form.querySelector("button[type='submit'],input[type='submit'],button:not([type])");  # jac:ignore[E1032]
            labels = [];
            labelCount = 0;
            fieldNodes = form.querySelectorAll("input,textarea,select");  # jac:ignore[E1032]
            for field in fieldNodes {
                if labelCount >= 6 {
                    break;
                }
                label = elementLabel(field);
                if label {
                    labels.push(label);  # jac:ignore[E1030]
                    labelCount = labelCount + 1;
                }
            }
            results.push({  # jac:ignore[E1030]
                "action": truncateText(form.getAttribute("action") or "", 240),  # jac:ignore[E1032]
                "method": truncateText(form.getAttribute("method") or "GET", 16).toUpperCase(),  # jac:ignore[E1030,E1032]
                "field_count": Number(fields.length or 0),  # jac:ignore[E1032,E1053]
                "submit_text": elementText(submit),
                "labels": labels,
                "path": targetPath(form)
            });
            count = count + 1;
        }
        return results;
    }

    def describeTarget(element: any) -> any {
        if not element or not element.tagName {
            return {"tag": "", "text": "", "label": "", "path": ""};
        }
        return {
            "tag": str(element.tagName or "").toLowerCase(),  # jac:ignore[E1030]
            "id": truncateText(element.id or "", 120),
            "name": truncateText(element.getAttribute("name") or "", 120),
            "role": truncateText(element.getAttribute("role") or "", 80),
            "type": truncateText(element.getAttribute("type") or "", 40),
            "label": elementLabel(element),
            "text": elementText(element),
            "placeholder": truncateText(element.getAttribute("placeholder") or "", 140),
            "class_name": truncateText(element.className or "", 220),
            "path": targetPath(element)
        };
    }

    def isSensitiveTarget(target: any) -> bool {
        fieldType = str(target["type"] or "").toLowerCase();  # jac:ignore[E1030]
        if fieldType == "password" {
            return True;
        }

        haystack = str((target["label"] or "") + " " + (target["name"] or "") + " " + (target["id"] or "") + " " + (target["placeholder"] or "")).toLowerCase();  # jac:ignore[E1030]
        return containsSensitiveHint(haystack);
    }

    def safeValue(value: any, target: any) -> str {
        if isSensitiveTarget(target) {
            return "__redacted__";
        }
        return truncateText(value or "", 300);
    }

    def safeStorageKeys(storage: any, maxItems: any = MAX_ITEMS) -> any {
        results = [];
        if not storage or typeof(storage.length) == "undefined" {
            return results;
        }

        try {
            index = 0;
            while index < storage.length and index < maxItems {
                key = storage.key(index);
                if key {
                    results.push(truncateText(key, 120));  # jac:ignore[E1030]
                }
                index = index + 1;
            }
        } except Exception {
        }

        return results;
    }

    def safeStoragePreview(storage: any, maxItems: any = 6) -> any {
        results = [];
        keys = safeStorageKeys(storage, maxItems);

        for key in keys {
            previewValue = "";
            try {
                previewValue = storage.getItem(key);
            } except Exception {
                previewValue = "";
            }

            if containsSensitiveHint(key) {
                previewValue = "__redacted__";
            } else {
                previewValue = truncateText(previewValue, 120);
            }

            results.push({  # jac:ignore[E1030]
                "key": truncateText(key, 120),
                "value_preview": previewValue
            });
        }

        return results;
    }

    def cookieEntries() -> any {
        results = [];
        raw = str(document.cookie or "");
        if not raw {
            return results;
        }

        pieces = raw.split(";");
        count = 0;
        for piece in pieces {
            if count >= 10 {
                break;
            }
            trimmed = str(piece or "").trim();  # jac:ignore[E1030]
            if not trimmed {
                continue;
            }

            name = trimmed;
            value = "";
            if trimmed.includes("=") {  # jac:ignore[E1032]
                name = trimmed.split("=", 2)[0];  # jac:ignore[E1032]
                value = trimmed.split("=", 2)[1];  # jac:ignore[E1001,E1032]
            }

            preview = truncateText(value, 40);
            if containsSensitiveHint(name) {
                preview = "__redacted__";
            }
            results.push({  # jac:ignore[E1030]
                "name": truncateText(name, 80),
                "value_preview": preview
            });
            count = count + 1;
        }
        return results;
    }

    def captureViewport() -> any {
        docEl = document.documentElement or document.body;
        body = document.body or {};
        scrollX = Number(window.scrollX or window.pageXOffset or 0);
        scrollY = Number(window.scrollY or window.pageYOffset or 0);
        viewportWidth = Number(window.innerWidth or docEl.clientWidth or 0);
        viewportHeight = Number(window.innerHeight or docEl.clientHeight or 0);
        documentWidth = Number(Math.max(docEl.scrollWidth or 0, body.scrollWidth or 0, viewportWidth));  # jac:ignore[E1099]
        documentHeight = Number(Math.max(docEl.scrollHeight or 0, body.scrollHeight or 0, viewportHeight));  # jac:ignore[E1099]
        progress = 0;

        if documentHeight > viewportHeight and viewportHeight > 0 {
            progress = scrollY / (documentHeight - viewportHeight);  # jac:ignore[E1001]
        }

        if progress < 0 {
            progress = 0;
        }
        if progress > 1 {
            progress = 1;
        }

        return {
            "scroll_x": scrollX,
            "scroll_y": scrollY,
            "viewport_width": viewportWidth,
            "viewport_height": viewportHeight,
            "document_width": documentWidth,
            "document_height": documentHeight,
            "scroll_progress": Math.round(progress * 1000) / 1000
        };
    }

    def inferPageKind() -> str {
        title = str(document.title or "").toLowerCase();  # jac:ignore[E1030]
        textSample = "";
        if document.body {
            textSample = truncateText(document.body.innerText or "", 800).toLowerCase();  # jac:ignore[E1001,E1030]
        }

        if document.querySelector("input[type='password']") {
            if title.includes("login") or title.includes("sign in") or textSample.includes("sign in") or textSample.includes("log in") {  # jac:ignore[E1030,E1032]
                return "authentication";
            }
            return "secure_form";
        }

        if document.querySelector("input[name='q'],input[type='search'],textarea[name='q']") or title.includes("search") {  # jac:ignore[E1032]
            return "search";
        }

        if document.querySelector("form") {
            return "form_entry";
        }

        if document.querySelector("table") or document.querySelector("[role='grid']") {
            return "dashboard";
        }

        if textSample.includes("thank you") or textSample.includes("success") or textSample.includes("completed") {  # jac:ignore[E1030]
            return "confirmation";
        }

        if document.querySelector("article") or document.querySelector("main") {
            return "content";
        }

        return "generic";
    }

    def inferWorkflowStage(pageKind: any) -> str {
        if pageKind == "authentication" {
            return "login";
        }
        if pageKind == "search" {
            return "discovery";
        }
        if pageKind == "form_entry" or pageKind == "secure_form" {
            return "data_entry";
        }
        if pageKind == "confirmation" {
            return "confirmation";
        }
        if pageKind == "dashboard" {
            return "review";
        }
        if pageKind == "content" {
            return "consume";
        }
        return "browse";
    }

    def collectSemanticContext() -> any {
        pageKind = inferPageKind();
        forms = summarizeForms(2);
        buttons = summarizeButtons(6);
        primaryActions = [];
        for button in buttons {
            label = truncateText((button["label"] or button["text"] or ""), 80);
            if label {
                primaryActions.push(label);  # jac:ignore[E1030]
            }
        }

        headingValues = [];
        headingNodes = document.querySelectorAll("h1,h2,h3");
        headingCount = 0;
        for node in headingNodes {  # jac:ignore[E1022]
            if headingCount >= MAX_ITEMS {
                break;
            }
            text = truncateText(node.innerText or node.textContent or "", 120);  # jac:ignore[E1032]
            if text {
                headingValues.push(text);  # jac:ignore[E1030]
                headingCount = headingCount + 1;
            }
        }

        dominantForm = {};
        if len(forms) > 0 {
            dominantForm = forms[0];
        }

        return {
            "title": truncateText(document.title or "", 160),
            "page_kind": pageKind,
            "workflow_stage": inferWorkflowStage(pageKind),
            "headings": headingValues,
            "primary_actions": primaryActions,
            "form_count": Number(document.querySelectorAll("form").length or 0),  # jac:ignore[E1030,E1053]
            "interactive_count": Number(document.querySelectorAll("a,button,input,select,textarea,[role='button'],[role='link']").length or 0),  # jac:ignore[E1030,E1053]
            "has_modal": bool(document.querySelector("[role='dialog'],dialog,.modal,[aria-modal='true']")),
            "dominant_form": dominantForm
        };
    }

    def buildDomSnapshot(targetElement: any = None, includeFull: any = False) -> any {
        body = document.body;
        docEl = document.documentElement;
        activeElement = document.activeElement;

        snapshot = {
            "title": truncateText(document.title or "", 160),
            "ready_state": truncateText(document.readyState or "", 24),
            "target_path": targetPath(targetElement),
            "target_html": htmlExcerpt(targetElement, 900),
            "active_element": describeTarget(activeElement),
            "body_text_sample": "",
            "headings": collectSemanticContext()["headings"],
            "forms": summarizeForms(4),
            "buttons": summarizeButtons(8),
            "links": summarizeLinks(8),
            "interactive_counts": {
                "links": Number(document.querySelectorAll("a[href]").length or 0),  # jac:ignore[E1030,E1053]
                "buttons": Number(document.querySelectorAll("button,[role='button'],input[type='submit'],input[type='button']").length or 0),  # jac:ignore[E1030,E1053]
                "inputs": Number(document.querySelectorAll("input,textarea,select").length or 0),  # jac:ignore[E1030,E1053]
                "forms": Number(document.querySelectorAll("form").length or 0)  # jac:ignore[E1030,E1053]
            }
        };

        if body {
            snapshot["body_text_sample"] = truncateText(body.innerText or "", 900);
        }

        if includeFull {
            snapshot["document_html_excerpt"] = "";
            if docEl {
                snapshot["document_html_excerpt"] = truncateText(docEl.outerHTML or "", 2600);
            }
        }

        return snapshot;
    }

    def captureSessionState() -> any {
        localStorageKeys = safeStorageKeys(window.localStorage, 10);  # jac:ignore[E1030]
        sessionStorageKeys = safeStorageKeys(window.sessionStorage, 10);  # jac:ignore[E1030]
        localStorageCount = 0;
        sessionStorageCount = 0;
        if window.localStorage {  # jac:ignore[E1030]
            localStorageCount = Number(window.localStorage.length or 0);  # jac:ignore[E1001,E1030,E1053]
        }
        if window.sessionStorage {  # jac:ignore[E1030]
            sessionStorageCount = Number(window.sessionStorage.length or 0);  # jac:ignore[E1001,E1030,E1053]
        }

        return {
            "origin": truncateText(window.location.origin or "", 160),
            "pathname": truncateText(window.location.pathname or "", 240),
            "referrer": truncateText(document.referrer or "", 240),
            "history_length": Number(window.history.length or 0),
            "cookie_count": Number(cookieEntries().length or 0),
            "cookies": cookieEntries(),
            "local_storage": {
                "count": localStorageCount,
                "keys": localStorageKeys,
                "items": safeStoragePreview(window.localStorage, 6)  # jac:ignore[E1030]
            },
            "session_storage": {
                "count": sessionStorageCount,
                "keys": sessionStorageKeys,
                "items": safeStoragePreview(window.sessionStorage, 6)  # jac:ignore[E1030]
            },
            "navigator": {
                "user_agent": truncateText(navigator.userAgent or "", 240),
                "language": truncateText(navigator.language or "", 32),
                "platform": truncateText(navigator.platform or "", 64),
                "online": bool(navigator.onLine),
                "cookie_enabled": bool(navigator.cookieEnabled)  # jac:ignore[E1030]
            }
        };
    }

    def semanticSignature(semantic: any) -> str {
        return JSON.stringify({
            "title": semantic["title"] or "",
            "page_kind": semantic["page_kind"] or "",
            "workflow_stage": semantic["workflow_stage"] or "",
            "headings": semantic["headings"] or [],
            "primary_actions": semantic["primary_actions"] or []
        });
    }

    def sessionSignature(sessionState: any) -> str {
        localKeys = [];
        sessionKeys = [];
        if sessionState["local_storage"] {
            localKeys = sessionState["local_storage"]["keys"] or [];
        }
        if sessionState["session_storage"] {
            sessionKeys = sessionState["session_storage"]["keys"] or [];
        }
        return JSON.stringify({
            "cookie_count": sessionState["cookie_count"] or 0,
            "local_keys": localKeys,
            "session_keys": sessionKeys
        });
    }

    def emitSemanticEvent(trigger: any, captureScreenshot: any = False) -> None {
        semantic = collectSemanticContext();
        signature = semanticSignature(semantic);
        if signature == lastSemanticSignature and trigger != "submit" {
            return;
        }
        lastSemanticSignature = signature;

        emitObservation("page_semantic", {"role": "document", "label": "page_semantic"}, "", {
            "source": "page",
            "trigger": trigger
        }, {
            "semantic": semantic,
            "viewport": captureViewport(),
            "capture_screenshot": bool(captureScreenshot)
        });
    }

    def emitSessionStateEvent(trigger: any, kind: any = "") -> None {
        sessionState = captureSessionState();
        signature = sessionSignature(sessionState);
        if signature == lastSessionSignature and trigger != "storage_mutation" and trigger != "storage_event" {
            return;
        }
        lastSessionSignature = signature;

        emitObservation("session_state", {"role": "document", "label": "session_state"}, "", {
            "source": "page",
            "trigger": trigger,
            "kind": kind
        }, {
            "session_state": sessionState,
            "viewport": captureViewport()
        });
    }

    def emitRouteTelemetry(trigger: any) -> None {
        emitObservation("page_ready", {"role": "document", "label": "route_change"}, "", {
            "source": "page",
            "trigger": trigger
        }, {
            "viewport": captureViewport(),
            "dom_snapshot": buildDomSnapshot(document.body, True),
            "semantic": collectSemanticContext(),
            "session_state": captureSessionState(),
            "capture_screenshot": True
        });
        emitSemanticEvent(trigger, True);
        emitSessionStateEvent(trigger, "navigation");
    }

    def queueInputEvent(element: any) -> None {
        if not element or not element.tagName {
            return;
        }
        previousTimer = pendingInputTimers.get(element);
        if previousTimer {
            clearTimeout(previousTimer);  # jac:ignore[E1053]
        }
        timer = setTimeout(lambda {
            target = describeTarget(element);
            rawValue = "";
            if "value" in element {
                rawValue = element.value;
            }
            emitObservation("input", target, safeValue(rawValue, target), {
                "source": "page",
                "trigger": "debounced_input"
            }, {
                "viewport": captureViewport(),
                "dom_snapshot": buildDomSnapshot(element, False),
                "semantic": collectSemanticContext()
            });
            pendingInputTimers.delete(element);
        }, INPUT_DEBOUNCE_MS);
        pendingInputTimers.set(element, timer);
    }

    def requestBodyPreview(body: any) -> str {
        if body == None {
            return "";
        }
        if typeof(body) == "string" {
            return truncateText(body, 240);
        }
        if body and body.toString {
            return truncateText(body.toString(), 240);
        }
        return "";
    }

    def headerPreview(headers: any) -> any {
        results = [];
        if not headers {
            return results;
        }

        try {
            if headers.forEach {
                count = 0;
                headers.forEach(lambda (value: any, key: any) {
                    if count >= 10 {
                        return;
                    }
                    results.push({  # jac:ignore[E1030]
                        "name": truncateText(key, 80),
                        "value": truncateText(value, 160)
                    });
                    count = count + 1;
                });
                return results;
            }
        } except Exception {
        }

        rawText = truncateText(headers, 400);
        if rawText {
            results.push({"name": "raw", "value": rawText});  # jac:ignore[E1030]
        }
        return results;
    }

    def sameOriginUrl(urlValue: any) -> bool {
        try {
            parsed = Reflect.construct(URL, [str(urlValue or ""), window.location.href]);
            return parsed.origin == window.location.origin;
        } except Exception {
            return False;
        }
    }

    def emitNetworkEvent(kind: any, requestUrl: any, method: any, status: any, ok: any, durationMs: any, extras: any = {}) -> None {
        networkPayload = {
            "kind": str(kind or ""),
            "request_url": truncateText(requestUrl, 300),
            "method": truncateText(method or "GET", 20).toUpperCase(),  # jac:ignore[E1030]
            "status": Number(status or 0),
            "ok": bool(ok),
            "duration_ms": Number(durationMs or 0),
            "same_origin": bool(sameOriginUrl(requestUrl))
        };

        if extras and typeof(extras) == "object" {
            extraKeys = Object.keys(extras);
            for key in extraKeys {
                networkPayload[key] = extras[key];
            }
        }

        emitObservation("network", {
            "role": "network",
            "label": "network_" + str(kind or ""),
            "text": truncateText(method or "GET", 20) + " " + truncateText(requestUrl or "", 140)
        }, "", {
            "source": "page",
            "trigger": "network",
            "kind": str(kind or ""),
            "method": truncateText(method or "GET", 20),
            "request_url": truncateText(requestUrl or "", 300),
            "status": Number(status or 0),
            "ok": bool(ok),
            "duration_ms": Number(durationMs or 0),
            "error": truncateText(networkPayload["error"] or "", 160)
        }, {
            "network": networkPayload,
            "viewport": captureViewport()
        });
    }

    def instrumentFetch() -> None {
        if not window.fetch {
            return;
        }

        nativeFetch = window.fetch.bind(window);  # jac:ignore[E1031]

        async def wrappedFetch(resource: any, requestInit: any = None) -> any {
            startedAt = Date.now();
            requestUrl = "";
            method = "GET";
            requestHeaders = [];
            requestBody = "";

            if typeof(resource) == "string" {
                requestUrl = resource;
            } elif resource and resource.url {
                requestUrl = resource.url;
                if resource.method {
                    method = resource.method;
                }
                if resource.headers {
                    requestHeaders = headerPreview(resource.headers);
                }
            }

            if requestInit and typeof(requestInit) == "object" {
                if requestInit.method {
                    method = requestInit.method;
                }
                if requestInit.headers {
                    requestHeaders = headerPreview(requestInit.headers);
                }
                if "body" in requestInit {
                    requestBody = requestBodyPreview(requestInit.body);
                }
            }

            try {
                response = await nativeFetch(resource, requestInit);
                contentType = "";
                if response.headers {  # jac:ignore[E1032]
                    contentType = truncateText(response.headers.get("content-type") or "", 120);  # jac:ignore[E1032]
                }
                emitNetworkEvent("fetch", requestUrl, method, response.status, response.ok, Date.now() - startedAt, {  # jac:ignore[E1032]
                    "redirected": bool(response.redirected),  # jac:ignore[E1032]
                    "response_type": truncateText(response.type or "", 40),  # jac:ignore[E1032]
                    "content_type": contentType,
                    "request_headers": requestHeaders,
                    "response_headers": headerPreview(response.headers),  # jac:ignore[E1032]
                    "request_body_preview": requestBody
                });
                return response;
            } except Exception as err {
                emitNetworkEvent("fetch", requestUrl, method, 0, False, Date.now() - startedAt, {
                    "error": truncateText(err.message or err, 160),  # jac:ignore[E1030]
                    "request_headers": requestHeaders,
                    "request_body_preview": requestBody
                });
                return Promise.reject(err);
            }
        }

        window.fetch = wrappedFetch;
    }

    def instrumentResourceObserver() -> None {
        if typeof(PerformanceObserver) == "undefined" {
            return;
        }

        try {
            observer = Reflect.construct(PerformanceObserver, [lambda (list: any) {
                entries = list.getEntries() or [];
                for ent in entries {
                    if ent.entryType != "resource" {
                        continue;
                    }
                    initiatorType = truncateText(ent.initiatorType or "resource", 40);
                    emitNetworkEvent("resource", ent.name or "", initiatorType.toUpperCase(), 0, True, Number(ent.duration or 0), {  # jac:ignore[E1030]
                        "initiator_type": initiatorType,
                        "transfer_size": Number(ent.transferSize or 0),
                        "encoded_body_size": Number(ent.encodedBodySize or 0),
                        "decoded_body_size": Number(ent.decodedBodySize or 0),
                        "next_hop_protocol": truncateText(ent.nextHopProtocol or "", 40)
                    });
                }
            }]);
            observer.observe({"entryTypes": ["resource"]});
        } except Exception {
        }
    }

    def instrumentStorage() -> None {
        try {
            if window.localStorage and window.localStorage.setItem {  # jac:ignore[E1030]
                originalLocalSetItem = window.localStorage.setItem.bind(window.localStorage);  # jac:ignore[E1030]
                originalLocalRemoveItem = window.localStorage.removeItem.bind(window.localStorage);  # jac:ignore[E1030]
                originalLocalClear = window.localStorage.clear.bind(window.localStorage);  # jac:ignore[E1030]

                window.localStorage.setItem = lambda (key: any, value: any) {  # jac:ignore[E1030]
                    result = originalLocalSetItem(key, value);
                    emitSessionStateEvent("storage_mutation", "local_storage");
                    return result;
                };
                window.localStorage.removeItem = lambda (key: any) {  # jac:ignore[E1030]
                    result = originalLocalRemoveItem(key);
                    emitSessionStateEvent("storage_mutation", "local_storage");
                    return result;
                };
                window.localStorage.clear = lambda {  # jac:ignore[E1030]
                    result = originalLocalClear();
                    emitSessionStateEvent("storage_mutation", "local_storage");
                    return result;
                };
            }
        } except Exception {
        }

        try {
            if window.sessionStorage and window.sessionStorage.setItem {  # jac:ignore[E1030]
                originalSessionSetItem = window.sessionStorage.setItem.bind(window.sessionStorage);  # jac:ignore[E1030]
                originalSessionRemoveItem = window.sessionStorage.removeItem.bind(window.sessionStorage);  # jac:ignore[E1030]
                originalSessionClear = window.sessionStorage.clear.bind(window.sessionStorage);  # jac:ignore[E1030]

                window.sessionStorage.setItem = lambda (key: any, value: any) {  # jac:ignore[E1030]
                    result = originalSessionSetItem(key, value);
                    emitSessionStateEvent("storage_mutation", "session_storage");
                    return result;
                };
                window.sessionStorage.removeItem = lambda (key: any) {  # jac:ignore[E1030]
                    result = originalSessionRemoveItem(key);
                    emitSessionStateEvent("storage_mutation", "session_storage");
                    return result;
                };
                window.sessionStorage.clear = lambda {  # jac:ignore[E1030]
                    result = originalSessionClear();
                    emitSessionStateEvent("storage_mutation", "session_storage");
                    return result;
                };
            }
        } except Exception {
        }

        window.addEventListener("storage", lambda (event: any) {
            kind = "local_storage";
            if event.storageArea == window.sessionStorage {  # jac:ignore[E1030]
                kind = "session_storage";
            }
            emitSessionStateEvent("storage_event", kind);
        });
    }

    def instrumentNavigation() -> None {
        if window.history and window.history.pushState {
            nativePushState = window.history.pushState.bind(window.history);  # jac:ignore[E1031]
            window.history.pushState = lambda (state: any, title: any, url: any) {
                result = nativePushState(state, title, url);
                setTimeout(lambda { emitRouteTelemetry("push_state"); }, 40);
                return result;
            };
        }

        if window.history and window.history.replaceState {
            nativeReplaceState = window.history.replaceState.bind(window.history);  # jac:ignore[E1031]
            window.history.replaceState = lambda (state: any, title: any, url: any) {
                result = nativeReplaceState(state, title, url);
                setTimeout(lambda { emitRouteTelemetry("replace_state"); }, 40);
                return result;
            };
        }

        window.addEventListener("hashchange", lambda {
            emitRouteTelemetry("hash_change");
        });

        window.addEventListener("popstate", lambda {
            emitRouteTelemetry("pop_state");
        });
    }

    def instrumentSemanticObserver() -> None {
        if typeof(MutationObserver) == "undefined" {
            return;
        }

        try {
            observer = Reflect.construct(MutationObserver, [lambda (mutations: any) {
                hasMeaningfulMutation = False;
                for mutation in mutations {
                    if mutation.type == "childList" {
                        if Number(mutation.addedNodes.length or 0) > 0 or Number(mutation.removedNodes.length or 0) > 0 {
                            hasMeaningfulMutation = True;
                            break;
                        }
                    } elif mutation.type == "attributes" or mutation.type == "characterData" {
                        hasMeaningfulMutation = True;
                        break;
                    }
                }

                if not hasMeaningfulMutation {
                    return;
                }

                if pendingMutationTimer {
                    clearTimeout(pendingMutationTimer);  # jac:ignore[E1053]
                }

                pendingMutationTimer = setTimeout(lambda {
                    emitSemanticEvent("dom_mutation", False);
                    pendingMutationTimer = None;
                }, 700);
            }]);

            observer.observe(document.documentElement or document.body, {
                "subtree": True,
                "childList": True,
                "characterData": True,
                "attributes": True,
                "attributeFilter": ["class", "style", "hidden", "aria-hidden", "open"]
            });
        } except Exception {
        }
    }

    document.addEventListener("click", lambda (event: any) {
        if not event.target or not event.target.tagName {
            return;
        }
        clickable = event.target.closest("a,button,input,textarea,select,[role='button'],[role='link']") or event.target;
        emitObservation("click", describeTarget(clickable), "", {"source": "page"}, {
            "viewport": captureViewport(),
            "dom_snapshot": buildDomSnapshot(clickable, False),
            "semantic": collectSemanticContext()
        });
    }, True);

    document.addEventListener("input", lambda (event: any) {
        if not event.target or not event.target.tagName {
            return;
        }
        if not ("value" in event.target) {
            return;
        }
        queueInputEvent(event.target);
    }, True);

    document.addEventListener("change", lambda (event: any) {
        if not event.target or not event.target.tagName {
            return;
        }
        if not ("value" in event.target) {
            return;
        }
        target = describeTarget(event.target);
        emitObservation("input", target, safeValue(event.target.value, target), {
            "source": "page",
            "trigger": "change"
        }, {
            "viewport": captureViewport(),
            "dom_snapshot": buildDomSnapshot(event.target, False),
            "semantic": collectSemanticContext()
        });
    }, True);

    document.addEventListener("submit", lambda (event: any) {
        if not event.target or not event.target.tagName {
            return;
        }
        emitObservation("submit", describeTarget(event.target), "", {"source": "page"}, {
            "viewport": captureViewport(),
            "dom_snapshot": buildDomSnapshot(event.target, True),
            "semantic": collectSemanticContext(),
            "session_state": captureSessionState(),
            "capture_screenshot": True
        });
        emitSemanticEvent("submit", True);
    }, True);

    window.addEventListener("scroll", lambda {
        if pendingScrollTimer {
            clearTimeout(pendingScrollTimer);  # jac:ignore[E1053]
        }
        pendingScrollTimer = setTimeout(lambda {
            viewport = captureViewport();
            signature = JSON.stringify({
                "scroll_y": viewport["scroll_y"] or 0,
                "progress": viewport["scroll_progress"] or 0
            });
            if signature == lastScrollSignature {
                return;
            }
            lastScrollSignature = signature;

            emitObservation("scroll", {"role": "document", "label": "scroll_position"}, "", {
                "source": "page",
                "trigger": "scroll"
            }, {
                "viewport": viewport,
                "semantic": collectSemanticContext()
            });
        }, SCROLL_THROTTLE_MS);
    }, {"passive": True});

    instrumentFetch();
    instrumentResourceObserver();
    instrumentStorage();
    instrumentNavigation();
    instrumentSemanticObserver();

    window.addEventListener("DOMContentLoaded", lambda {
        emitObservation("page_ready", {"role": "document", "label": "page_ready"}, "", {"source": "page"}, {
            "viewport": captureViewport(),
            "dom_snapshot": buildDomSnapshot(document.body, True),
            "semantic": collectSemanticContext(),
            "session_state": captureSessionState(),
            "capture_screenshot": True
        });
        emitSemanticEvent("page_ready", True);
        emitSessionStateEvent("page_ready", "document");
    });
}
