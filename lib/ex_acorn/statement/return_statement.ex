defmodule ExAcorn.Statement.ReturnStatement do
  import NimbleParsec
  import ExAcorn.Utils
  # import ExAcorn.Common

  def return_statement(possible_expressions \\ []) do
    ignore(string("return"))
    |> concat(space_chars())
    |> choice([
      ignore(expression_boundary())
      | possible_expressions
    ])
    |> tag(:argument)
    |> tag(:return_statement)
  end
end
