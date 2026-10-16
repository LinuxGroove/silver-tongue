#!/usr/bin/env python3
"""A stand-in for Lemonade Server, for the tests and CI, where no model can
run: enough of its API for Silver Tongue's hearing, brains and speaking.

    python3 tools/fake_lemonade.py --port 13399

Serves, under /api/v1 (and /v1):
  GET  /health, /models, /downloads      what the game asks at start
  POST /load, /pull, /unload             always fine
  POST /chat/completions                 canned replies by keyword (see REPLIES,
                                         and GALA and CAST for the gala's cast),
                                         with usage and llama.cpp-style timings;
                                         a json_schema whose only word is
                                         "pineapple" gets that word (the probe)
  POST /audio/transcriptions             the next scripted transcript (or a default)
  POST /audio/speech                     a WAV: a hum as long as the text
  WS   /realtime                         the realtime transcription events
And for the tests:
  POST /fake/transcript {"text": ...}    what the next utterance is heard as
  POST /fake/slow {"seconds": ...}       delay the next chat reply
  GET  /fake/log                         what was asked (response_format and all)
  POST /fake/fresh {"models": [...]}     those models aren't downloaded yet: /pull
                                         starts a job that /downloads reports
                                         for DOWNLOAD_SECONDS, in two files
  POST /fake/reset
With --no-schema the chat ignores response_format (a server that doesn't pass
it through), so the game's probe reports "not enforced".
"""
import argparse
import base64
import hashlib
import json
import math
import struct
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODEL = "Qwen3-4B-Instruct-2507-GGUF"
GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

# The guard's canned replies: the first rule whose words appear in the last
# user message wins. Events from the game arrive in square brackets.
REPLIES = [
    (["pineapple"], None),
    (["cops", "police", "weapon", "gun", "open it"], {"think": "That's a threat.", "say": "Right. That's enough.", "tone": "alarmed", "do": "radio_security", "believes": ["dangerous"], "suspicion": 5}),
    (["code", "4471", "combination"], {"think": "Nobody asks that.", "say": "Not a chance. Who are you?", "tone": "annoyed", "do": "none", "believes": ["wants the kitchen code"], "suspicion": 3}),
    (["dana, on the radio", "reception says", "nothing booked"], {"think": "Nothing booked. So what's this?", "say": "Reception says nothing's booked. So who sent you?", "tone": "wary", "do": "none", "believes": ["says they're from facilities", "reception has nothing"], "suspicion": 2}),
    (["priya", "day manager", "booked it"], {"think": "Priya forgetting to book it. That's her all over.", "say": "Course she didn't book it. Go on through, and tell her I said so.", "tone": "friendly", "do": "let_through", "believes": ["Priya sent them about the freezer", "facilities"], "suspicion": 1}),
    (["badge", "work order"], {"think": "A badge. Fine.", "say": "Let's see it, then.", "tone": "calm", "do": "ask_for_badge", "believes": ["has a badge, they say"], "suspicion": 1}),
    (["freezer", "facilities", "sent me", "kitchen"], {"think": "Facilities, this late? Nobody radioed.", "say": "Facilities? Nobody told me. Hang on, I'll check with reception.", "tone": "wary", "do": "ask_reception", "believes": ["says they're from facilities about the freezer"], "suspicion": 1}),
    (["standing", "without saying"], {"think": "Just standing there.", "say": "You want something?", "tone": "wary", "do": "none", "believes": [], "suspicion": 2}),
    (["hello", "evening", "hi "], {"think": "Someone at the door.", "say": "Evening. Staff only back here.", "tone": "calm", "do": "none", "believes": [], "suspicion": 1}),
]
DEFAULT = {"think": "No idea what they're on about.", "say": "Service entrance. You want the front.", "tone": "calm", "do": "none", "believes": [], "suspicion": 1}

