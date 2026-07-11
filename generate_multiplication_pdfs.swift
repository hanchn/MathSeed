import AppKit
import CoreGraphics
import Foundation

let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("PDF输出/乘法表", isDirectory: true)

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let outputURL = outputDirectory.appendingPathComponent("9x9乘法表_完整和无答案卡片_A4打印版.pdf")
let a4 = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
let margin: CGFloat = 42
let usableWidth = a4.width - margin * 2
let black = NSColor(calibratedWhite: 0.08, alpha: 1)
let gray = NSColor(calibratedWhite: 0.42, alpha: 1)
let lightGray = NSColor(calibratedWhite: 0.82, alpha: 1)
let lineGray = NSColor(calibratedWhite: 0.68, alpha: 1)
let headerFill = NSColor(calibratedRed: 0.93, green: 0.96, blue: 0.98, alpha: 1)
let cardFill = NSColor(calibratedWhite: 0.985, alpha: 1)

let titleFont = NSFont.systemFont(ofSize: 27, weight: .bold)
let subtitleFont = NSFont.systemFont(ofSize: 13, weight: .regular)
let stepFormulaFont = NSFont.monospacedDigitSystemFont(ofSize: 11.2, weight: .semibold)
let stepChantFont = NSFont.systemFont(ofSize: 8.3, weight: .regular)
let cardIndexFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
let cardExpressionFont = NSFont.monospacedDigitSystemFont(ofSize: 31, weight: .semibold)
let cardBlankFont = NSFont.systemFont(ofSize: 16, weight: .regular)
let footerFont = NSFont.systemFont(ofSize: 9, weight: .regular)

let chineseDigits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]

let dateFormatter = DateFormatter()
dateFormatter.locale = Locale(identifier: "zh_CN")
dateFormatter.dateFormat = "yyyy-MM-dd"
let generatedDate = dateFormatter.string(from: Date())

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

func drawLine(from start: CGPoint, to end: CGPoint, color: NSColor = lineGray, width: CGFloat = 0.7, dash: [CGFloat]? = nil) {
    color.setStroke()
    let path = NSBezierPath()
    path.lineWidth = width
    path.move(to: start)
    path.line(to: end)
    if let dash {
        path.setLineDash(dash, count: dash.count, phase: 0)
    }
    path.stroke()
}

func drawRect(_ rect: CGRect, stroke: NSColor = lineGray, fill: NSColor? = nil, width: CGFloat = 0.7) {
    let path = NSBezierPath(rect: rect)
    if let fill {
        fill.setFill()
        path.fill()
    }
    stroke.setStroke()
    path.lineWidth = width
    path.stroke()
}

func drawRoundedRect(_ rect: CGRect, stroke: NSColor = lineGray, fill: NSColor? = nil, width: CGFloat = 0.8, dash: [CGFloat]? = nil) {
    let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
    if let fill {
        fill.setFill()
        path.fill()
    }
    stroke.setStroke()
    path.lineWidth = width
    if let dash {
        path.setLineDash(dash, count: dash.count, phase: 0)
    }
    path.stroke()
}

func drawPageFooter(_ text: String) {
    drawLine(from: CGPoint(x: margin, y: 50), to: CGPoint(x: a4.width - margin, y: 50), color: lightGray, width: 0.55)
    drawText(
        text,
        in: CGRect(x: margin, y: 31, width: usableWidth, height: 14),
        font: footerFont,
        color: gray,
        alignment: .center
    )
}

func multiplicationChant(_ a: Int, _ b: Int) -> String {
    "\(chineseDigits[a])\(chineseDigits[b])\(chineseProduct(a * b))"
}

func chineseProduct(_ value: Int) -> String {
    if value < 10 {
        return "得\(chineseDigits[value])"
    }

    if value == 10 {
        return "一十"
    }

    let tens = value / 10
    let ones = value % 10
    let tensText = tens == 1 ? "十" : "\(chineseDigits[tens])十"
    return ones == 0 ? tensText : "\(tensText)\(chineseDigits[ones])"
}

