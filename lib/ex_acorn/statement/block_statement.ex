defmodule ExAcorn.Statement.BlockStatement do
  import NimbleParsec
  import ExAcorn.Common
  # import ExAcorn.Utils

  def block_statement(root_statement \\ empty()) do
    local_block(root_statement) |> tag(:block_statement)
  end
end
