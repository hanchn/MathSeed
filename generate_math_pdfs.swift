import AppKit
import CoreGraphics
import Foundation

struct Problem: Hashable {
    let a: Int
    let b: Int
    let op: String

    var answer: Int {
        op == "+" ? a + b : a - b
    }

    var expression: String {
        "\(a) \(op) \(b)"
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

let sheetCount = 10
let problemsPerSheet = 48
let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("PDF输出", isDirectory: true)
let simpleOutputDirectory = outputDirectory.appendingPathComponent("简单加减练习", isDirectory: true)
let easyTwoDigitOutputDirectory = outputDirectory.appendingPathComponent("简单两位数加减练习", isDirectory: true)

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: simpleOutputDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: easyTwoDigitOutputDirectory, withIntermediateDirectories: true)

let a4 = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
let margin: CGFloat = 40
let columnCount = 2
let rowCount = 24
let usableWidth = a4.width - margin * 2
let usableHeight: CGFloat = 630
let columnWidth = usableWidth / CGFloat(columnCount)
let rowHeight = usableHeight / CGFloat(rowCount)

let titleFont = NSFont.systemFont(ofSize: 21, weight: .semibold)
let headerFont = NSFont.systemFont(ofSize: 12, weight: .regular)
let problemFont = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
let answerFont = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
let footerFont = NSFont.systemFont(ofSize: 9, weight: .regular)

let textColor = NSColor(calibratedWhite: 0.12, alpha: 1)
let lightColor = NSColor(calibratedWhite: 0.78, alpha: 1)

func drawText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor = textColor, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
    NSString(string: text).draw(in: rect, withAttributes: attrs)
}

func drawLine(from start: CGPoint, to end: CGPoint, color: NSColor = lightColor, width: CGFloat = 0.7) {
    color.setStroke()
    let path = NSBezierPath()
    path.lineWidth = width
    path.move(to: start)
    path.line(to: end)
    path.stroke()
}

func makeProblem(isAddition: Bool, rng: inout SeededGenerator) -> Problem {
    if isAddition {
        while true {
            let a = Int.random(in: 10...89, using: &rng)
            let b = Int.random(in: 10...89, using: &rng)
            let answer = a + b
            if answer <= 99 {
                return Problem(a: a, b: b, op: "+")
            }
        }
    } else {
        let b = Int.random(in: 10...99, using: &rng)
        let a = Int.random(in: b...99, using: &rng)
        return Problem(a: a, b: b, op: "-")
    }
}

func makeWorksheet(seed: UInt64, index: Int) -> [Problem] {
    var rng = SeededGenerator(seed: seed + UInt64(index) * 10_007)
    var problems: [Problem] = []
    var seen = Set<Problem>()
    var operations = Array(repeating: true, count: problemsPerSheet / 2)
        + Array(repeating: false, count: problemsPerSheet - problemsPerSheet / 2)
    operations.shuffle(using: &rng)

    for isAddition in operations {
        var problem = makeProblem(isAddition: isAddition, rng: &rng)
        while seen.contains(problem) {
            problem = makeProblem(isAddition: isAddition, rng: &rng)
        }
        problems.append(problem)
        seen.insert(problem)
    }
    return problems
}