# The gala's cast, known by the name the system prompt gives ("You are Teo,
# ..."). GALA comes first for everyone: a colleague's answer, a question on
# the radio, an invitation; then the character's own rules; then Marcus's
# (REPLIES) for him, or the cast's default. Only the last line of the last
# user message is matched, since the game sends several lines at once.
OPENS = {"marcus": "let_through", "teo": "let_through", "okafor": "escort_in", "dana": "add_to_list", "laurent": "put_to_work", "celeste": "plus_one", "hugo": "plus_one"}
GALA = [
    (["so it checks out"], {"think": "Checks out.", "say": "Right. That checks out. Go ahead.", "tone": "friendly", "do": "OPEN", "believes": ["checks out"], "suspicion": 1}),
    (["so it doesn't check out"], {"think": "That's not what I'm told.", "say": "That's not what I'm hearing. Who are you, really?", "tone": "wary", "do": "none", "believes": ["story doesn't check out"], "suspicion": 3}),
    (["asks about"], {"think": "Let me look.", "say": "ANSWER", "tone": "calm", "do": "none", "believes": [], "suspicion": 1}),
    (["it's a copy"], {"think": "A fake.", "say": "This isn't real. Where did you get it?", "tone": "annoyed", "do": "none", "believes": ["has a forged invitation"], "suspicion": 4}),
    (["it looks right"], {"think": "Looks fine.", "say": "Thank you. Enjoy the evening.", "tone": "friendly", "do": "OPEN", "believes": ["has an invitation"], "suspicion": 1}),
    (["police", "gun", "weapon"], {"think": "That's a threat.", "say": "Right. That's enough.", "tone": "alarmed", "do": "radio_security", "believes": ["dangerous"], "suspicion": 5}),
    (["forged", "the rose", "heist", "steal"], {"think": "What did they just say?", "say": "", "tone": "wary", "do": "none", "believes": ["talking about something they shouldn't"], "suspicion": 3}),
]
CAST = {
    "teo": [
        (["nephew", "halvorsen"], {"think": "The owner's nephew? I'd better check.", "say": "Mr Halvorsen? Of course. Let me just check with reception.", "tone": "calm", "do": "ask_reception", "believes": ["says he's Felix Halvorsen, the owner's nephew"], "suspicion": 1}),
        (["invitation", "invited"], {"think": "Papers, then.", "say": "May I see your invitation?", "tone": "calm", "do": "ask_for_invitation", "believes": ["says they're a guest"], "suspicion": 1}),
    ],
    "dana": [
        (["list", "add me", "put me down"], {"think": "Another one for the list.", "say": "Of course. I'll put you down.", "tone": "friendly", "do": "add_to_list", "believes": ["a guest whose name was missed"], "suspicion": 1}),
        (["freezer", "facilities", "book"], {"think": "Finally, the freezer.", "say": "At last. I'll book you in so the door knows.", "tone": "friendly", "do": "book_visit", "believes": ["here about the freezer"], "suspicion": 1}),
    ],
    "laurent": [
        (["agency", "staffing", "temp"], {"think": "The temps, at last.", "say": "You're late. Jacket, tray, out the pass. Go.", "tone": "annoyed", "do": "put_to_work", "believes": ["an agency temp"], "suspicion": 1}),
    ],
    "okafor": [
        (["nephew", "halvorsen"], {"think": "Oh no. The nephew.", "say": "Mr Halvorsen! Please, come with me, I'll take you in myself.", "tone": "friendly", "do": "escort_in", "believes": ["the owner's nephew"], "suspicion": 0}),
    ],
    "celeste": [
        (["plus-one", "plus one", "your arm", "take me in"], {"think": "Why not?", "say": "Oh, why not. Stay close at five past.", "tone": "friendly", "do": "plus_one", "believes": ["charming"], "suspicion": 1}),
    ],
    "hugo": [
        (["plus-one", "plus one", "your arm", "take me in"], {"think": "Fine.", "say": "Fine, you can come in with us.", "tone": "friendly", "do": "plus_one", "believes": ["harmless"], "suspicion": 1}),
    ],
    "benny": [
        (["code", "kitchen"], {"think": "Hm.", "say": "Couldn't tell you. Another drink?", "tone": "calm", "do": "none", "believes": [], "suspicion": 1}),
    ],
}
CAST_DEFAULT = {"think": "Hm.", "say": "Sorry, can I help you?", "tone": "calm", "do": "none", "believes": [], "suspicion": 1}
BAD_FACTS = ["isn't them", "not on the", "nobody", "never met", "don't know", "no press"]
GOOD_FACTS = ["on the list", "added them", "booked their", "expecting temps", "sending temps", "let him in", "taking them in", "seemed fine"]

# How long a fake download takes, and how big it says it is.
DOWNLOAD_SECONDS = 2.5
DOWNLOAD_BYTES = 2_684_354_560

