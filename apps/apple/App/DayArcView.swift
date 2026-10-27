import SwiftUI

struct DayArcView: View {
    let runs: [RunRecord]
    let schedules: [Schedule]
    var title: String?
    var height: CGFloat = 84
    var ground = Solar.plate

    var body: some View {
        TimelineView(.everyMinute) { context in
            let arc = DayArc(containing: context.date)
            let next = schedules.compactMap { $0.nextRun(after: context.date) }.min()
            let summary = arc.summary(runs, next: next)
            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title)
                        .font(.headline)
                        .fontDesign(.rounded)
                }
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(Solar.muted)
                    .lineLimit(2)
                DayArcCanvas(arc: arc, runs: arc.runs(runs), now: context.date, next: next, ground: ground)
                    .frame(height: height)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title ?? "Today")
            .accessibilityValue(summary)
        }
    }
}

struct DayArcCanvas: View {
    let arc: DayArc
    let runs: [RunRecord]
    let now: Date
    let next: Date?
    let ground: Color

    var body: some View {
        Canvas { context, size in
            let labelHeight: CGFloat = 14
            let rect = CGRect(x: 9, y: 9, width: size.width - 18, height: size.height - 18 - labelHeight)
            let nowFraction = arc.fraction(of: now) ?? 1
            context.fill(daylight(in: rect), with: .linearGradient(
                Gradient(colors: [Solar.sunlight.opacity(0.28), Solar.sunlight.opacity(0.04)]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.midY)
            ))
            context.stroke(
                Path { $0.move(to: CGPoint(x: rect.minX, y: rect.midY)); $0.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)) },
                with: .color(Solar.horizon),
                lineWidth: 1
            )
            context.stroke(curve(in: rect, from: 0, to: 1), with: .color(Solar.horizon), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 3]))
            context.stroke(curve(in: rect, from: 0, to: nowFraction), with: .color(Solar.sun), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            for (fraction, label) in hourLabels() {
                let point = CGPoint(x: rect.minX + rect.width * fraction, y: rect.maxY + labelHeight / 2 + 4)
                context.draw(Text(label).font(.caption2).foregroundStyle(Solar.muted), at: point)
            }
            let body = DayArc.altitude(at: nowFraction) >= 0 ? "sun.max.fill" : "moon.fill"
            if let symbol = context.resolveSymbol(id: body) {
                context.draw(symbol, at: DayArc.point(at: nowFraction, in: rect))
            }
            if let next, let fraction = arc.fraction(of: next) {
                let point = DayArc.point(at: fraction, in: rect)
                let ring = Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
                context.fill(ring, with: .color(ground))
                context.stroke(ring, with: .color(Solar.ink), lineWidth: 1.5)
            }
            for run in runs.sorted(by: { order($0.status()) < order($1.status()) }) {
                guard let fraction = arc.fraction(of: run.startedAt) else { continue }
                let status = run.status()
                let mark = mark(for: status, at: DayArc.point(at: fraction, in: rect))
                context.stroke(mark, with: .color(ground), lineWidth: 3)
                if status == .running {
                    context.fill(mark, with: .color(ground))
                    context.stroke(mark, with: .color(status.tint), lineWidth: 2)
                } else {
                    context.fill(mark, with: .color(status.tint))
                }
            }
        } symbols: {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 17))
                .foregroundStyle(Solar.sun)
                .tag("sun.max.fill")
            Image(systemName: "moon.fill")
                .font(.system(size: 13))
                .foregroundStyle(Solar.dusk)
                .tag("moon.fill")
        }
    }

    private func curve(in rect: CGRect, from start: Double, to end: Double) -> Path {
        Path { path in
            let steps = max(1, Int((end - start) * 96))
            for step in 0...steps {
                let point = DayArc.point(at: start + (end - start) * Double(step) / Double(steps), in: rect)
                step == 0 ? path.move(to: point) : path.addLine(to: point)
            }
        }
    }

    private func daylight(in rect: CGRect) -> Path {
        var path = curve(in: rect, from: 0.25, to: 0.75)
        path.closeSubpath()
        return path
    }

    private func hourLabels() -> [(Double, String)] {
        [6, 12, 18].compactMap { hour in
            guard let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: arc.interval.start), let fraction = arc.fraction(of: date) else { return nil }
            return (fraction, hour == 12 ? "Noon" : date.formatted(.dateTime.hour()))
        }
    }

    private func mark(for status: RunRecord.Status, at point: CGPoint) -> Path {
        guard status.isFailure else {
            let radius: CGFloat = 3.5
            return Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        }
        let size: CGFloat = 5.5
        return Path { path in
            path.move(to: CGPoint(x: point.x, y: point.y - size))
            path.addLine(to: CGPoint(x: point.x + size, y: point.y))
            path.addLine(to: CGPoint(x: point.x, y: point.y + size))
            path.addLine(to: CGPoint(x: point.x - size, y: point.y))
            path.closeSubpath()
        }
    }

    private func order(_ status: RunRecord.Status) -> Int {
        status.isFailure ? 2 : status == .running ? 1 : 0
    }
}
