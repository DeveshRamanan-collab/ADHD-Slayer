import * as fs from 'node:fs';
import * as path from 'node:path';
import { App, type Stack } from 'aws-cdk-lib/core';
import { Template } from 'aws-cdk-lib/assertions';
import { buildFocusApp, type FocusEnvironment } from '../lib/app';
import { loadConfigs, type ConfigSources, type EnvName } from '../lib/config';

export const INFRA_DIR = path.join(__dirname, '..');
export const BACKEND_DIR = path.join(INFRA_DIR, '..');
export const REPO_DIR = path.join(BACKEND_DIR, '..');

export const cdkJson = JSON.parse(fs.readFileSync(path.join(INFRA_DIR, 'cdk.json'), 'utf8')) as {
  context: Record<string, unknown>;
};

/** Config sources exactly as `cdk synth` sees them with the committed cdk.json. */
export function sourcesFor(context: Record<string, unknown> = {}, env: Record<string, string | undefined> = {}): ConfigSources {
  const merged = { ...cdkJson.context, ...context };
  return { focus: merged.focus, context: (key) => merged[key], env };
}

let cached: { app: App; environments: FocusEnvironment[] } | undefined;

/**
 * The whole app (both environments), built once per test file. The first template request
 * synthesises everything, which also runs cdk-nag: an unacknowledged finding throws there.
 */
export function focusApp(): { app: App; environments: FocusEnvironment[] } {
  if (!cached) {
    const app = new App({ context: cdkJson.context });
    const environments = buildFocusApp(app, loadConfigs(sourcesFor()));
    cached = { app, environments };
  }
  return cached;
}

export function environment(name: EnvName): FocusEnvironment {
  const found = focusApp().environments.find((e) => e.config.envName === name);
  if (!found) throw new Error(`No ${name} environment in the test app`);
  return found;
}

const templates = new Map<Stack, Template>();
export function template(stack: Stack): Template {
  let t = templates.get(stack);
  if (!t) {
    t = Template.fromStack(stack);
    templates.set(stack, t);
  }
  return t;
}

/** Resources of one type as [logicalId, resource] pairs. */
export function resourcesOf(t: Template, type: string): Array<[string, { Properties: Record<string, any>; [key: string]: any }]> {
  return Object.entries(t.findResources(type)) as Array<[string, { Properties: Record<string, any> }]>;
}

export function readRepoFile(...parts: string[]): string {
  return fs.readFileSync(path.join(REPO_DIR, ...parts), 'utf8');
}

/** Parses a markdown table that follows a heading, returning rows as arrays of cell text. */
export function markdownTable(markdown: string, heading: string): string[][] {
  const start = markdown.indexOf(heading);
  if (start === -1) throw new Error(`Heading "${heading}" not found`);
  const lines = markdown.slice(start).split('\n').slice(1);
  const rows: string[][] = [];
  let inTable = false;
  for (const line of lines) {
    if (line.trim().startsWith('|')) {
      inTable = true;
      const cells = line.trim().replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
      if (cells.every((c) => /^:?-{3,}:?$/.test(c))) continue;
      rows.push(cells);
    } else if (inTable) {
      break;
    }
  }
  return rows.slice(1); // drop the header row
}

/** Environment variable names from a task definition's first container. */
export function containerEnvironment(taskDefinition: { Properties: Record<string, any> }): Record<string, unknown> {
  const container = taskDefinition.Properties.ContainerDefinitions[0];
  return Object.fromEntries((container.Environment ?? []).map((e: { Name: string; Value: unknown }) => [e.Name, e.Value]));
}

export function containerSecrets(taskDefinition: { Properties: Record<string, any> }): Record<string, unknown> {
  const container = taskDefinition.Properties.ContainerDefinitions[0];
  return Object.fromEntries((container.Secrets ?? []).map((s: { Name: string; ValueFrom: unknown }) => [s.Name, s.ValueFrom]));
}

export function taskDefinitionByFamily(t: Template, family: string): { Properties: Record<string, any> } {
  const found = resourcesOf(t, 'AWS::ECS::TaskDefinition').find(([, r]) => r.Properties.Family === family);
  if (!found) throw new Error(`No task definition with family ${family}`);
  return found[1];
}
