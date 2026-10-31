export type Point = { x: number; y: number };
export type Run = { hour: number; failed: boolean };
export type RunState = "scheduled" | "next" | "running" | "passed" | "failed";

export const latitude = 37.77;
export const declination = 23.44;
export const dayStart = 6;
export const dayEnd = 19.5;
export const runDuration = 0.25;
export const tilt = 0.46;
export const turn = 156;

export const dayRuns: Run[] = [
  { hour: 7, failed: false },
  { hour: 9, failed: false },
  { hour: 13, failed: false },
  { hour: 15, failed: true },
  { hour: 17, failed: false },
];

const radians = (degrees: number) => (degrees * Math.PI) / 180;

export function hourAt(progress: number) {
  const clamped = Math.min(Math.max(progress, 0), 1);
  return dayStart + clamped * (dayEnd - dayStart);
}

export function sunAt(hour: number) {
  const angle = radians((hour - 12) * 15);
  const phi = radians(latitude);
  const delta = radians(declination);
  return {
    east: -Math.cos(delta) * Math.sin(angle),
    north: Math.sin(delta) * Math.cos(phi) - Math.cos(delta) * Math.sin(phi) * Math.cos(angle),
    up: Math.sin(delta) * Math.sin(phi) + Math.cos(delta) * Math.cos(phi) * Math.cos(angle),
  };
}

export function hourLine(hour: number): Point {
  const angle = radians((hour - 12) * 15);
  const x = Math.sin(radians(latitude)) * Math.sin(angle);
  const y = Math.cos(angle);
  const length = Math.hypot(x, y);
  return { x: x / length, y: y / length };
}

export function gnomonHeight(length: number) {
  return length * Math.tan(radians(latitude));
}

export function shadowTip(hour: number, length: number, limit: number): Point | null {
  const sun = sunAt(hour);
  if (sun.up <= 0) return null;
  const height = gnomonHeight(length);
  const tip = { x: (-height * sun.east) / sun.up, y: length - (height * sun.north) / sun.up };
  const distance = Math.hypot(tip.x, tip.y);
  if (distance <= limit) return tip;
  return { x: (tip.x / distance) * limit, y: (tip.y / distance) * limit };
}

export function shadowStrength(hour: number) {
  return Math.min(Math.max(sunAt(hour).up / 0.12, 0), 1);
}

export function project(point: Point, height = 0): Point {
  const angle = radians(turn);
  return {
    x: point.x * Math.cos(angle) + point.y * Math.sin(angle),
    y: tilt * (point.x * Math.sin(angle) - point.y * Math.cos(angle)) - height,
  };
}

export function formatHour(hour: number) {
  const minutes = Math.floor(Math.round(hour * 6000) / 100);
  const hours = Math.floor(minutes / 60) % 24;
  const minute = String(minutes % 60).padStart(2, "0");
  return `${hours % 12 === 0 ? 12 : hours % 12}:${minute} ${hours < 12 ? "AM" : "PM"}`;
}

export function runState(run: Run, hour: number, runs: Run[]): RunState {
  if (run.hour <= hour) {
    if (hour < run.hour + runDuration) return "running";
    return run.failed ? "failed" : "passed";
  }
  return nextRun(runs, hour) === run ? "next" : "scheduled";
}

export function nextRun(runs: Run[], hour: number) {
  return runs.filter((run) => run.hour > hour).sort((a, b) => a.hour - b.hour)[0];
}

export function summary(runs: Run[], hour: number) {
  const states = runs.map((run) => runState(run, hour, runs));
  const counts = [
    [states.filter((state) => state === "passed").length, "passed"],
    [states.filter((state) => state === "failed").length, "failed"],
    [states.filter((state) => state === "running").length, "running"],
  ] as const;
  const parts = counts.filter(([count]) => count > 0).map(([count, label]) => `${count} ${label}`);
  let text = parts.length > 0 ? parts.join(", ") : "No runs today";
  const next = nextRun(runs, hour);
  if (next) text += `. Next run at ${formatHour(next.hour)}`;
  return `${text}.`;
}
