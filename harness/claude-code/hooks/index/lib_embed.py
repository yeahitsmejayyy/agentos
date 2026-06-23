"""Agent OS — local embedding layer (three-tier, graceful, fully local).

Backend selection (env AGENT_OS_EMBED = ollama | st | hash | auto; default auto):
  auto → Ollama if its server answers, else sentence-transformers if importable,
         else a zero-dependency hashing baseline (always works).

Nothing here calls any remote API. Ollama and sentence-transformers both run on
the local machine; the hash backend is pure stdlib.
"""
import os, json, math, hashlib, re, time, urllib.request, urllib.error

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("AGENT_OS_OLLAMA_MODEL", "nomic-embed-text")
ST_MODEL = os.environ.get("AGENT_OS_ST_MODEL", "all-MiniLM-L6-v2")
HASH_DIM = 512

_st_model = None


def _ollama_available():
    """True only if the server answers AND the embed model is actually pulled.

    Checking the model (not just the server) is what keeps `auto` from picking
    ollama and then 404-ing on /api/embeddings when the model was never pulled —
    which would otherwise hard-crash an index build (and silently fail in cron).
    """
    try:
        with urllib.request.urlopen(OLLAMA_URL + "/api/tags", timeout=1) as r:
            models = [m.get("name", "") for m in json.loads(r.read()).get("models", [])]
    except Exception:
        return False
    want = OLLAMA_MODEL.split(":")[0]
    return any(m == OLLAMA_MODEL or m.split(":")[0] == want for m in models)


def _embed_ollama(texts, retries=4):
    """Embed via the local ollama server, retrying transient errors.

    A cold model load (ollama unloads idle models after ~5 min) can make the first
    request 500 or drop the connection — exactly what the hourly cron rebuild hits.
    Retry with backoff on transient failures so one cold start doesn't crash the
    whole index build; genuine errors (e.g. 404 / bad request) still raise.
    """
    out = []
    for t in texts:
        body = json.dumps({"model": OLLAMA_MODEL, "prompt": t}).encode()
        last = None
        for attempt in range(retries):
            req = urllib.request.Request(
                OLLAMA_URL + "/api/embeddings", data=body,
                headers={"Content-Type": "application/json"},
            )
            try:
                with urllib.request.urlopen(req, timeout=120) as r:
                    out.append(json.loads(r.read())["embedding"])
                    last = None
                    break
            except urllib.error.HTTPError as e:
                last = e
                if e.code in (500, 502, 503, 504):  # transient (cold model load)
                    time.sleep(1.5 * (attempt + 1)); continue
                raise  # 404/400 etc. are real — don't mask them
            except (urllib.error.URLError, TimeoutError) as e:
                last = e
                time.sleep(1.5 * (attempt + 1)); continue
        if last is not None:
            raise last
    return out


def _embed_st(texts):
    global _st_model
    from sentence_transformers import SentenceTransformer
    if _st_model is None:
        _st_model = SentenceTransformer(ST_MODEL)
    return [list(map(float, v)) for v in _st_model.encode(texts, normalize_embeddings=False)]


def _embed_hash(texts):
    """Zero-dependency lexical baseline: hashed bag-of-words → fixed dim, L2-normalized."""
    out = []
    for t in texts:
        vec = [0.0] * HASH_DIM
        for tok in re.findall(r"[a-z0-9]{2,}", t.lower()):
            h = int(hashlib.md5(tok.encode()).hexdigest(), 16)
            vec[h % HASH_DIM] += 1.0
        norm = math.sqrt(sum(x * x for x in vec)) or 1.0
        out.append([x / norm for x in vec])
    return out


def select_backend():
    b = os.environ.get("AGENT_OS_EMBED", "auto").lower()
    if b != "auto":
        return b
    if _ollama_available():
        return "ollama"
    try:
        import sentence_transformers  # noqa: F401
        return "st"
    except Exception:
        return "hash"


def embed(texts, backend=None):
    """Return (list_of_vectors, backend_used)."""
    backend = backend or select_backend()
    if backend == "ollama":
        return _embed_ollama(texts), "ollama"
    if backend == "st":
        return _embed_st(texts), "st"
    return _embed_hash(texts), "hash"
