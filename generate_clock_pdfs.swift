import AppKit
import CoreGraphics
import Foundation

enum ClockPageKind: String, CaseIterable {
    case hour
    case minute
    case second
    case combined

    var fileName: String {
        switch self {
        case .hour: return "认识时针_打印版.pdf"
        case .minute: return "认识分针_打印版.pdf"
        case .second: return "认识秒针_打印版.pdf"
        case .combined: return "时分秒合起来_打印版.pdf"
        }
    }

    var title: String {
        switch self {
        case .hour: return "认识时针"
        case .minute: return "认识分针"
        case .second: return "认识秒针"
        case .combined: return "时针、分针、秒针合起来"
        }
    }

    var subtitle: String {
        switch self {
        case .hour: return "时针短而粗，指向钟面上的小时。一天有 24 小时，时针一天走 2 圈。"
        case .minute: return "分针比较长，走一圈是 60 分钟，也就是 1 小时。"
        case .second: return "秒针最长最细，走得最快。走一圈是 60 秒，也就是 1 分钟。"
        case .combined: return "三根针一起读时间：先看时针，再看分针，最后看秒针。一天有 24 小时。"
        }
    }
}

let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("PDF输出/时钟学习", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let a4 = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
let margin: CGFloat = 42
let clockCenter = CGPoint(x: a4.width / 2, y: 438)
let clockRadius: CGFloat = 214

let titleFont = NSFont.systemFont(ofSize: 28, weight: .bold)
let subtitleFont = NSFont.systemFont(ofSize: 13, weight: .regular)
let numberFont = NSFont.monospacedDigitSystemFont(ofSize: 30, weight: .semibold)
let smallFont = NSFont.systemFont(ofSize: 12, weight: .regular)
let infoFont = NSFont.systemFont(ofSize: 15, weight: .medium)
let infoSmallFont = NSFont.systemFont(ofSize: 12, weight: .regular)

let black = NSColor(calibratedWhite: 0.08, alpha: 1)
let gray = NSColor(calibratedWhite: 0.48, alpha: 1)
let lightGray = NSColor(calibratedWhite: 0.82, alpha: 1)
let hourColor = NSColor(calibratedRed: 0.78, green: 0.14, blue: 0.14, alpha: 1)
let minuteColor = NSColor(calibratedRed: 0.08, green: 0.32, blue: 0.72, alpha: 1)
let secondColor = NSColor(calibratedRed: 0.02, green: 0.48, blue: 0.30, alpha: 1)

func drawText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor = black, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
    NSString(string: text).draw(in: rect, withAttributes: attrs)
}

func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
    CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
}

func angleForHour(_ hour: CGFloat, minute: CGFloat = 0) -> CGFloat {
    CGFloat.pi / 2 - ((hour.truncatingRemainder(dividingBy: 12) + minute / 60) / 12) * 2 * CGFloat.pi
}

func angleForMinuteOrSecond(_ value: CGFloat) -> CGFloat {
    CGFloat.pi / 2 - (value / 60) * 2 * CGFloat.pi
}

func drawLine(from start: CGPoint, to end: CGPoint, color: NSColor, width: CGFloat, cap: NSBezierPath.LineCapStyle = .butt) {
    color.setStroke()
    let path = NSBezierPath()
    path.lineWidth = width
    path.lineCapStyle = cap
    path.move(to: start)
    path.line(to: end)
    path.stroke()
}

func drawCircle(center: CGPoint, radius: CGFloat, stroke: NSColor, fill: NSColor? = nil, width: CGFloat = 1) {
    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let path = NSBezierPath(ovalIn: rect)
    if let fill {
        fill.setFill()
        path.fill()
    }
    stroke.setStroke()
    path.lineWidth = width
    path.stroke()
}

