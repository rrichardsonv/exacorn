defmodule ExAcorn.Operators do
  import NimbleParsec
  import ExAcorn.Utils

  def operator,
    do:
      optional(space_chars())
      |> choice([
        string("===") |> tag(:binary_operator),
        string("!==") |> tag(:binary_operator),
        string(">>>") |> tag(:binary_operator),
        string(">>>=") |> tag(:assignment_operator),
        string("<<=") |> tag(:assignment_operator),
        string(">>=") |> tag(:assignment_operator),
        string(">>") |> tag(:binary_operator),
        string("<<") |> tag(:binary_operator),
        string("<=") |> tag(:binary_operator),
        string(">=") |> tag(:binary_operator),
        string("in") |> ignore(whitespace()) |> tag(:binary_operator),
        string("instanceof") |> ignore(whitespace()) |> tag(:binary_operator),
        string("typeof") |> ignore(whitespace()) |> tag(:unary_operator),
        string("void") |> ignore(whitespace()) |> tag(:unary_operator),
        string("delete") |> ignore(whitespace()) |> tag(:unary_operator),
        string("+=") |> tag(:assignment_operator),
        string("-=") |> tag(:assignment_operator),
        string("*=") |> tag(:assignment_operator),
        string("/=") |> tag(:assignment_operator),
        string("%=") |> tag(:assignment_operator),
        string("|=") |> tag(:assignment_operator),
        string("^=") |> tag(:assignment_operator),
        string("&=") |> tag(:assignment_operator),
        string("||") |> tag(:logical_operator),
        string("&&") |> tag(:logical_operator),
        string("--") |> tag(:update_operator),
        string("++") |> tag(:update_operator),
        string("-") |> tag(:maybe_unary_operator),
        string(">") |> tag(:binary_operator),
        string("<") |> tag(:binary_operator),
        string("*") |> tag(:binary_operator),
        string("/") |> tag(:binary_operator),
        string("%") |> tag(:binary_operator),
        string("|") |> tag(:binary_operator),
        string("^") |> tag(:binary_operator),
        string("&") |> tag(:binary_operator),
        string("+") |> tag(:maybe_unary_operator),
        string("!") |> tag(:unary_operator),
        string("~") |> tag(:unary_operator),
        string("=") |> tag(:assignment_operator)
      ])
      |> reduce({:to_atom_operator, []})

  def to_atom_operator(args) do
    Enum.map(args, fn
      {k, [v]}
      when k in [
             :assignment_operator,
             :unary_operator,
             :maybe_unary_operator,
             :binary_operator,
             :update_operator,
             :logical_operator
           ] ->
        {k, [val: String.to_atom(v)]}

      a ->
        a
    end)
    |> case do
      [{_, _} = single_operator] ->
        single_operator
      a ->
        IO.inspect(a, label: "invariant------to_atom_operator----------")
    end
  end
end
