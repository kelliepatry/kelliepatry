// PreToolUse hook: refuse new Markdown files outside articles/ and examples/.
// Notes, summaries, plans and handoffs are not written as .md files in this repo.
import { existsSync, readFileSync } from "node:fs";
import { resolve, relative, sep } from "node:path";

const input = JSON.parse(readFileSync(0, "utf8") || "{}");
const filePath = input?.tool_input?.file_path;
if (!filePath || !/\.(md|markdown)$/i.test(filePath)) process.exit(0);

const root = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
const abs = resolve(root, filePath);
const rel = relative(root, abs);
const insideRepo = rel && !rel.startsWith("..") && !rel.startsWith(sep);

// Editing a file that already exists is fine; so is a new article or example.
if (existsSync(abs)) process.exit(0);
if (insideRepo && /^(articles|examples)[\\/]/.test(rel)) process.exit(0);

process.stderr.write(
  `Blocked: new Markdown file ${filePath}. Studio protocol: do not document in .md files. ` +
  `New .md files are allowed only under articles/ or examples/. ` +
  `Keep notes in the chat or the studio record through the session protocol instead.\n`
);
process.exit(2);