func drawClockFace(showMinuteLabels: Bool, showSecondLabels: Bool) {
    drawCircle(center: clockCenter, radius: clockRadius, stroke: black, fill: .white, width: 2.4)
    drawCircle(center: clockCenter, radius: clockRadius - 34, stroke: NSColor(calibratedWhite: 0.9, alpha: 1), width: 0.7)

    for tick in 0..<60 {
        let isHourTick = tick % 5 == 0
        let tickAngle = CGFloat.pi / 2 - CGFloat(tick) / 60 * 2 * CGFloat.pi
        let outer = point(center: clockCenter, radius: clockRadius - 8, angle: tickAngle)
        let inner = point(center: clockCenter, radius: clockRadius - (isHourTick ? 28 : 17), angle: tickAngle)
        drawLine(from: inner, to: outer, color: isHourTick ? black : lightGray, width: isHourTick ? 2.2 : 0.85, cap: .round)
    }

    for hour in 1...12 {
        let hourAngle = angleForHour(CGFloat(hour))
        let textCenter = point(center: clockCenter, radius: clockRadius - 58, angle: hourAngle)
        let rect = CGRect(x: textCenter.x - 24, y: textCenter.y - 18, width: 48, height: 36)
        drawText("\(hour)", in: rect, font: numberFont, alignment: .center)

        if showMinuteLabels {
            let minute = hour == 12 ? 60 : hour * 5
            let labelCenter = point(center: clockCenter, radius: clockRadius + 21, angle: hourAngle)
            drawText("\(minute)分", in: CGRect(x: labelCenter.x - 18, y: labelCenter.y - 8, width: 36, height: 16), font: smallFont, color: minuteColor, alignment: .center)
        }

        if showSecondLabels {
            let second = hour == 12 ? 60 : hour * 5
            let labelCenter = point(center: clockCenter, radius: clockRadius + 21, angle: hourAngle)
            drawText("\(second)秒", in: CGRect(x: labelCenter.x - 18, y: labelCenter.y - 8, width: 36, height: 16), font: smallFont, color: secondColor, alignment: .center)
        }
    }
}

func drawHand(angle: CGFloat, length: CGFloat, color: NSColor, width: CGFloat, label: String, labelOffset: CGFloat = 18) {
    let end = point(center: clockCenter, radius: length, angle: angle)
    drawLine(from: clockCenter, to: end, color: color, width: width, cap: .round)

    let labelPoint = point(center: clockCenter, radius: length + labelOffset, angle: angle)
    let labelRect = CGRect(x: labelPoint.x - 29, y: labelPoint.y - 12, width: 58, height: 24)
    drawText(label, in: labelRect, font: infoSmallFont, color: color, alignment: .center)
}

func drawLegend(kind: ClockPageKind) {
    let panel = CGRect(x: margin, y: 72, width: a4.width - margin * 2, height: 96)
    NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
    NSBezierPath(roundedRect: panel, xRadius: 7, yRadius: 7).fill()
    lightGray.setStroke()
    let border = NSBezierPath(roundedRect: panel, xRadius: 7, yRadius: 7)
    border.lineWidth = 0.8
    border.stroke()

    switch kind {
    case .hour:
        drawText("重点：时针看“几时”", in: CGRect(x: panel.minX + 18, y: panel.minY + 58, width: panel.width - 36, height: 22), font: infoFont, color: hourColor)
        drawText("钟面有 12 个小时数字；一天有 24 小时，所以时针一天绕表盘走 2 圈。", in: CGRect(x: panel.minX + 18, y: panel.minY + 28, width: panel.width - 36, height: 22), font: infoSmallFont, color: black)
    case .minute:
        drawText("重点：分针看“多少分”", in: CGRect(x: panel.minX + 18, y: panel.minY + 58, width: panel.width - 36, height: 22), font: infoFont, color: minuteColor)
        drawText("分针每走过一个大数字，就是 5 分钟；走完整个表盘是 60 分钟。", in: CGRect(x: panel.minX + 18, y: panel.minY + 28, width: panel.width - 36, height: 22), font: infoSmallFont, color: black)
    case .second:
        drawText("重点：秒针看“多少秒”", in: CGRect(x: panel.minX + 18, y: panel.minY + 58, width: panel.width - 36, height: 22), font: infoFont, color: secondColor)
        drawText("秒针每走一小格是 1 秒，走完整个表盘是 60 秒，也就是 1 分钟。", in: CGRect(x: panel.minX + 18, y: panel.minY + 28, width: panel.width - 36, height: 22), font: infoSmallFont, color: black)
    case .combined:
        drawText("读时间顺序：时针 → 分针 → 秒针", in: CGRect(x: panel.minX + 18, y: panel.minY + 58, width: panel.width - 36, height: 22), font: infoFont, color: black)
        drawText("示例图大约是 10 时 10 分 30 秒。一天有 24 小时。", in: CGRect(x: panel.minX + 18, y: panel.minY + 28, width: panel.width - 36, height: 22), font: infoSmallFont, color: black)
    }
}