state = {"transcripts": [], "slow": 0.0, "missing": set(), "jobs": {}, "log": {"chat": [], "transcriptions": 0, "speech": [], "pulls": [], "ws": {"connections": 0, "appends": 0, "bytes": 0, "commits": 0}}, "no_schema": False}


def job_now(job):
    """A download job as /downloads reports it, DOWNLOAD_SECONDS after it
    started: two files, the first nine tenths of the bytes."""
    f = min(1.0, (time.time() - job["started"]) / DOWNLOAD_SECONDS)
    got = int(DOWNLOAD_BYTES * f)
    first = int(DOWNLOAD_BYTES * 0.9)
    if got < first:
        index, done, size = 1, got, first
    else:
        index, done, size = 2, got - first, DOWNLOAD_BYTES - first
    out = {
        "id": "model:" + job["model_name"], "type": "model", "model_name": job["model_name"],
        "status": "completed" if f >= 1.0 else "downloading", "running": f < 1.0,
        "file": "model.gguf" if index == 1 else "config.json", "file_index": index, "total_files": 2,
        "bytes_downloaded": done, "bytes_total": size, "percent": int(100 * done / size) if size else 100,
        "total_download_size": DOWNLOAD_BYTES, "overall_bytes_downloaded": got, "complete": f >= 1.0,
    }
    if f >= 1.0:
        state["missing"].discard(job["model_name"])
    return out
lock = threading.Lock()


def wav_hum(seconds, rate=24000):
    n = int(rate * seconds)
    data = bytearray()
    for i in range(n):
        t = i / rate
        # Syllables: a 140 Hz hum pulsing four times a second, fading at the end.
        env = 0.5 + 0.5 * math.sin(2 * math.pi * 4.0 * t)
        env *= min(1.0, (seconds - t) * 4.0)
        v = int(9000 * env * math.sin(2 * math.pi * 140.0 * t))
        data += struct.pack("<h", v)
    header = b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt " + struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16) + b"data" + struct.pack("<I", len(data))
    return header + bytes(data)


def who(messages):
    """The character the system prompt is for: "teo", "okafor", or ""."""
    for m in messages:
        if m.get("role") == "system":
            head = str(m.get("content", "")).split(",", 1)[0]
            if head.startswith("You are "):
                return head[len("You are "):].split()[-1].lower()
    return ""


def gala_reply(name, last):
    for words, reply in GALA:
        if any(w in last for w in words):
            r = dict(reply)
            if r["do"] == "OPEN":
                r["do"] = OPENS.get(name, "none")
            if r["say"] == "ANSWER":
                fact = last.split("what you know:", 1)[-1]
                bad = any(b in fact for b in BAD_FACTS)
                r["say"] = "Yes, that checks out." if not bad and any(f in fact for f in GOOD_FACTS) else "No. Nothing like that here."
            return r
    for words, reply in CAST.get(name, []):
        if any(w in last for w in words):
            return dict(reply)
    return None


def reply_for(messages, response_format):
    full = ""
    for m in reversed(messages):
        if m.get("role") == "user":
            full = str(m.get("content", "")).lower().strip()
            break
    last = full.split("\n")[-1]
    schema = {}
    if isinstance(response_format, dict) and response_format.get("type") == "json_schema":
        schema = response_format.get("json_schema", {}).get("schema", {})
    if not state["no_schema"] and schema.get("properties", {}).get("word", {}).get("enum") == ["pineapple"]:
        return {"word": "pineapple"}
    if schema.get("properties", {}).get("word") and state["no_schema"]:
        return {"answer": "hello"}
    name = who(messages)
    if name in CAST or name == "marcus" and ("so it" in last or "asks about" in last):
        r = gala_reply(name, last)
        if r is not None:
            return r
        if name != "marcus":
            return dict(CAST_DEFAULT)
    for words, reply in REPLIES:
        if reply is None:
            continue
        if any(w in full for w in words):
            return dict(reply)
    return dict(DEFAULT)