func drawWorksheet(_ problems: [Problem], sheetNumber: Int, showAnswers: Bool, into url: URL) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

    drawText(
        showAnswers ? "两位数加减练习答案（第 \(sheetNumber) 份）" : "两位数加减练习（第 \(sheetNumber) 份）",
        in: CGRect(x: margin, y: a4.height - 62, width: usableWidth, height: 28),
        font: titleFont,
        alignment: .center
    )
    drawText(
        "姓名：________________    日期：________________    用时：________________",
        in: CGRect(x: margin, y: a4.height - 94, width: usableWidth, height: 20),
        font: headerFont
    )
    drawText(
        "题目：两个两位数相加或相减，答案均为个位数或两位数。",
        in: CGRect(x: margin, y: a4.height - 116, width: usableWidth, height: 18),
        font: headerFont,
        color: NSColor(calibratedWhite: 0.32, alpha: 1)
    )

    let gridTop = a4.height - 145
    for col in 1..<columnCount {
        let x = margin + CGFloat(col) * columnWidth - 10
        drawLine(from: CGPoint(x: x, y: gridTop - usableHeight - 6), to: CGPoint(x: x, y: gridTop + 4), width: 0.45)
    }

    for i in 0..<problems.count {
        let col = i / rowCount
        let row = i % rowCount
        let x = margin + CGFloat(col) * columnWidth
        let y = gridTop - CGFloat(row + 1) * rowHeight + 10
        let p = problems[i]
        let number = String(format: "%2d.", i + 1)
        let suffix = showAnswers ? String(format: " = %2d", p.answer) : " = _____"
        let line = "\(number)  \(p.expression)\(suffix)"
        drawText(line, in: CGRect(x: x, y: y, width: columnWidth - 18, height: 24), font: showAnswers ? answerFont : problemFont)
    }

    drawLine(from: CGPoint(x: margin, y: 58), to: CGPoint(x: a4.width - margin, y: 58), width: 0.55)
    drawText(
        "生成日期：2026-06-03    每份 \(problemsPerSheet) 题，24 道加法 + 24 道减法。",
        in: CGRect(x: margin, y: 38, width: usableWidth, height: 14),
        font: footerFont,
        color: NSColor(calibratedWhite: 0.42, alpha: 1),
        alignment: .center
    )

    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()
    context.closePDF()
}

let simpleSheetCount = 10
let simpleProblemsPerSheet = 36

func makeSimpleProblem(isAddition: Bool, rng: inout SeededGenerator) -> Problem {
    if isAddition {
        while true {
            let a = Int.random(in: 0...10, using: &rng)
            let b = Int.random(in: 0...10, using: &rng)
            if a + b <= 10 {
                return Problem(a: a, b: b, op: "+")
            }
        }
    }

    let a = Int.random(in: 0...10, using: &rng)
    let b = Int.random(in: 0...a, using: &rng)
    return Problem(a: a, b: b, op: "-")
}

func makeSimpleWorksheet(seed: UInt64, index: Int) -> [Problem] {
    var rng = SeededGenerator(seed: seed + UInt64(index) * 23_017)
    var problems: [Problem] = []
    var seen = Set<Problem>()
    var operations = Array(repeating: true, count: simpleProblemsPerSheet / 2)
        + Array(repeating: false, count: simpleProblemsPerSheet - simpleProblemsPerSheet / 2)
    operations.shuffle(using: &rng)

    for isAddition in operations {
        var problem = makeSimpleProblem(isAddition: isAddition, rng: &rng)
        while seen.contains(problem) {
            problem = makeSimpleProblem(isAddition: isAddition, rng: &rng)
        }
        problems.append(problem)
        seen.insert(problem)
    }
    return problems
}

func drawSimpleWorksheet(_ problems: [Problem], sheetNumber: Int, showAnswers: Bool, into url: URL) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

    let simpleTitleFont = NSFont.systemFont(ofSize: 23, weight: .semibold)
    let simpleProblemFont = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .regular)
    let simpleAnswerFont = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)
    let simpleColumnCount = 2
    let simpleRowCount = 18
    let simpleUsableWidth = a4.width - margin * 2
    let simpleUsableHeight: CGFloat = 600
    let simpleColumnWidth = simpleUsableWidth / CGFloat(simpleColumnCount)
    let simpleRowHeight = simpleUsableHeight / CGFloat(simpleRowCount)

    drawText(
        showAnswers ? "10以内简单加减练习答案（第 \(sheetNumber) 份）" : "10以内简单加减练习（第 \(sheetNumber) 份）",
        in: CGRect(x: margin, y: a4.height - 62, width: simpleUsableWidth, height: 30),
        font: simpleTitleFont,
        alignment: .center
    )
    drawText(
        "姓名：________________    日期：________________    用时：________________",
        in: CGRect(x: margin, y: a4.height - 96, width: simpleUsableWidth, height: 20),
        font: headerFont
    )
    drawText(
        "题目：10以内加减法，答案在 0 到 10 之间。",
        in: CGRect(x: margin, y: a4.height - 120, width: simpleUsableWidth, height: 18),
        font: headerFont,
        color: NSColor(calibratedWhite: 0.32, alpha: 1)
    )

    let gridTop = a4.height - 154
    for col in 1..<simpleColumnCount {
        let x = margin + CGFloat(col) * simpleColumnWidth - 8
        drawLine(from: CGPoint(x: x, y: gridTop - simpleUsableHeight - 4), to: CGPoint(x: x, y: gridTop + 4), width: 0.45)
    }

    for i in 0..<problems.count {
        let col = i / simpleRowCount
        let row = i % simpleRowCount
        let x = margin + CGFloat(col) * simpleColumnWidth
        let y = gridTop - CGFloat(row + 1) * simpleRowHeight + 9
        let p = problems[i]
        let number = String(format: "%2d.", i + 1)
        let suffix = showAnswers ? String(format: " = %2d", p.answer) : " = ____"
        let line = "\(number)  \(p.expression)\(suffix)"
        drawText(line, in: CGRect(x: x, y: y, width: simpleColumnWidth - 18, height: 27), font: showAnswers ? simpleAnswerFont : simpleProblemFont)
    }

    drawLine(from: CGPoint(x: margin, y: 58), to: CGPoint(x: a4.width - margin, y: 58), width: 0.55)
    drawText(
        "生成日期：2026-06-03    每份 \(simpleProblemsPerSheet) 题，适合入门练习。",
        in: CGRect(x: margin, y: 38, width: simpleUsableWidth, height: 14),
        font: footerFont,
        color: NSColor(calibratedWhite: 0.42, alpha: 1),
        alignment: .center
    )

    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()
    context.closePDF()
}

