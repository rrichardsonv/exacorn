defmodule ExAcorn.Statement.ThrowStatement do
  import NimbleParsec
  import ExAcorn.Utils
  # import ExAcorn.Common

  def throw_statement(expr \\ empty()) do
    ignore(string("throw"))
    |> ignore(space_chars())
    |> concat(expr |> tag(:argument))
    |> tag(:throw_statement)
  end
end