def next_transcript():
    with lock:
        if state["transcripts"]:
            return state["transcripts"].pop(0)
    return "Evening, facilities sent me about the freezer."


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        if "--verbose" in sys.argv:
            sys.stderr.write("%s %s\n" % (self.command, self.path))

    def _path(self):
        p = self.path.split("?")[0]
        for prefix in ("/api/v1", "/api/v0", "/v1", "/v0"):
            if p.startswith(prefix + "/"):
                return p[len(prefix):]
        return p

    def _send(self, code, body, ctype="application/json"):
        if isinstance(body, (dict, list)):
            body = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _body(self):
        n = int(self.headers.get("Content-Length", "0") or 0)
        return self.rfile.read(n) if n > 0 else b""

    def do_GET(self):
        p = self._path()
        if p == "/realtime" and "websocket" in self.headers.get("Upgrade", "").lower():
            return self._websocket()
        if p == "/health":
            return self._send(200, {"status": "ok", "version": "fake-0.1", "model_loaded": MODEL, "all_models_loaded": [MODEL, "Whisper-Small", "kokoro-v1"], "max_models": 3})
        if p == "/models":
            with lock:
                for job in list(state["jobs"].values()):
                    job_now(job)
                missing = set(state["missing"])
            return self._send(200, {"object": "list", "data": [{"id": m, "object": "model", "downloaded": m not in missing} for m in [MODEL, "LFM2.5-1.2B-Instruct-GGUF", "Whisper-Tiny", "Whisper-Base", "Whisper-Small", "kokoro-v1"]]})
        if p == "/downloads":
            with lock:
                return self._send(200, [job_now(j) for j in state["jobs"].values()])
        if p == "/fake/log":
            with lock:
                return self._send(200, state["log"])
        self._send(404, {"error": "no such endpoint: " + p})

    def do_POST(self):
        p = self._path()
        raw = self._body()
        if p == "/pull":
            name = json.loads(raw or b"{}").get("model_name", "")
            with lock:
                state["log"]["pulls"].append(name)
                if name in state["missing"]:
                    job = state["jobs"].get(name)
                    if job is None or job_now(job)["complete"]:
                        job = {"model_name": name, "started": time.time()}
                        state["jobs"][name] = job
                    return self._send(200, job_now(job))
            return self._send(200, {"status": "success", "message": "Installed model: " + name})
        if p == "/load":
            with lock:
                # Lemonade installs a model it hasn't got when asked to load it.
                state["missing"].discard(json.loads(raw or b"{}").get("model_name", ""))
            return self._send(200, {"status": "success"})
        if p == "/unload":
            return self._send(200, {"status": "ok"})
        if p == "/fake/fresh":
            with lock:
                for m in json.loads(raw or b"{}").get("models", []):
                    state["missing"].add(m)
                    state["jobs"].pop(m, None)
            return self._send(200, {"ok": True})
        if p == "/fake/transcript":
            with lock:
                state["transcripts"].append(json.loads(raw or b"{}").get("text", ""))
            return self._send(200, {"ok": True})
        if p == "/fake/slow":
            with lock:
                state["slow"] = float(json.loads(raw or b"{}").get("seconds", 0.0))
            return self._send(200, {"ok": True})
        if p == "/fake/reset":
            with lock:
                state["transcripts"] = []
                state["slow"] = 0.0
                state["missing"] = set()
                state["jobs"] = {}
                state["log"] = {"chat": [], "transcriptions": 0, "speech": [], "pulls": [], "ws": {"connections": 0, "appends": 0, "bytes": 0, "commits": 0}}
            return self._send(200, {"ok": True})
        if p == "/chat/completions":
            body = json.loads(raw or b"{}")
            with lock:
                slow = state["slow"]
                state["slow"] = 0.0
                state["log"]["chat"].append({"response_format": body.get("response_format"), "messages": len(body.get("messages", [])), "model": body.get("model"), "max_tokens": body.get("max_tokens"), "who": who(body.get("messages", []))})
            if slow > 0:
                time.sleep(slow)
            reply = reply_for(body.get("messages", []), body.get("response_format"))
            text = json.dumps(reply)
            prompt_n = 40 + 20 * len(body.get("messages", []))
            return self._send(200, {
                "id": "fake", "object": "chat.completion", "model": body.get("model", MODEL),
                "choices": [{"index": 0, "message": {"role": "assistant", "content": text}, "finish_reason": "stop"}],
                "usage": {"prompt_tokens": prompt_n, "completion_tokens": 40, "total_tokens": prompt_n + 40},
                "timings": {"prompt_n": 20, "cache_n": prompt_n - 20, "prompt_ms": 120.0, "predicted_n": 40, "predicted_ms": 400.0},
            })
        if p == "/audio/transcriptions":
            with lock:
                state["log"]["transcriptions"] += 1
            text = next_transcript() if len(raw) > 4000 else ""
            return self._send(200, {"text": text})
        if p == "/audio/speech":
            body = json.loads(raw or b"{}")
            text = str(body.get("input", ""))
            with lock:
                state["log"]["speech"].append({"input": text, "voice": body.get("voice"), "model": body.get("model"), "format": body.get("response_format")})
            seconds = min(3.0, max(0.4, 0.05 * len(text)))
            return self._send(200, wav_hum(seconds), "audio/wav")
        self._send(404, {"error": "no such endpoint: " + p})

    # A small WebSocket server: the realtime transcription events.
    def _websocket(self):
        key = self.headers.get("Sec-WebSocket-Key", "")
        accept = base64.b64encode(hashlib.sha1((key + GUID).encode()).digest()).decode()
        self.send_response(101)
        self.send_header("Upgrade", "websocket")
        self.send_header("Connection", "Upgrade")
        self.send_header("Sec-WebSocket-Accept", accept)
        self.end_headers()
        self.close_connection = True
        with lock:
            state["log"]["ws"]["connections"] += 1
        self._ws_send({"type": "session.created", "session": {"id": "fake-session"}})
        audio = 0
        while True:
            msg = self._ws_recv()
            if msg is None:
                return
            try:
                data = json.loads(msg)
            except ValueError:
                continue
            t = data.get("type", "")
            if t == "session.update":
                self._ws_send({"type": "session.updated", "session": data.get("session", {})})
            elif t == "input_audio_buffer.append":
                n = len(base64.b64decode(data.get("audio", "")))
                audio += n
                with lock:
                    state["log"]["ws"]["appends"] += 1
                    state["log"]["ws"]["bytes"] += n
            elif t == "input_audio_buffer.clear":
                audio = 0
                self._ws_send({"type": "input_audio_buffer.cleared"})
            elif t == "input_audio_buffer.commit":
                with lock:
                    state["log"]["ws"]["commits"] += 1
                self._ws_send({"type": "input_audio_buffer.committed"})
                text = next_transcript() if audio >= 4000 else ""
                audio = 0
                if text:
                    words = text.split(" ")
                    self._ws_send({"type": "conversation.item.input_audio_transcription.delta", "delta": " ".join(words[: max(1, len(words) // 2)])})
                    time.sleep(0.05)
                self._ws_send({"type": "conversation.item.input_audio_transcription.completed", "transcript": text})

    def _ws_recv(self):
        try:
            head = self.rfile.read(2)
            if len(head) < 2:
                return None
            opcode = head[0] & 0x0F
            masked = head[1] & 0x80
            length = head[1] & 0x7F
            if length == 126:
                length = struct.unpack(">H", self.rfile.read(2))[0]
            elif length == 127:
                length = struct.unpack(">Q", self.rfile.read(8))[0]
            mask = self.rfile.read(4) if masked else b"\0\0\0\0"
            payload = bytearray(self.rfile.read(length))
            if masked:
                for i in range(len(payload)):
                    payload[i] ^= mask[i % 4]
            if opcode == 0x8:
                return None
            if opcode == 0x9:
                self._ws_frame(0xA, bytes(payload))
                return ""
            return payload.decode("utf-8", "replace")
        except (ConnectionError, OSError):
            return None

    def _ws_send(self, obj):
        self._ws_frame(0x1, json.dumps(obj).encode())

    def _ws_frame(self, opcode, payload):
        head = bytes([0x80 | opcode])
        n = len(payload)
        if n < 126:
            head += bytes([n])
        elif n < 65536:
            head += bytes([126]) + struct.pack(">H", n)
        else:
            head += bytes([127]) + struct.pack(">Q", n)
        try:
            self.wfile.write(head + payload)
            self.wfile.flush()
        except (ConnectionError, OSError):
            pass


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--port", type=int, default=13399)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--no-schema", action="store_true", help="ignore response_format, like a server that doesn't pass it through")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()
    state["no_schema"] = args.no_schema
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    server.daemon_threads = True
    print("fake lemonade on http://%s:%d/api/v1" % (args.host, args.port), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