func drawPage(kind: ClockPageKind) {
    drawText(kind.title, in: CGRect(x: margin, y: a4.height - 72, width: a4.width - margin * 2, height: 38), font: titleFont, alignment: .center)
    drawText(kind.subtitle, in: CGRect(x: margin, y: a4.height - 104, width: a4.width - margin * 2, height: 28), font: subtitleFont, color: gray, alignment: .center)

    switch kind {
    case .hour:
        drawClockFace(showMinuteLabels: false, showSecondLabels: false)
        drawHand(angle: angleForHour(3), length: 112, color: hourColor, width: 13, label: "时针")
    case .minute:
        drawClockFace(showMinuteLabels: true, showSecondLabels: false)
        drawHand(angle: angleForMinuteOrSecond(40), length: 166, color: minuteColor, width: 8, label: "分针")
    case .second:
        drawClockFace(showMinuteLabels: false, showSecondLabels: true)
        drawHand(angle: angleForMinuteOrSecond(10), length: 184, color: secondColor, width: 3, label: "秒针")
    case .combined:
        drawClockFace(showMinuteLabels: false, showSecondLabels: false)
        drawHand(angle: angleForHour(10, minute: 10), length: 112, color: hourColor, width: 12, label: "时针", labelOffset: 10)
        drawHand(angle: angleForMinuteOrSecond(10), length: 165, color: minuteColor, width: 7, label: "分针", labelOffset: 10)
        drawHand(angle: angleForMinuteOrSecond(30), length: 184, color: secondColor, width: 3, label: "秒针", labelOffset: 8)
    }

    drawCircle(center: clockCenter, radius: 9, stroke: black, fill: black, width: 1)
    drawCircle(center: clockCenter, radius: 4, stroke: .white, fill: .white, width: 1)
    drawLegend(kind: kind)
}

func createPDF(at url: URL, pages: [ClockPageKind]) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    for page in pages {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawPage(kind: page)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }
    context.closePDF()
}

struct ClockTime {
    let hour: Int
    let minute: Int
    let second: Int?

    var includesSeconds: Bool {
        second != nil
    }

    var answerText: String {
        if let second {
            return String(format: "%d时%02d分%02d秒", hour, minute, second)
        }
        if minute == 0 {
            return "\(hour)时"
        }
        return String(format: "%d时%02d分", hour, minute)
    }
}

struct TimeSection {
    let title: String
    let subtitle: String
    let times: [ClockTime]
}

enum TimePageMode {
    case examples
    case practice
    case answers

    var titlePrefix: String {
        switch self {
        case .examples: return "不同时间例题"
        case .practice: return "读时间练习"
        case .answers: return "读时间练习答案"
        }
    }
}

