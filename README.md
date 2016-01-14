# cocoa-redundant-l10n

The tool finds all `*.lproj` directories, parses every `*.strings` file from them and then scans all `*.m` files for localization keys usage.

## Usage

```
cocoa-redundant-l10n PROJECT_DIR
```

## Installation

1. Clone the repository
2. Open project with Xcode
3. Build project
4. Select `Products/cocoa-redundant-l10n`, open a context menu and select "Show in Finder"
5. Move the binary to a proper directory
