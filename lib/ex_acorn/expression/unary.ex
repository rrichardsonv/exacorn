defmodule ExAcorn.Expression.Unary do
  import NimbleParsec
  import ExAcorn.Utils

  def unary_expression(expr \\ empty()) do
    operator =
      choice([
        string("typeof") |> ignore(whitespace()),
        string("void") |> ignore(whitespace()),
        string("delete") |> ignore(whitespace()),
        string("-"),
        string("+"),
        string("!"),
        string("~")
      ])
      |> reduce({__MODULE__, :unary_atom_operator, []})
      |> unwrap_and_tag(:operator)

    operator
    |> optional(whitespace())
    |> concat(expr |> unwrap_and_tag(:argument))
    |> tag(:unary_expression)
  end

  def unary_atom_operator(args) do
    Enum.map(args, fn
      v when v in ["typeof","void","delete","-","+","!","~"] ->
        String.to_atom(v)
      a ->
        a
    end)
    |> case do
      [[single_operator]] ->
        single_operator
      [single_operator] ->
        single_operator
      a ->
        IO.inspect(a, label: "invariant------unary_atom_operator----------")
    end
  end
end
