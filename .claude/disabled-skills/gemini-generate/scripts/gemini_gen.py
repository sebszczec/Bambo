"""Generate ONE image (Nano Banana) or ONE video (Veo) with the Gemini API.

Standard library only. Reads the key from the GEMINI_API_KEY environment variable.

  python -I gemini_gen.py image --prompt "..." --out <file.png> [--ref <png>]...
  python -I gemini_gen.py video --prompt "..." --out <file.mp4> [--ref <png>] [--aspect 16:9]
  add --dry-run to print the request summary without calling the API (no cost)

Always produces exactly one output. There is no count option on purpose: every call costs money.
"""
import argparse
import base64
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://generativelanguage.googleapis.com/v1beta"
IMAGE_MODEL = "gemini-2.5-flash-image"          # "Nano Banana"
VIDEO_MODEL = "veo-3.1-generate-preview"        # Veo 3.1 (8 s clips)


def die(msg):
    sys.exit("gemini_gen: " + msg)


def api_key():
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not key:
        die("GEMINI_API_KEY is not set (run PowerShell again after setting it, or set it for this session)")
    return key


def request(method, url, key, body=None):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("x-goog-api-key", key)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=600) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        die(f"HTTP {e.code} from {url.split('?')[0]}: {e.read().decode('utf-8', 'replace')[:800]}")


def inline_part(path):
    mime = mimetypes.guess_type(path)[0] or "image/png"
    with open(path, "rb") as f:
        return {"inlineData": {"mimeType": mime, "data": base64.b64encode(f.read()).decode("ascii")}}


def image(args, key):
    model = args.model or IMAGE_MODEL
    parts = [{"text": args.prompt}] + [inline_part(p) for p in args.ref]
    body = {"contents": [{"parts": parts}]}
    if args.dry_run:
        print(f"DRY RUN image: model={model} refs={len(args.ref)} out={args.out}")
        return
    result = request("POST", f"{API}/models/{model}:generateContent", key, body)
    for cand in result.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            inline = part.get("inlineData")
            if inline:
                with open(args.out, "wb") as f:
                    f.write(base64.b64decode(inline["data"]))
                print(f"saved {args.out}")
                return
    text = " ".join(p.get("text", "") for c in result.get("candidates", []) for p in c.get("content", {}).get("parts", []))
    die("no image in the response. Model said: " + (text or json.dumps(result)[:500]))


def video(args, key):
    model = args.model or VIDEO_MODEL
    instance = {"prompt": args.prompt}
    if args.ref:
        instance["image"] = {"bytesBase64Encoded": inline_part(args.ref[0])["inlineData"]["data"],
                             "mimeType": mimetypes.guess_type(args.ref[0])[0] or "image/png"}
    body = {"instances": [instance], "parameters": {"aspectRatio": args.aspect}}
    if args.dry_run:
        print(f"DRY RUN video: model={model} ref={'yes' if args.ref else 'no'} aspect={args.aspect} out={args.out}")
        return
    op = request("POST", f"{API}/models/{model}:predictLongRunning", key, body)
    name = op.get("name")
    if not name:
        die("no operation name in response: " + json.dumps(op)[:500])
    print(f"submitted {name}, waiting (video takes minutes)...")
    while not op.get("done"):
        time.sleep(15)
        op = request("GET", f"{API}/{name}", key)
    if "error" in op:
        die("video failed: " + json.dumps(op["error"])[:500])
    samples = op.get("response", {}).get("generateVideoResponse", {}).get("generatedSamples", [])
    if not samples:
        die("no video in the response: " + json.dumps(op)[:500])
    uri = samples[0]["video"]["uri"]
    req = urllib.request.Request(uri)
    req.add_header("x-goog-api-key", key)
    with urllib.request.urlopen(req, timeout=600) as resp, open(args.out, "wb") as f:
        f.write(resp.read())
    print(f"saved {args.out}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="kind", required=True)
    for name, fn in (("image", image), ("video", video)):
        s = sub.add_parser(name)
        s.add_argument("--prompt", required=True)
        s.add_argument("--out", required=True)
        s.add_argument("--ref", action="append", default=[], help="reference image (repeatable for image)")
        s.add_argument("--model", default=None)
        s.add_argument("--dry-run", action="store_true")
        if name == "video":
            s.add_argument("--aspect", default="16:9")
        s.set_defaults(fn=fn)
    args = p.parse_args()
    if os.path.exists(args.out) and not args.dry_run:
        die(f"{args.out} already exists; pick a new name so a paid result is not overwritten by accident")
    key = "" if args.dry_run else api_key()
    args.fn(args, key)


if __name__ == "__main__":
    main()