let exampleSections = [
    TimeSection(
        title: "例题 1：整点",
        subtitle: "分针指向 12，就是整点；先看短短的红色时针。",
        times: [
            ClockTime(hour: 1, minute: 0, second: nil),
            ClockTime(hour: 3, minute: 0, second: nil),
            ClockTime(hour: 6, minute: 0, second: nil),
            ClockTime(hour: 9, minute: 0, second: nil),
            ClockTime(hour: 11, minute: 0, second: nil),
            ClockTime(hour: 12, minute: 0, second: nil),
        ]
    ),
    TimeSection(
        title: "例题 2：半点、一刻和三刻",
        subtitle: "分针指向 6 是 30 分，指向 3 是 15 分，指向 9 是 45 分。",
        times: [
            ClockTime(hour: 2, minute: 30, second: nil),
            ClockTime(hour: 4, minute: 15, second: nil),
            ClockTime(hour: 7, minute: 45, second: nil),
            ClockTime(hour: 10, minute: 30, second: nil),
            ClockTime(hour: 8, minute: 15, second: nil),
            ClockTime(hour: 12, minute: 45, second: nil),
        ]
    ),
    TimeSection(
        title: "例题 3：5 分钟刻度",
        subtitle: "分针每走过一个大数字，就是增加 5 分钟。",
        times: [
            ClockTime(hour: 1, minute: 10, second: nil),
            ClockTime(hour: 5, minute: 25, second: nil),
            ClockTime(hour: 6, minute: 40, second: nil),
            ClockTime(hour: 11, minute: 50, second: nil),
            ClockTime(hour: 9, minute: 35, second: nil),
            ClockTime(hour: 3, minute: 5, second: nil),
        ]
    ),
    TimeSection(
        title: "例题 4：带秒钟",
        subtitle: "读时间顺序：时针、分针、秒针。绿色细针是秒针。",
        times: [
            ClockTime(hour: 7, minute: 20, second: 15),
            ClockTime(hour: 10, minute: 10, second: 30),
            ClockTime(hour: 2, minute: 45, second: 50),
            ClockTime(hour: 4, minute: 5, second: 40),
            ClockTime(hour: 12, minute: 30, second: 20),
            ClockTime(hour: 8, minute: 55, second: 5),
        ]
    ),
]

let practiceSections = [
    TimeSection(
        title: "练习 1：整点和半点",
        subtitle: "看红色时针和蓝色分针，把时间写出来。",
        times: [
            ClockTime(hour: 2, minute: 0, second: nil),
            ClockTime(hour: 5, minute: 0, second: nil),
            ClockTime(hour: 8, minute: 0, second: nil),
            ClockTime(hour: 10, minute: 0, second: nil),
            ClockTime(hour: 1, minute: 30, second: nil),
            ClockTime(hour: 4, minute: 30, second: nil),
        ]
    ),
    TimeSection(
        title: "练习 2：15 分、45 分和 5 分钟",
        subtitle: "分针指到哪个大数字，就用 5 分钟去数。",
        times: [
            ClockTime(hour: 3, minute: 15, second: nil),
            ClockTime(hour: 6, minute: 45, second: nil),
            ClockTime(hour: 9, minute: 5, second: nil),
            ClockTime(hour: 11, minute: 25, second: nil),
            ClockTime(hour: 7, minute: 40, second: nil),
            ClockTime(hour: 12, minute: 50, second: nil),
        ]
    ),
    TimeSection(
        title: "练习 3：混合读时间",
        subtitle: "先判断几时，再看多少分。",
        times: [
            ClockTime(hour: 1, minute: 55, second: nil),
            ClockTime(hour: 5, minute: 10, second: nil),
            ClockTime(hour: 6, minute: 35, second: nil),
            ClockTime(hour: 8, minute: 20, second: nil),
            ClockTime(hour: 10, minute: 45, second: nil),
            ClockTime(hour: 2, minute: 30, second: nil),
        ]
    ),
    TimeSection(
        title: "练习 4：带秒钟",
        subtitle: "绿色秒针每走一小格是 1 秒。",
        times: [
            ClockTime(hour: 1, minute: 10, second: 10),
            ClockTime(hour: 3, minute: 25, second: 35),
            ClockTime(hour: 6, minute: 40, second: 45),
            ClockTime(hour: 9, minute: 55, second: 5),
            ClockTime(hour: 11, minute: 5, second: 20),
            ClockTime(hour: 12, minute: 50, second: 55),
        ]
    ),
]

