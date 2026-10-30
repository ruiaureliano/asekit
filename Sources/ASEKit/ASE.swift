import Foundation

public struct ASEColor: Equatable, Sendable {
    public let name: String
    public let red: Float
    public let green: Float
    public let blue: Float
    public let alpha: Float

    public init(name: String, red: Float, green: Float, blue: Float, alpha: Float = 1) {
        self.name = name
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public struct ASEPalette: Equatable, Sendable {
    public var name: String
    public var colors: [ASEColor]

    public init(name: String = "", colors: [ASEColor] = []) {
        self.name = name
        self.colors = colors
    }
}

public enum ASEError: Error, Equatable {
    case invalidHeader
    case truncated
    case invalidBlock
    case unsupportedColorModel(String)
    case invalidColorValues
}

public enum ASEReader {
    public static func read(from url: URL) throws -> ASEPalette {
        try read(data: Data(contentsOf: url))
    }

    public static func read(data: Data) throws -> ASEPalette {
        var reader = BinaryReader(data: data)
        guard try reader.readBytes(count: 4) == Array("ASEF".utf8) else { throw ASEError.invalidHeader }
        _ = try reader.readUInt16() // major version
        _ = try reader.readUInt16() // minor version
        let blockCount = Int(try reader.readUInt32())
        var palette = ASEPalette()

        for _ in 0..<blockCount {
            let type = try reader.readUInt16()
            let length = Int(try reader.readUInt32())
            let block = try reader.readData(count: length)
            var blockReader = BinaryReader(data: block)

            switch type {
            case 0x0001:
                let name = try blockReader.readUTF16String()
                let model = try blockReader.readASCII(count: 4)
                let color = try readColor(model: model, name: name, reader: &blockReader)
                palette.colors.append(color)
            case 0xC001:
                palette.name = try blockReader.readUTF16String()
            default:
                break
            }
        }
        return palette
    }

    private static func readColor(model: String, name: String, reader: inout BinaryReader) throws -> ASEColor {
        switch model {
        case "RGB ":
            return ASEColor(name: name, red: try reader.readFloat(), green: try reader.readFloat(), blue: try reader.readFloat())
        case "Gray":
            let value = try reader.readFloat()
            return ASEColor(name: name, red: value, green: value, blue: value)
        case "CMYK":
            let c = try reader.readFloat(), m = try reader.readFloat(), y = try reader.readFloat(), k = try reader.readFloat()
            return ASEColor(name: name, red: 1 - min(1, c + k), green: 1 - min(1, m + k), blue: 1 - min(1, y + k))
        case "Lab ":
            return try labColor(name: name, lightness: reader.readFloat(), a: reader.readFloat(), b: reader.readFloat())
        default:
            throw ASEError.unsupportedColorModel(model)
        }
    }

    private static func labColor(name: String, lightness: Float, a: Float, b: Float) throws -> ASEColor {
        let fy = (lightness + 16) / 116
        let fx = a / 500 + fy
        let fz = fy - b / 200
        func xyz(_ value: Float) -> Float {
            let cube = value * value * value
            return cube > 0.008856 ? cube : (value - 16 / 116) / 7.787
        }
        let x = xyz(fx) * 0.96422, y = xyz(fy), z = xyz(fz) * 0.82521
        let linearRed = 3.2406 * x - 1.5372 * y - 0.4986 * z
        let linearGreen = -0.9689 * x + 1.8758 * y + 0.0415 * z
        let linearBlue = 0.0557 * x - 0.2040 * y + 1.0570 * z
        func srgb(_ value: Float) -> Float {
            let clamped = max(0, value)
            return clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        }
        return ASEColor(name: name, red: srgb(linearRed), green: srgb(linearGreen), blue: srgb(linearBlue))
    }
}

public enum ASEWriter {
    public static func data(for palette: ASEPalette) -> Data {
        var data = Data([0x41, 0x53, 0x45, 0x46])
        data.appendUInt16(1)
        data.appendUInt16(0)
        data.appendUInt32(UInt32(palette.colors.count + (palette.name.isEmpty ? 0 : 1)))
        if !palette.name.isEmpty {
            data.appendBlock(type: 0xC001) { block in block.appendUTF16String(palette.name) }
        }
        for color in palette.colors {
            data.appendBlock(type: 0x0001) { block in
                block.appendUTF16String(color.name)
                block.appendASCII("RGB ")
                block.appendFloat(color.red)
                block.appendFloat(color.green)
                block.appendFloat(color.blue)
                block.appendUInt16(0)
            }
        }
        return data
    }

    public static func write(_ palette: ASEPalette, to url: URL) throws {
        try data(for: palette).write(to: url, options: .atomic)
    }
}

private struct BinaryReader {
    let data: Data
    var offset = 0

    mutating func readData(count: Int) throws -> Data {
        guard count >= 0, offset + count <= data.count else { throw ASEError.truncated }
        defer { offset += count }
        return data.subdata(in: offset..<(offset + count))
    }

    mutating func readBytes(count: Int) throws -> [UInt8] { Array(try readData(count: count)) }

    mutating func readUInt16() throws -> UInt16 {
        let bytes = try readBytes(count: 2)
        return UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    }

    mutating func readUInt32() throws -> UInt32 {
        let bytes = try readBytes(count: 4)
        return UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
    }

    mutating func readFloat() throws -> Float {
        Float(bitPattern: try readUInt32())
    }

    mutating func readASCII(count: Int) throws -> String {
        String(bytes: try readBytes(count: count), encoding: .utf8) ?? ""
    }

    mutating func readUTF16String() throws -> String {
        let count = Int(try readUInt16())
        var values: [UInt16] = []
        for _ in 0..<count { values.append(try readUInt16()) }
        if values.last == 0 { values.removeLast() }
        return String(decoding: values, as: UTF16.self)
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8(value >> 8)); append(UInt8(value & 0xFF))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xFF)); append(UInt8((value >> 16) & 0xFF)); append(UInt8((value >> 8) & 0xFF)); append(UInt8(value & 0xFF))
    }

    mutating func appendFloat(_ value: Float) { appendUInt32(value.bitPattern) }

    mutating func appendASCII(_ value: String) { append(contentsOf: value.utf8) }

    mutating func appendUTF16String(_ value: String) {
        let units = Array(value.utf16) + [0]
        appendUInt16(UInt16(units.count))
        for unit in units { appendUInt16(unit) }
    }

    mutating func appendBlock(type: UInt16, build: (inout Data) -> Void) {
        var block = Data()
        build(&block)
        appendUInt16(type)
        appendUInt32(UInt32(block.count))
        append(block)
    }
}