let easyTwoDigitSheetCount = 10
let easyTwoDigitProblemsPerSheet = 36

func makeEasyTwoDigitAddition(rng: inout SeededGenerator) -> Problem {
    while true {
        let aTens = Int.random(in: 1...7, using: &rng)
        let bTens = Int.random(in: 1...(9 - aTens), using: &rng)
        let aOnes = Int.random(in: 0...9, using: &rng)
        let bOnes = Int.random(in: 0...(9 - aOnes), using: &rng)
        let a = aTens * 10 + aOnes
        let b = bTens * 10 + bOnes
        let answer = a + b
        if answer >= 10 && answer <= 99 {
            return Problem(a: a, b: b, op: "+")
        }
    }
}

func makeEasyTwoDigitSubtraction(rng: inout SeededGenerator) -> Problem {
    let bTens = Int.random(in: 1...8, using: &rng)
    let aTens = Int.random(in: bTens...9, using: &rng)
    let bOnes = Int.random(in: 0...9, using: &rng)
    let aOnes = Int.random(in: bOnes...9, using: &rng)
    let a = aTens * 10 + aOnes
    let b = bTens * 10 + bOnes
    return Problem(a: a, b: b, op: "-")
}

func makeEasyTwoDigitWorksheet(seed: UInt64, index: Int) -> [Problem] {
    var rng = SeededGenerator(seed: seed + UInt64(index) * 41_027)
    var problems: [Problem] = []
    var seen = Set<Problem>()
    var operations = Array(repeating: true, count: easyTwoDigitProblemsPerSheet / 2)
        + Array(repeating: false, count: easyTwoDigitProblemsPerSheet - easyTwoDigitProblemsPerSheet / 2)
    operations.shuffle(using: &rng)

    for isAddition in operations {
        var problem = isAddition ? makeEasyTwoDigitAddition(rng: &rng) : makeEasyTwoDigitSubtraction(rng: &rng)
        while seen.contains(problem) {
            problem = isAddition ? makeEasyTwoDigitAddition(rng: &rng) : makeEasyTwoDigitSubtraction(rng: &rng)
        }
        problems.append(problem)
        seen.insert(problem)
    }
    return problems
}