func drawSmallClockFace(center: CGPoint, radius: CGFloat) {
    drawCircle(center: center, radius: radius, stroke: black, fill: .white, width: 1.3)

    for tick in 0..<60 {
        let isHourTick = tick % 5 == 0
        let tickAngle = CGFloat.pi / 2 - CGFloat(tick) / 60 * 2 * CGFloat.pi
        let outer = point(center: center, radius: radius - 3, angle: tickAngle)
        let inner = point(center: center, radius: radius - (isHourTick ? 10 : 6), angle: tickAngle)
        drawLine(from: inner, to: outer, color: isHourTick ? black : lightGray, width: isHourTick ? 1.2 : 0.45, cap: .round)
    }

    let miniNumberFont = NSFont.monospacedDigitSystemFont(ofSize: max(8, radius * 0.2), weight: .semibold)
    let numberBox = max(14, radius * 0.36)
    for hour in 1...12 {
        let hourAngle = angleForHour(CGFloat(hour))
        let textCenter = point(center: center, radius: radius - radius * 0.36, angle: hourAngle)
        drawText(
            "\(hour)",
            in: CGRect(x: textCenter.x - numberBox / 2, y: textCenter.y - numberBox * 0.43, width: numberBox, height: numberBox * 0.86),
            font: miniNumberFont,
            alignment: .center
        )
    }
}

func drawSmallHand(center: CGPoint, angle: CGFloat, length: CGFloat, color: NSColor, width: CGFloat) {
    let end = point(center: center, radius: length, angle: angle)
    drawLine(from: center, to: end, color: color, width: width, cap: .round)
}

func drawClockCard(time: ClockTime, number: Int, frame: CGRect, mode: TimePageMode) {
    let borderPath = NSBezierPath(roundedRect: frame, xRadius: 7, yRadius: 7)
    NSColor.white.setFill()
    borderPath.fill()
    NSColor(calibratedWhite: 0.84, alpha: 1).setStroke()
    borderPath.lineWidth = 0.7
    borderPath.stroke()

    drawText("\(number).", in: CGRect(x: frame.minX + 10, y: frame.maxY - 26, width: 34, height: 18), font: infoSmallFont, color: gray)

    let center = CGPoint(x: frame.midX, y: frame.minY + 108)
    let radius: CGFloat = 63
    drawSmallClockFace(center: center, radius: radius)
    drawSmallHand(center: center, angle: angleForHour(CGFloat(time.hour), minute: CGFloat(time.minute)), length: radius * 0.46, color: hourColor, width: 5)
    drawSmallHand(center: center, angle: angleForMinuteOrSecond(CGFloat(time.minute)), length: radius * 0.72, color: minuteColor, width: 3.2)

    if let second = time.second {
        drawSmallHand(center: center, angle: angleForMinuteOrSecond(CGFloat(second)), length: radius * 0.82, color: secondColor, width: 1.35)
    }

    drawCircle(center: center, radius: 3.6, stroke: black, fill: black, width: 0.8)
    drawCircle(center: center, radius: 1.6, stroke: .white, fill: .white, width: 0.5)

    switch mode {
    case .examples:
        drawText(time.answerText, in: CGRect(x: frame.minX + 10, y: frame.minY + 12, width: frame.width - 20, height: 21), font: infoFont, color: black, alignment: .center)
    case .practice:
        let blank = time.includesSeconds ? "____时 ____分 ____秒" : "____时 ____分"
        drawText(blank, in: CGRect(x: frame.minX + 10, y: frame.minY + 12, width: frame.width - 20, height: 21), font: infoFont, color: black, alignment: .center)
    case .answers:
        drawText(time.answerText, in: CGRect(x: frame.minX + 10, y: frame.minY + 12, width: frame.width - 20, height: 21), font: infoFont, color: black, alignment: .center)
    }
}

let compactExampleTimes = [
    ClockTime(hour: 1, minute: 0, second: nil),
    ClockTime(hour: 2, minute: 30, second: nil),
    ClockTime(hour: 3, minute: 15, second: nil),
    ClockTime(hour: 4, minute: 45, second: nil),
    ClockTime(hour: 5, minute: 10, second: nil),
    ClockTime(hour: 6, minute: 25, second: nil),
    ClockTime(hour: 7, minute: 40, second: nil),
    ClockTime(hour: 8, minute: 55, second: nil),
    ClockTime(hour: 9, minute: 5, second: nil),
    ClockTime(hour: 10, minute: 20, second: nil),
    ClockTime(hour: 11, minute: 35, second: nil),
    ClockTime(hour: 12, minute: 50, second: nil),
]

