# lustre_daisyui

A CLI tool to easily install [daisyUI](https://daisyui.com/) for [Lustre](https://lustre.build/) projects.

[![Package Version](https://img.shields.io/hexpm/v/lustre_daisyui)](https://hex.pm/packages/lustre_daisyui)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/lustre_daisyui/)

## Installation

Add this package to your Lustre project:

```sh
gleam add lustre_daisyui --dev
```

## Usage

Run the install command to set up daisyUI in your Lustre project:

```sh
gleam run -m lustre_daisyui install
```

This command will:

1. Install Tailwind CSS (if not already installed) via `lustre/dev`
2. Create a `vendor` directory in your project root
3. Download the latest daisyUI plugin files (`daisyui.mjs` and `daisyui-theme.mjs`) to the `vendor` directory
4. Automatically configure your CSS entry file to use daisyUI

### What it does

The installer modifies your `src/<project_name>.css` file to include daisyUI. After running the install command, your CSS file will contain:

```css
@import "tailwindcss";
@source not "../vendor/daisyui{,*}.mjs";
@plugin "../vendor/daisyui.mjs";
```

The configuration is inserted automatically after the Tailwind import, ensuring proper setup.

### Using daisyUI

Once installed, you can use any daisyUI component classes in your Lustre views:

```gleam
import lustre/element/html
import lustre/attribute

pub fn view() {
  html.button(
    [attribute.class("btn btn-primary")],
    [html.text("Click me!")],
  )
}
```

Visit the [daisyUI documentation](https://daisyui.com/components/) to explore all available components and themes.

## Development

```sh
gleam run    # Run the project
gleam test   # Run the tests
gleam format # Format the code
```
