import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { validateProfile } from "../bin/macropilot-kit.mjs";

test("AI Workbench profile is valid", async () => {
  const profile = JSON.parse(
    await readFile(new URL("../profiles/ai-workbench.json", import.meta.url), "utf8"),
  );
  assert.equal(validateProfile(profile).id, "ai-workbench");
});

test("duplicate inputs are rejected", () => {
  assert.throws(
    () => validateProfile({
      schemaVersion: 1,
      bindings: [
        { input: "f13", action: "one", label: "One", safety: "safe" },
        { input: "f13", action: "two", label: "Two", safety: "safe" },
      ],
    }),
    /inputs must be unique/,
  );
});
