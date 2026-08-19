# Module-level state (like JavaScript module variables)
glob monacoInitialized: bool = False;
glob cachedConfig: any = None;
glob initPromise: any = None;

async def:pub initializeOnce() -> any {
    if monacoInitialized {
        return cachedConfig;
    }
    if initPromise {
        return await initPromise;
    }
    initPromise = performInit();
    try {
        cachedConfig = await initPromise;
        monacoInitialized = True;
        return cachedConfig;
    } except Exception as e {
        # Clear the failed promise so a later call can retry
        initPromise = None;
        raise e;
    }
}
