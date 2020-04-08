defmodule ExAcorn.Statement.ExportStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def export_statement do
    ignore(string("export"))
    |> optional(whitespace() |> concat(string("default")))
    |> concat(whitespace())
    |> choice([
      variable_statement(),
      whitespace(),
      non_control_char()
    ])
    |> tag(:export_statement)
  end
end