let compactPracticeTimes = [
    ClockTime(hour: 12, minute: 0, second: nil),
    ClockTime(hour: 1, minute: 20, second: nil),
    ClockTime(hour: 2, minute: 45, second: nil),
    ClockTime(hour: 3, minute: 30, second: nil),
    ClockTime(hour: 4, minute: 5, second: nil),
    ClockTime(hour: 5, minute: 50, second: nil),
    ClockTime(hour: 6, minute: 15, second: nil),
    ClockTime(hour: 7, minute: 35, second: nil),
    ClockTime(hour: 8, minute: 10, second: nil),
    ClockTime(hour: 9, minute: 55, second: nil),
    ClockTime(hour: 10, minute: 25, second: nil),
    ClockTime(hour: 11, minute: 40, second: nil),
]

func drawCompactClockCard(time: ClockTime, number: Int, frame: CGRect, mode: TimePageMode) {
    drawText("\(number).", in: CGRect(x: frame.minX + 2, y: frame.maxY - 18, width: 28, height: 14), font: smallFont, color: gray)

    let center = CGPoint(x: frame.midX, y: frame.minY + 76)
    let radius: CGFloat = 43
    drawSmallClockFace(center: center, radius: radius)
    drawSmallHand(center: center, angle: angleForHour(CGFloat(time.hour), minute: CGFloat(time.minute)), length: radius * 0.46, color: hourColor, width: 3.4)
    drawSmallHand(center: center, angle: angleForMinuteOrSecond(CGFloat(time.minute)), length: radius * 0.72, color: minuteColor, width: 2.2)
    drawCircle(center: center, radius: 2.7, stroke: black, fill: black, width: 0.6)
    drawCircle(center: center, radius: 1.1, stroke: .white, fill: .white, width: 0.4)

    switch mode {
    case .examples, .answers:
        drawText(time.answerText, in: CGRect(x: frame.minX, y: frame.minY + 7, width: frame.width, height: 18), font: smallFont, color: black, alignment: .center)
    case .practice:
        drawText("____时 ____分", in: CGRect(x: frame.minX, y: frame.minY + 7, width: frame.width, height: 18), font: smallFont, color: black, alignment: .center)
    }
}

func drawCompactTwelveClockPage(times: [ClockTime], mode: TimePageMode) {
    let title: String
    let subtitle: String
    switch mode {
    case .examples:
        title = "一页 12 个小表盘例题"
        subtitle = "每个小表盘都是一个不同时间，按“时针、分针”的顺序读。"
    case .practice:
        title = "一页 12 个小表盘练习"
        subtitle = "看表盘，把每个时间写在下面。"
    case .answers:
        title = "一页 12 个小表盘答案"
        subtitle = "对应“一页 12 个小表盘练习”。"
    }

    drawText(title, in: CGRect(x: margin, y: a4.height - 60, width: a4.width - margin * 2, height: 30), font: titleFont, alignment: .center)
    drawText(subtitle, in: CGRect(x: margin, y: a4.height - 88, width: a4.width - margin * 2, height: 22), font: subtitleFont, color: gray, alignment: .center)

    let columns = 3
    let rows = 4
    let gridTop: CGFloat = 720
    let gridBottom: CGFloat = 42
    let gridWidth = a4.width - margin * 2
    let cellWidth = gridWidth / CGFloat(columns)
    let cellHeight = (gridTop - gridBottom) / CGFloat(rows)

    for index in 0..<min(times.count, columns * rows) {
        let row = index / columns
        let col = index % columns
        let frame = CGRect(
            x: margin + CGFloat(col) * cellWidth + 5,
            y: gridTop - CGFloat(row + 1) * cellHeight + 7,
            width: cellWidth - 10,
            height: cellHeight - 14
        )
        drawCompactClockCard(time: times[index], number: index + 1, frame: frame, mode: mode)
    }
}

