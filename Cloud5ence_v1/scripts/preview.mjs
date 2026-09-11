import http from "node:http";
import { readFile, stat } from "node:fs/promises";
import { resolve, extname, sep } from "node:path";
const root = resolve("out");
const port = Number(process.env.PORT || 3000);
const types = {".html":"text/html; charset=utf-8", ".js":"text/javascript; charset=utf-8", ".css":"text/css; charset=utf-8", ".json":"application/json", ".txt":"text/plain; charset=utf-8", ".svg":"image/svg+xml", ".png":"image/png", ".woff2":"font/woff2", ".ico":"image/x-icon"};
await stat(resolve(root, "index.html")).catch(() => { throw new Error("Run pnpm build before pnpm preview."); });
http.createServer(async (req, res) => {
  try {
    let path = resolve(root, "." + decodeURIComponent(new URL(req.url, "http://localhost").pathname));
    if (path !== root && !path.startsWith(root + sep)) {res.writeHead(403).end(); return;}
    if ((await stat(path)).isDirectory()) path = resolve(path, "index.html");
    const bytes = await readFile(path);
    res.writeHead(200, {"Content-Type": types[extname(path)] || "application/octet-stream"});
    res.end(req.method === "HEAD" ? undefined : bytes);
  } catch {res.writeHead(404, {"Content-Type":"text/plain"}).end("Not found");}
}).listen(port, "127.0.0.1", () => console.log(`Cloud5ence preview: http://localhost:${port}`));
