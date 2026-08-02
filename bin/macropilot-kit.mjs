#!/usr/bin/env node

import { readFile } from "node:fs/promises";

const usage = `MacroPilot Kit — profile inspector

Usage:
  macropilot-kit inspect <profile.json>
  macropilot-kit validate <profile.json>`;

export function validateProfile(profile) {
  if (profile?.schemaVersion !== 1) {
    throw new Error("expected schemaVersion 1");
  }
  if (!Array.isArray(profile.bindings) || profile.bindings.length === 0) {
    throw new Error("at least one binding is required");
  }

  const inputs = profile.bindings.map((binding) => binding.input);
  if (new Set(inputs).size !== inputs.length) {
    throw new Error("inputs must be unique within a profile");
  }

  for (const binding of profile.bindings) {
    if (!["safe", "review", "confirm"].includes(binding.safety)) {
      throw new Error(`invalid safety level for ${binding.input}`);
    }
    if (![binding.input, binding.action, binding.label].every(Boolean)) {
      throw new Error("each binding needs input, action, and label");
    }
  }
  return profile;
}

export function formatProfile(profile) {
  const rows = profile.bindings.map(({ input, label, safety }) =>
    `${input.padEnd(22)} ${label} [${safety}]`,
  );
  return `${profile.name} — ${profile.description}\n\n${rows.join("\n")}`;
}

async function main(argv) {
  const [command, path] = argv;
  if (!path || !["inspect", "validate"].includes(command)) {
    console.log(usage);
    process.exitCode = 64;
    return;
  }

  const profile = JSON.parse(await readFile(path, "utf8"));
  validateProfile(profile);

  if (command === "inspect") {
    console.log(formatProfile(profile));
  } else {
    console.log(`Valid: ${profile.id} (${profile.bindings.length} bindings)`);
  }
}

if (process.argv[1] && import.meta.url === new URL(process.argv[1], "file:").href) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(`MacroPilot Kit: ${error.message}`);
    process.exitCode = 1;
  });
}
