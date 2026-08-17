import { spawn } from "node:child_process";
import { existsSync, statSync, watch } from "node:fs";
import { extname, relative, resolve } from "node:path";

const roots = ["source", "docs"]
  .map((path) => resolve(path))
  .filter(existsSync);
const prettierCli = resolve("node_modules", "prettier", "bin", "prettier.cjs");
const debounceMs = 700;
const isVerbose =
  process.argv.includes("--verbose") || process.argv.includes("-v");
const pending = new Map();
const running = new Set();

function now() {
  return new Date().toLocaleTimeString();
}

function log(message) {
  console.log(`[${now()}] ${message}`);
}

function verbose(message) {
  if (isVerbose) {
    log(message);
  }
}

function isHaxeFile(path) {
  try {
    return (
      extname(path).toLowerCase() === ".hx" &&
      existsSync(path) &&
      statSync(path).isFile()
    );
  } catch {
    return false;
  }
}

function formatFile(path) {
  if (running.has(path)) {
    verbose(
      `Already formatting ${relative(process.cwd(), path)}, skipping duplicate event.`,
    );
    return;
  }

  running.add(path);
  const displayPath = relative(process.cwd(), path);
  log(`Formatting ${displayPath}`);

  if (!existsSync(prettierCli)) {
    running.delete(path);
    log("Could not find local Prettier. Run npm.cmd install first.");
    return;
  }

  const child = spawn(process.execPath, [prettierCli, "--write", displayPath], {
    stdio: "inherit",
    shell: false,
  });

  child.on("close", (code) => {
    running.delete(path);

    if (code === 0) {
      log(`Done ${displayPath}`);
      return;
    }

    log(`Failed ${displayPath} with exit code ${code}`);
  });

  child.on("error", (error) => {
    running.delete(path);
    log(`Could not start Prettier for ${displayPath}: ${error.message}`);
  });
}

function queueFormat(path) {
  if (!isHaxeFile(path)) {
    verbose(`Ignored ${relative(process.cwd(), path)}`);
    return;
  }

  const displayPath = relative(process.cwd(), path);
  verbose(`Change detected in ${displayPath}`);
  clearTimeout(pending.get(path));
  pending.set(
    path,
    setTimeout(() => {
      pending.delete(path);
      formatFile(path);
    }, debounceMs),
  );
}

if (roots.length === 0) {
  log("No source/ or docs/ folders found. Nothing to watch.");
  process.exit(1);
}

for (const root of roots) {
  watch(
    root,
    {
      recursive: true,
    },
    (_eventType, filename) => {
      if (!filename) {
        return;
      }

      queueFormat(resolve(root, filename));
    },
  );

  log(`Watching ${relative(process.cwd(), root) || root}`);
}

log(
  `Ready. Verbose mode is ${isVerbose ? "on" : "off"}. Press Ctrl+C to stop.`,
);
