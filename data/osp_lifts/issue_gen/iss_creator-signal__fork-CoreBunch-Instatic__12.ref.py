import importlib.util, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("cb12", HERE / "iss_creator-signal__fork-CoreBunch-Instatic__12.py")
mod = importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(mod)
load_fs, list_media, upload_queue = mod.load_fs, mod.list_media, mod.upload_queue

def main():
    g = load_fs([
        ("/media", "folder", None), ("/media/photos", "folder", "/media"),
        ("/media/photos/a.png", "file", "/media/photos"),
        ("/media/vids", "folder", "/media"), ("/media/vids/clip.mp4", "file", "/media/vids"),
        ("/media/readme.txt", "file", "/media"),
    ])
    assert list_media(g, "/media") == ["/media/photos/a.png", "/media/vids/clip.mp4"]
    assert list_media(g, "/nope") == []
    assert upload_queue(g, ["/media/photos", "/media/vids"]) == [
        "/media/photos/a.png", "/media/vids/clip.mp4"
    ]
    print("ok")
if __name__ == "__main__": main()
