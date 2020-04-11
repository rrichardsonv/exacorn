defmodule ExAcorn.Statement.WhileStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def while_statement(expression \\ empty(), root_statement \\ empty()) do
    condition =
      paren_group([expression])
      |> unwrap_and_tag(:condition)

    ignore(string("while"))
    |> optional(space_chars())
    |> concat(condition)
    |> optional(space_chars())
    |> concat(root_statement |> unwrap_and_tag(:block))
    |> tag(:while_statement)
  end

  def do_statement(expression \\ empty(), root_statement \\ empty()) do
    condition =
      paren_group([expression])
      |> unwrap_and_tag(:condition)

    ignore(string("do"))
    |> optional(whitespace())
    |> concat(root_statement |> tag(:block))
    |> optional(whitespace())
    |> ignore(string("while"))
    |> optional(space_chars())
    |> concat(condition)
    |> tag(:do_statement)
  end
end
