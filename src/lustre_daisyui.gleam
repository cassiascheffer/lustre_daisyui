import argv
import filepath
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lustre_dev_tools/cli
import lustre_dev_tools/project
import lustre_dev_tools/system
import simplifile
import snag

const daisyui_mjs_url = "https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.mjs"

const daisyui_theme_mjs_url = "https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.mjs"

pub fn main() -> Nil {
  case argv.load().arguments {
    ["install"] -> {
      case install() {
        Ok(_) -> Nil
        Error(err) -> {
          io.println_error(snag.pretty_print(err))
          Nil
        }
      }
    }
    _ -> {
      io.println_error("Usage: gleam run -m lustre_daisyui install")
      Nil
    }
  }
}

fn install() -> Result(Nil, snag.Snag) {
  let quiet = False
  cli.log("Installing daisyUI for Lustre", quiet)

  let proj = project.config()

  use _ <- result.try(install_tailwind(quiet))

  use _ <- result.try(download_daisyui_files(quiet))

  use _ <- result.try(modify_css_file(proj, quiet))

  cli.success("daisyUI installed successfully!", quiet)
  Ok(Nil)
}

fn install_tailwind(quiet: Bool) -> Result(Nil, snag.Snag) {
  cli.log("Installing Tailwind CSS via lustre/dev", quiet)

  use _ <- result.try(
    system.run("gleam run -m lustre/dev add tailwind")
    |> result.map_error(fn(err) {
      snag.new("Failed to install Tailwind CSS: " <> err)
    }),
  )

  cli.success("Tailwind CSS installed", quiet)
  Ok(Nil)
}

fn download_daisyui_files(quiet: Bool) -> Result(Nil, snag.Snag) {
  cli.log("Downloading daisyUI files", quiet)

  use _ <- result.try(
    simplifile.create_directory_all("vendor")
    |> result.map_error(fn(err) {
      snag.new("Failed to create vendor directory: " <> string.inspect(err))
    }),
  )

  use _ <- result.try(download_file(daisyui_mjs_url, "vendor/daisyui.mjs"))
  cli.log("Downloaded daisyui.mjs", quiet)

  use _ <- result.try(download_file(
    daisyui_theme_mjs_url,
    "vendor/daisyui-theme.mjs",
  ))
  cli.log("Downloaded daisyui-theme.mjs", quiet)

  cli.success("daisyUI files downloaded", quiet)
  Ok(Nil)
}

fn download_file(url: String, filename: String) -> Result(Nil, snag.Snag) {
  use req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) {
      snag.new("Failed to create request for " <> url)
    }),
  )

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_) { snag.new("Failed to download " <> url) }),
  )

  case resp.status {
    200 -> {
      simplifile.write(filename, resp.body)
      |> result.map_error(fn(err) {
        snag.new("Failed to write " <> filename <> ": " <> string.inspect(err))
      })
    }
    302 | 301 -> {
      case list.key_find(resp.headers, "location") {
        Ok(redirect_url) -> download_file(redirect_url, filename)
        Error(_) ->
          snag.error("Received redirect but no location header for " <> url)
      }
    }
    _ ->
      snag.error(
        "Failed to download "
        <> url
        <> " (status: "
        <> string.inspect(resp.status)
        <> ")",
      )
  }
}

fn modify_css_file(proj: project.Project, quiet: Bool) -> Result(Nil, snag.Snag) {
  cli.log("Modifying CSS file", quiet)

  use css_path <- result.try(
    filepath.join("src", proj.name <> ".css")
    |> filepath.expand
    |> result.map_error(fn(_) { snag.new("Failed to resolve CSS file path") }),
  )

  use content <- result.try(
    simplifile.read(css_path)
    |> result.map_error(fn(err) {
      snag.new(
        "Failed to read CSS file at " <> css_path <> ": " <> string.inspect(err),
      )
    }),
  )

  use modified_content <- result.try(insert_daisyui_config(
    content,
    css_path,
    quiet,
  ))

  use _ <- result.try(
    simplifile.write(css_path, modified_content)
    |> result.map_error(fn(err) {
      snag.new(
        "Failed to write CSS file at "
        <> css_path
        <> ": "
        <> string.inspect(err),
      )
    }),
  )

  cli.success("CSS file updated", quiet)
  Ok(Nil)
}

pub fn insert_daisyui_config(
  content: String,
  css_path: String,
  quiet: Bool,
) -> Result(String, snag.Snag) {
  let daisyui_config =
    "@source not \"../vendor/daisyui{,*}.mjs\";\n@plugin \"../vendor/daisyui.mjs\";"

  case string.contains(content, "@import \"tailwindcss\";") {
    False ->
      snag.error("Could not find @import \"tailwindcss\"; in " <> css_path)
    True ->
      case string.contains(content, "@plugin \"../vendor/daisyui.mjs\"") {
        True -> {
          cli.log("daisyUI configuration already present in CSS file", quiet)
          Ok(content)
        }
        False -> {
          let lines = string.split(content, "\n")
          use modified_lines <- result.try(insert_after_tailwind_import(
            lines,
            daisyui_config,
          ))
          Ok(string.join(modified_lines, "\n"))
        }
      }
  }
}

pub fn insert_after_tailwind_import(
  lines: List(String),
  config: String,
) -> Result(List(String), snag.Snag) {
  do_insert_after_tailwind_import(lines, config, [])
}

fn do_insert_after_tailwind_import(
  lines: List(String),
  config: String,
  acc: List(String),
) -> Result(List(String), snag.Snag) {
  case lines {
    [] -> snag.error("Could not find @import \"tailwindcss\"; line in CSS file")
    [line, ..rest] -> {
      case string.contains(line, "@import \"tailwindcss\";") {
        True -> {
          let new_acc = list.append(acc, [line, config])
          Ok(list.append(new_acc, rest))
        }
        False -> {
          do_insert_after_tailwind_import(
            rest,
            config,
            list.append(acc, [
              line,
            ]),
          )
        }
      }
    }
  }
}
