import gleeunit
import gleeunit/should
import lustre_daisyui

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn insert_after_tailwind_import_basic_test() {
  let lines = ["@import \"tailwindcss\";", ""]
  let config = "@plugin \"../vendor/daisyui.mjs\";"

  let result = lustre_daisyui.insert_after_tailwind_import(lines, config)

  result
  |> should.be_ok
  |> should.equal([
    "@import \"tailwindcss\";",
    "@plugin \"../vendor/daisyui.mjs\";",
    "",
  ])
}

pub fn insert_after_tailwind_import_with_existing_content_test() {
  let lines = [
    "/* Some comment */",
    "@import \"tailwindcss\";",
    "",
    "body { margin: 0; }",
  ]
  let config = "@plugin \"../vendor/daisyui.mjs\";"

  let result = lustre_daisyui.insert_after_tailwind_import(lines, config)

  result
  |> should.be_ok
  |> should.equal([
    "/* Some comment */",
    "@import \"tailwindcss\";",
    "@plugin \"../vendor/daisyui.mjs\";",
    "",
    "body { margin: 0; }",
  ])
}

pub fn insert_after_tailwind_import_missing_import_test() {
  let lines = ["body { margin: 0; }"]
  let config = "@plugin \"../vendor/daisyui.mjs\";"

  let result = lustre_daisyui.insert_after_tailwind_import(lines, config)

  result
  |> should.be_error
}

pub fn insert_daisyui_config_success_test() {
  let content = "@import \"tailwindcss\";\n\nbody { margin: 0; }"

  let result = lustre_daisyui.insert_daisyui_config(content, "test.css", True)

  result
  |> should.be_ok
  |> should.equal(
    "@import \"tailwindcss\";\n@source not \"../vendor/daisyui{,*}.mjs\";\n@plugin \"../vendor/daisyui.mjs\";\n\nbody { margin: 0; }",
  )
}

pub fn insert_daisyui_config_already_present_test() {
  let content =
    "@import \"tailwindcss\";\n@plugin \"../vendor/daisyui.mjs\";\n\nbody { margin: 0; }"

  let result = lustre_daisyui.insert_daisyui_config(content, "test.css", True)

  result
  |> should.be_ok
  |> should.equal(content)
}

pub fn insert_daisyui_config_missing_tailwind_import_test() {
  let content = "body { margin: 0; }"

  let result = lustre_daisyui.insert_daisyui_config(content, "test.css", True)

  result
  |> should.be_error
}
