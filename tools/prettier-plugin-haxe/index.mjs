import { spawnSync } from "node:child_process";

export const languages = [
  {
    name: "Haxe",
    extensions: [".hx"],
    parsers: ["haxe"],
  },
];

export const parsers = {
  haxe: {
    astFormat: "haxe-formatter-output",
    parse(text, options) {
      const filepath = options.filepath || "Main.hx";
      const result = spawnSync(
        "haxelib",
        ["run", "formatter", "--stdin", "-s", filepath],
        {
          input: text,
          encoding: "utf8",
        },
      );

      if (result.status !== 0) {
        const details =
          result.stderr || result.stdout || "Unknown haxe-formatter error";
        throw new Error(`haxe-formatter failed for ${filepath}\n${details}`);
      }

      return {
        type: "HaxeFormatterOutput",
        formatted: result.stdout,
        start: 0,
        end: text.length,
      };
    },
    locStart(node) {
      return node.start ?? 0;
    },
    locEnd(node) {
      return node.end ?? 0;
    },
  },
};

export const printers = {
  "haxe-formatter-output": {
    print(path) {
      return path.node.formatted;
    },
  },
};
