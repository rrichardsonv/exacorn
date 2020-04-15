defmodule ExAcorn.Statement.LabelStatement do
  import NimbleParsec
  # import ExAcorn.Common
  import ExAcorn.Utils

  def label_statement(statement_combinator \\ empty()) do
    optional(space_chars())
    |> concat(line_text() |> tag(:label))
    |> optional(space_chars())
    |> ignore(colon())
    |> optional(whitespace())
    |> concat(statement_combinator |> tag(:body))
    |> tag(:label_statement)
  end
end
