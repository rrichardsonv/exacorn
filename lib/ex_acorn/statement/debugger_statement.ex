defmodule ExAcorn.Statement.DebuggerStatement do
  import NimbleParsec
  # import ExAcorn.Common
  import ExAcorn.Utils

  def debugger_statement do
    ignore(string("debugger"))
    |> optional(whitespace())
    |> concat(expression_boundary())
    |> tag(:debugger_statement)
  end
end
