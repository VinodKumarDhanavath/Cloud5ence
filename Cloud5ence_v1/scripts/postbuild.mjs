import { copyFile } from "node:fs/promises";
// Existing CloudFront distribution serves cloud5ence.html as its root object.
await copyFile("out/index.html", "out/cloud5ence.html");
