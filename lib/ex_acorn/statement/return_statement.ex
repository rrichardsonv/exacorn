defmodule ExAcorn.Statement.ReturnStatement do
  import NimbleParsec
  # import ExAcorn.Common
  # import ExAcorn.Utils

  def return_statement do
    string("return") |> tag(:return_statement)
  end
end
