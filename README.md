# ASEKit

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS-lightgrey)](https://www.apple.com/macos/)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)

Read and write Adobe Swatch Exchange palettes in Swift.

A small, dependency-free Swift Package for working with `.ase` color files.

## Why ASEKit?

ASEKit gives Swift applications a focused API for Adobe Swatch Exchange files without pulling in a larger palette-format framework.

- Import and export `.ase` palettes
- Preserve palette and swatch names
- Read RGB, Gray, CMYK, and Lab color models
- Export portable RGB palettes
- Foundation-only implementation
- Works on macOS and is easy to test with Swift Package Manager

## Installation

Add ASEKit to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ruiaureliano/asekit.git", from: "1.0.0")
]
```

Then add `ASEKit` to the target that uses it.

## Quick start

```swift
import ASEKit

let palette = try ASEReader.read(from: paletteURL)

print(palette.name)
for color in palette.colors {
    print("\(color.name): \(color.red), \(color.green), \(color.blue)")
}
```

Create and save a palette:

```swift
import ASEKit

let palette = ASEPalette(
    name: "Brand Colors",
    colors: [
        ASEColor(name: "Ocean", red: 0.05, green: 0.35, blue: 0.80),
        ASEColor(name: "Coral", red: 0.95, green: 0.35, blue: 0.25)
    ]
)

try ASEWriter.write(palette, to: outputURL)
```

For in-memory use, `ASEReader.read(data:)` and `ASEWriter.data(for:)` are also available.

## API

### `ASEPalette`

Represents a named collection of swatches.

```swift
public struct ASEPalette {
    public var name: String
    public var colors: [ASEColor]
}
```

### `ASEColor`

Represents a swatch using normalized RGBA components in the `0...1` range.

```swift
public struct ASEColor {
    public let name: String
    public let red: Float
    public let green: Float
    public let blue: Float
    public let alpha: Float
}
```

The writer currently emits RGB swatches, which provides the most portable representation across design tools. The reader converts supported non-RGB models into RGB values.

## Requirements

- Swift 5.9 or later
- macOS 10.15 or later

## Development

Run the test suite from the repository root:

```bash
swift test
```

ASEKit is intentionally small. Changes should include tests for new format behavior, malformed input, and round-trip compatibility where appropriate.

## License

Choose and add a license before the first public release. MIT is a good fit for a small reusable package if you want broad use and redistribution.
