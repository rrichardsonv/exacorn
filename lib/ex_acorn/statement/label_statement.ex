defmodule ExAcorn.Statement.LabelStatement do
  import NimbleParsec
  # import ExAcorn.Common
  import ExAcorn.Utils

  def label_statement do
    optional(space_chars())
    |> concat(line_text())
    |> optional(space_chars())
    |> ignore(colon())
    |> optional(whitespace())
    |> tag(:label_statement)
  end
end
