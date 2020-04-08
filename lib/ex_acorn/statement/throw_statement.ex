defmodule ExAcorn.Statement.ThrowStatement do
  import NimbleParsec
  # import ExAcorn.Common
  # import ExAcorn.Utils

  def throw_statement do
    string("throw") |> tag(:throw_statement)
  end
end
