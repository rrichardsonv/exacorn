defmodule ExAcorn.Statement.EmptyStatement do
  import NimbleParsec
  import ExAcorn.Utils

  def empty_statement do
    ignore(semi()) |> tag(:empty_statement)
  end
end
