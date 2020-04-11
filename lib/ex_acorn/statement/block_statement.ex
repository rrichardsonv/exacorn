defmodule ExAcorn.Statement.BlockStatement do
  import NimbleParsec
  # import ExAcorn.Utils

  def block_statement(root_statement \\ empty()) do
    root_statement |> tag(:block_statement)
  end
end