func drawTimeSectionPage(section: TimeSection, mode: TimePageMode, pageNumber: Int) {
    drawText(mode.titlePrefix, in: CGRect(x: margin, y: a4.height - 62, width: a4.width - margin * 2, height: 32), font: titleFont, alignment: .center)
    drawText(section.title, in: CGRect(x: margin, y: a4.height - 92, width: a4.width - margin * 2, height: 24), font: infoFont, alignment: .center)
    drawText(section.subtitle, in: CGRect(x: margin, y: a4.height - 116, width: a4.width - margin * 2, height: 24), font: subtitleFont, color: gray, alignment: .center)

    let cardWidth: CGFloat = 239
    let cardHeight: CGFloat = 194
    let xPositions = [margin, a4.width - margin - cardWidth]
    let yPositions: [CGFloat] = [514, 300, 86]

    for index in 0..<section.times.count {
        let row = index / 2
        let col = index % 2
        let frame = CGRect(x: xPositions[col], y: yPositions[row], width: cardWidth, height: cardHeight)
        drawClockCard(time: section.times[index], number: index + 1, frame: frame, mode: mode)
    }

    drawText("第 \(pageNumber) 页", in: CGRect(x: margin, y: 34, width: a4.width - margin * 2, height: 14), font: smallFont, color: gray, alignment: .center)
}

func createTimePDF(at url: URL, sections: [TimeSection], mode: TimePageMode) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    for (index, section) in sections.enumerated() {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawTimeSectionPage(section: section, mode: mode, pageNumber: index + 1)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }
    context.closePDF()
}

func createFullStudyPDF(at url: URL) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    for page in ClockPageKind.allCases {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawPage(kind: page)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }

    for (index, section) in exampleSections.enumerated() {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawTimeSectionPage(section: section, mode: .examples, pageNumber: index + 1)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }

    for (index, section) in practiceSections.enumerated() {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawTimeSectionPage(section: section, mode: .practice, pageNumber: index + 1)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }

    for (index, section) in practiceSections.enumerated() {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawTimeSectionPage(section: section, mode: .answers, pageNumber: index + 1)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    drawCompactTwelveClockPage(times: compactExampleTimes, mode: .examples)
    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    drawCompactTwelveClockPage(times: compactPracticeTimes, mode: .practice)
    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    drawCompactTwelveClockPage(times: compactPracticeTimes, mode: .answers)
    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()

    context.closePDF()
}

func createSingleCompactPDF(at url: URL, times: [ClockTime], mode: TimePageMode) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    drawCompactTwelveClockPage(times: times, mode: mode)
    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()
    context.closePDF()
}

for kind in ClockPageKind.allCases {
    createPDF(at: outputDirectory.appendingPathComponent(kind.fileName), pages: [kind])
}

createPDF(
    at: outputDirectory.appendingPathComponent("认识时钟_四页合订打印版.pdf"),
    pages: ClockPageKind.allCases
)

createTimePDF(
    at: outputDirectory.appendingPathComponent("不同时间例题_打印版.pdf"),
    sections: exampleSections,
    mode: .examples
)

createTimePDF(
    at: outputDirectory.appendingPathComponent("读时间练习_打印版.pdf"),
    sections: practiceSections,
    mode: .practice
)

createTimePDF(
    at: outputDirectory.appendingPathComponent("读时间练习答案_打印版.pdf"),
    sections: practiceSections,
    mode: .answers
)

createSingleCompactPDF(
    at: outputDirectory.appendingPathComponent("一页12个小表盘例题_打印版.pdf"),
    times: compactExampleTimes,
    mode: .examples
)

createSingleCompactPDF(
    at: outputDirectory.appendingPathComponent("一页12个小表盘练习_打印版.pdf"),
    times: compactPracticeTimes,
    mode: .practice
)

createSingleCompactPDF(
    at: outputDirectory.appendingPathComponent("一页12个小表盘练习答案_打印版.pdf"),
    times: compactPracticeTimes,
    mode: .answers
)

createFullStudyPDF(
    at: outputDirectory.appendingPathComponent("认识时钟_完整合订打印版.pdf")
)

print("已生成时钟学习 PDF：\(outputDirectory.path)")
