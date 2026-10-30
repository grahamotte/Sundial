import {
  dayEnd,
  dayStart,
  formatHour,
  gnomonHeight,
  hourAt,
  hourLine,
  nextRun,
  project,
  runState,
  shadowStrength,
  shadowTip,
  summary,
  sunAt,
  tilt,
  turn,
  type Run,
} from "../../src/lib/sun";
import { describe, expect, test } from "vitest";

const runs: Run[] = [
  { hour: 7, failed: false },
  { hour: 15, failed: true },
  { hour: 9, failed: false },
];

describe("hourAt", () => {
  test("maps scroll progress onto the day", () => {
    expect(hourAt(0)).toBe(dayStart);
    expect(hourAt(1)).toBe(dayEnd);
    expect(hourAt(0.5)).toBe(12.75);
  });

  test("clamps progress outside the page", () => {
    expect(hourAt(-0.2)).toBe(dayStart);
    expect(hourAt(1.4)).toBe(dayEnd);
  });
});

describe("sunAt", () => {
  test("puts the noon sun due south at its highest", () => {
    const sun = sunAt(12);
    expect(sun.east).toBeCloseTo(0);
    expect(sun.north).toBeCloseTo(-0.2475, 3);
    expect(sun.up).toBeCloseTo(0.9689, 3);
  });

  test("rises in the east and sets in the west", () => {
    expect(sunAt(8).east).toBeGreaterThan(0);
    expect(sunAt(16).east).toBeLessThan(0);
    expect(sunAt(dayStart).up).toBeGreaterThan(0);
    expect(sunAt(dayEnd).up).toBeLessThan(0);
  });
});

describe("hourLine", () => {
  test("points north at noon and west and east at six", () => {
    expect(hourLine(12).x).toBeCloseTo(0);
    expect(hourLine(12).y).toBeCloseTo(1);
    expect(hourLine(6).x).toBeCloseTo(-1);
    expect(hourLine(6).y).toBeCloseTo(0);
    expect(hourLine(18).x).toBeCloseTo(1);
  });

  test("bunches morning lines toward noon like a horizontal dial", () => {
    const line = hourLine(9);
    expect(line.x).toBeCloseTo(-0.5222, 3);
    expect(line.y).toBeCloseTo(0.8528, 3);
  });
});

describe("shadowTip", () => {
  test("falls on the hour line for the time", () => {
    for (const hour of [6.5, 9, 11.25, 14, 17.75]) {
      const tip = shadowTip(hour, 90, 1000)!;
      const line = hourLine(hour);
      expect(tip.x * line.y - tip.y * line.x).toBeCloseTo(0, 6);
      expect(tip.x * line.x + tip.y * line.y).toBeGreaterThan(0);
    }
  });

  test("is shortest at noon", () => {
    const length = (hour: number) => Math.hypot(shadowTip(hour, 90, 1000)!.x, shadowTip(hour, 90, 1000)!.y);
    expect(length(12)).toBeLessThan(length(10));
    expect(length(12)).toBeLessThan(length(14));
    expect(length(12)).toBeCloseTo(90 + gnomonHeight(90) * (0.2475 / 0.9689), 0);
  });

  test("is limited to the plate", () => {
    const tip = shadowTip(6.25, 90, 150)!;
    expect(Math.hypot(tip.x, tip.y)).toBeCloseTo(150);
  });

  test("is missing after sunset", () => {
    expect(shadowTip(dayEnd, 90, 150)).toBeNull();
  });
});

describe("shadowStrength", () => {
  test("fades as the sun sets", () => {
    expect(shadowStrength(12)).toBe(1);
    expect(shadowStrength(19.2)).toBeGreaterThan(0);
    expect(shadowStrength(19.2)).toBeLessThan(1);
    expect(shadowStrength(dayEnd)).toBe(0);
  });
});

describe("project", () => {
  test("turns and tilts the plate toward the viewer", () => {
    const angle = (turn * Math.PI) / 180;
    expect(project({ x: 0, y: 0 }).x).toBeCloseTo(0);
    expect(project({ x: 0, y: 0 }).y).toBeCloseTo(0);
    const north = project({ x: 0, y: 1 });
    expect(north.x).toBeCloseTo(Math.sin(angle));
    expect(north.y).toBeCloseTo(-tilt * Math.cos(angle));
  });

  test("raises points by their height", () => {
    expect(project({ x: 0, y: 0 }, 10).y).toBeCloseTo(-10);
  });
});

describe("formatHour", () => {
  test("formats a twelve-hour clock time", () => {
    expect(formatHour(6)).toBe("6:00 AM");
    expect(formatHour(12)).toBe("12:00 PM");
    expect(formatHour(0)).toBe("12:00 AM");
    expect(formatHour(dayEnd)).toBe("7:30 PM");
    expect(formatHour(13.999)).toBe("1:59 PM");
    expect(formatHour(9 + 5 / 60)).toBe("9:05 AM");
  });
});

describe("runState", () => {
  test("follows a run from scheduled to its result", () => {
    expect(runState(runs[1], 8, runs)).toBe("scheduled");
    expect(runState(runs[2], 8, runs)).toBe("next");
    expect(runState(runs[2], 9.1, runs)).toBe("running");
    expect(runState(runs[2], 10, runs)).toBe("passed");
    expect(runState(runs[1], 16, runs)).toBe("failed");
  });
});

describe("nextRun", () => {
  test("finds the earliest run after the time", () => {
    expect(nextRun(runs, 7.5)).toBe(runs[2]);
    expect(nextRun(runs, 16)).toBeUndefined();
  });
});

describe("summary", () => {
  test("reads like the day arc", () => {
    expect(summary(runs, 6)).toBe("No runs today. Next run at 7:00 AM.");
    expect(summary(runs, 7.1)).toBe("1 running. Next run at 9:00 AM.");
    expect(summary(runs, 12)).toBe("2 passed. Next run at 3:00 PM.");
    expect(summary(runs, 16)).toBe("2 passed, 1 failed.");
  });
});
