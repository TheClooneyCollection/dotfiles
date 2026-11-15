# Usage: python3 serve-lab.py <lab dir> [port] (default port 8091)
import functools
import http.server
from pathlib import Path
import sys
from urllib.parse import unquote, urlsplit


class NoStore(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        super().end_headers()

    def send_head(self):
        path = unquote(urlsplit(self.path).path)
        if any(part.startswith(".") for part in path.split("/")):
            self.send_error(404)
            return None
        target = Path(self.translate_path(self.path))
        if target.is_dir() and not (target / "index.html").is_file():
            self.send_error(404)
            return None
        return super().send_head()

    def list_directory(self, path):
        self.send_error(404)
        return None


if __name__ == "__main__":
    root = sys.argv[1]
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8091
    http.server.ThreadingHTTPServer(
        ("127.0.0.1", port), functools.partial(NoStore, directory=root)
    ).serve_forever()
