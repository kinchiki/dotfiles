#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, "../..");
const sourcePath = path.join(repoRoot, "agent-resources/permissions.json");
const claudeSettingsPath = path.join(repoRoot, ".claude/settings.json");
const codexRulesPath = path.join(repoRoot, ".codex/rules/default.rules");

const decisionByKind = {
  allow: "allow",
  ask: "prompt",
  deny: "forbidden",
};

const checkOnly = process.argv.includes("--check");

const source = readJson(sourcePath);

const claudePermissions = {};
for (const kind of ["allow", "deny", "ask"]) {
  claudePermissions[kind] = source.permissions[kind].map((entry) => {
    if (!entry.claude) {
      throw new Error(`Missing Claude permission for ${kind} entry`);
    }
    return entry.claude;
  });
}

const claudeSettingsBefore = fs.readFileSync(claudeSettingsPath, "utf8");
const claudeSettings = JSON.parse(claudeSettingsBefore);
claudeSettings.permissions = claudePermissions;
const claudeSettingsAfter = `${JSON.stringify(claudeSettings, null, 2)}\n`;

const codexRules = [];
for (const kind of ["allow", "ask", "deny"]) {
  for (const entry of source.permissions[kind]) {
    const rules = entry.codex == null ? [] : Array.isArray(entry.codex) ? entry.codex : [entry.codex];
    for (const rule of rules) {
      codexRules.push({
        decision: rule.decision ?? decisionByKind[kind],
        ...rule,
      });
    }
  }
}

const codexRulesAfter = renderCodexRules(codexRules);
const codexRulesBefore = fs.existsSync(codexRulesPath) ? fs.readFileSync(codexRulesPath, "utf8") : null;

if (checkOnly) {
  const drift = [];
  if (claudeSettingsAfter !== claudeSettingsBefore) drift.push(".claude/settings.json");
  if (codexRulesAfter !== codexRulesBefore) drift.push(".codex/rules/default.rules");
  if (drift.length > 0) {
    console.error("agent-resources/permissions.json is out of sync with:");
    for (const file of drift) console.error(`  - ${file}`);
    console.error("Run: node agent-resources/scripts/generate-agent-permissions.mjs");
    process.exit(1);
  }
  console.log("agent-resources/permissions.json is in sync.");
  process.exit(0);
}

writeText(claudeSettingsPath, claudeSettingsAfter);
writeText(codexRulesPath, codexRulesAfter);

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function writeText(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, value);
}

function renderCodexRules(rules) {
  const chunks = [
    "# Generated from agent-resources/permissions.json.",
    "# Do not edit by hand; run `node agent-resources/scripts/generate-agent-permissions.mjs`.",
    "# Claude \"ask\" maps to Codex \"prompt\"; Claude \"deny\" maps to \"forbidden\".",
    "# These rules apply when Codex requests to run a command outside the sandbox.",
    "",
  ];

  for (const rule of rules) {
    chunks.push("prefix_rule(");
    chunks.push(`    pattern = ${starlarkValue(rule.pattern)},`);
    chunks.push(`    decision = ${starlarkValue(rule.decision)},`);
    chunks.push(`    justification = ${starlarkValue(rule.justification)},`);
    appendOptionalList(chunks, "match", rule.match);
    appendOptionalList(chunks, "not_match", rule.not_match);
    chunks.push(")");
    chunks.push("");
  }

  return chunks.join("\n");
}

function appendOptionalList(chunks, key, values) {
  if (!values || values.length === 0) {
    return;
  }

  chunks.push(`    ${key} = [`);
  for (const value of values) {
    chunks.push(`        ${starlarkValue(value)},`);
  }
  chunks.push("    ],");
}

function starlarkValue(value) {
  if (Array.isArray(value)) {
    return `[${value.map(starlarkValue).join(", ")}]`;
  }

  return JSON.stringify(value);
}