func drawFullTablePage() {
    drawText(
        "9x9 阶梯式乘法表（完整答案）",
        in: CGRect(x: margin, y: a4.height - 68, width: usableWidth, height: 34),
        font: titleFont,
        alignment: .center
    )
    drawText(
        "传统九九口诀阶梯排版：每一行只列到本行数字，A4 纸直接打印。",
        in: CGRect(x: margin, y: a4.height - 98, width: usableWidth, height: 22),
        font: subtitleFont,
        color: gray,
        alignment: .center
    )

    let columns = 9
    let stepMargin: CGFloat = 30
    let stepUsableWidth = a4.width - stepMargin * 2
    let cellGap: CGFloat = 4
    let cellWidth = (stepUsableWidth - CGFloat(columns - 1) * cellGap) / CGFloat(columns)
    let cellHeight: CGFloat = 50
    let rowGap: CGFloat = 8
    let tableTop: CGFloat = 690

    for row in 1...9 {
        let y = tableTop - CGFloat(row) * cellHeight - CGFloat(row - 1) * rowGap
        for col in 1...row {
            let x = stepMargin + CGFloat(col - 1) * (cellWidth + cellGap)
            let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
            let fill = row % 2 == 0 ? headerFill : cardFill

            drawRoundedRect(rect, stroke: NSColor(calibratedWhite: 0.78, alpha: 1), fill: fill, width: 0.7)
            drawText(
                "\(col)x\(row)=\(col * row)",
                in: CGRect(x: rect.minX + 2, y: rect.midY - 2, width: rect.width - 4, height: 17),
                font: stepFormulaFont,
                color: black,
                alignment: .center
            )
            drawText(
                multiplicationChant(col, row),
                in: CGRect(x: rect.minX + 2, y: rect.minY + 8, width: rect.width - 4, height: 13),
                font: stepChantFont,
                color: gray,
                alignment: .center
            )
        }
    }

    drawText(
        "读法示例：第 9 行从 1x9 到 9x9，最后一格是 9x9=81。",
        in: CGRect(x: margin, y: 112, width: usableWidth, height: 22),
        font: subtitleFont,
        color: gray,
        alignment: .center
    )
    drawPageFooter("生成日期：\(generatedDate)    第 1 页：阶梯式完整 9x9 乘法表")
}

func drawCardPage(multiplicand: Int, pageNumber: Int, totalCardPages: Int) {
    drawText(
        "9x9 乘法卡片（无答案）",
        in: CGRect(x: margin, y: a4.height - 64, width: usableWidth, height: 32),
        font: titleFont,
        alignment: .center
    )
    drawText(
        "第 \(multiplicand) 组：\(multiplicand) x 1 到 \(multiplicand) x 9。沿虚线剪下，每张卡片可单独练习。",
        in: CGRect(x: margin, y: a4.height - 94, width: usableWidth, height: 22),
        font: subtitleFont,
        color: gray,
        alignment: .center
    )

    let columns = 3
    let rows = 3
    let gridTop: CGFloat = 718
    let gridBottom: CGFloat = 72
    let gridWidth = usableWidth
    let gridHeight = gridTop - gridBottom
    let cellWidth = gridWidth / CGFloat(columns)
    let cellHeight = gridHeight / CGFloat(rows)

    for multiplier in 1...9 {
        let index = multiplier - 1
        let row = index / columns
        let col = index % columns
        let frame = CGRect(
            x: margin + CGFloat(col) * cellWidth + 8,
            y: gridTop - CGFloat(row + 1) * cellHeight + 10,
            width: cellWidth - 16,
            height: cellHeight - 20
        )

        drawRoundedRect(frame, stroke: lineGray, fill: cardFill, width: 0.9, dash: [5, 4])
        drawText(
            String(format: "%02d/81", (multiplicand - 1) * 9 + multiplier),
            in: CGRect(x: frame.minX + 12, y: frame.maxY - 27, width: 58, height: 16),
            font: cardIndexFont,
            color: gray
        )
        drawText(
            "\(multiplicand) x \(multiplier)",
            in: CGRect(x: frame.minX + 12, y: frame.midY + 15, width: frame.width - 24, height: 42),
            font: cardExpressionFont,
            alignment: .center
        )
        drawText(
            "=  __________",
            in: CGRect(x: frame.minX + 18, y: frame.midY - 35, width: frame.width - 36, height: 28),
            font: cardBlankFont,
            color: black,
            alignment: .center
        )
    }

    drawPageFooter("生成日期：\(generatedDate)    卡片页 \(pageNumber)/\(totalCardPages)    本页共 9 张无答案卡片")
}

func createMultiplicationPDF(at url: URL) {
    var mediaBox = a4
    guard let consumer = CGDataConsumer(url: url as CFURL),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("无法创建 PDF：\(url.path)")
    }

    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    drawFullTablePage()
    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()

    for multiplicand in 1...9 {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawCardPage(multiplicand: multiplicand, pageNumber: multiplicand, totalCardPages: 9)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }

    context.closePDF()
}

createMultiplicationPDF(at: outputURL)
print("已生成 9x9 乘法表完整答案和无答案卡片 PDF：\(outputURL.path)")