func drawEasyTwoDigitWorksheet(_ problems: [Problem], sheetNumber: Int, showAnswers: Bool, into url: URL) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

    let easyTitleFont = NSFont.systemFont(ofSize: 22, weight: .semibold)
    let easyProblemFont = NSFont.monospacedDigitSystemFont(ofSize: 19, weight: .regular)
    let easyAnswerFont = NSFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
    let easyColumnCount = 2
    let easyRowCount = 18
    let easyUsableWidth = a4.width - margin * 2
    let easyUsableHeight: CGFloat = 600
    let easyColumnWidth = easyUsableWidth / CGFloat(easyColumnCount)
    let easyRowHeight = easyUsableHeight / CGFloat(easyRowCount)

    drawText(
        showAnswers ? "简单两位数加减练习答案（第 \(sheetNumber) 份）" : "简单两位数加减练习（第 \(sheetNumber) 份）",
        in: CGRect(x: margin, y: a4.height - 62, width: easyUsableWidth, height: 30),
        font: easyTitleFont,
        alignment: .center
    )
    drawText(
        "姓名：________________    日期：________________    用时：________________",
        in: CGRect(x: margin, y: a4.height - 96, width: easyUsableWidth, height: 20),
        font: headerFont
    )
    drawText(
        "题目：两个两位数相加减；加法不进位，减法不退位，适合入门心算。",
        in: CGRect(x: margin, y: a4.height - 120, width: easyUsableWidth, height: 18),
        font: headerFont,
        color: NSColor(calibratedWhite: 0.32, alpha: 1)
    )

    let gridTop = a4.height - 154
    for col in 1..<easyColumnCount {
        let x = margin + CGFloat(col) * easyColumnWidth - 8
        drawLine(from: CGPoint(x: x, y: gridTop - easyUsableHeight - 4), to: CGPoint(x: x, y: gridTop + 4), width: 0.45)
    }

    for i in 0..<problems.count {
        let col = i / easyRowCount
        let row = i % easyRowCount
        let x = margin + CGFloat(col) * easyColumnWidth
        let y = gridTop - CGFloat(row + 1) * easyRowHeight + 9
        let p = problems[i]
        let number = String(format: "%2d.", i + 1)
        let suffix = showAnswers ? String(format: " = %2d", p.answer) : " = ____"
        let line = "\(number)  \(p.expression)\(suffix)"
        drawText(line, in: CGRect(x: x, y: y, width: easyColumnWidth - 18, height: 27), font: showAnswers ? easyAnswerFont : easyProblemFont)
    }

    drawLine(from: CGPoint(x: margin, y: 58), to: CGPoint(x: a4.width - margin, y: 58), width: 0.55)
    drawText(
        "生成日期：2026-06-03    每份 \(easyTwoDigitProblemsPerSheet) 题，18 道加法 + 18 道减法。",
        in: CGRect(x: margin, y: 38, width: easyUsableWidth, height: 14),
        font: footerFont,
        color: NSColor(calibratedWhite: 0.42, alpha: 1),
        alignment: .center
    )

    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()
    context.closePDF()
}

let seed = UInt64(20260603)

for sheet in 1...sheetCount {
    let problems = makeWorksheet(seed: seed, index: sheet)
    let practiceURL = outputDirectory.appendingPathComponent(String(format: "两位数加减练习_%02d.pdf", sheet))
    let answerURL = outputDirectory.appendingPathComponent(String(format: "两位数加减练习_答案_%02d.pdf", sheet))
    drawWorksheet(problems, sheetNumber: sheet, showAnswers: false, into: practiceURL)
    drawWorksheet(problems, sheetNumber: sheet, showAnswers: true, into: answerURL)
}

for sheet in 1...simpleSheetCount {
    let problems = makeSimpleWorksheet(seed: seed + 99_001, index: sheet)
    let practiceURL = simpleOutputDirectory.appendingPathComponent(String(format: "10以内简单加减练习_%02d.pdf", sheet))
    let answerURL = simpleOutputDirectory.appendingPathComponent(String(format: "10以内简单加减练习_答案_%02d.pdf", sheet))
    drawSimpleWorksheet(problems, sheetNumber: sheet, showAnswers: false, into: practiceURL)
    drawSimpleWorksheet(problems, sheetNumber: sheet, showAnswers: true, into: answerURL)
}

for sheet in 1...easyTwoDigitSheetCount {
    let problems = makeEasyTwoDigitWorksheet(seed: seed + 171_991, index: sheet)
    let practiceURL = easyTwoDigitOutputDirectory.appendingPathComponent(String(format: "简单两位数加减练习_%02d.pdf", sheet))
    let answerURL = easyTwoDigitOutputDirectory.appendingPathComponent(String(format: "简单两位数加减练习_答案_%02d.pdf", sheet))
    drawEasyTwoDigitWorksheet(problems, sheetNumber: sheet, showAnswers: false, into: practiceURL)
    drawEasyTwoDigitWorksheet(problems, sheetNumber: sheet, showAnswers: true, into: answerURL)
}

print("已生成两位数加减练习、简单两位数加减练习和 10 以内简单版 PDF：\(outputDirectory.path)")
