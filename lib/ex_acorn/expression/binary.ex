defmodule ExAcorn.Expression.Binary do
  import NimbleParsec
  import ExAcorn.Utils

  def dangling_binary(expr \\ empty()) do
    operator =
      choice([
        string("==="),
        string("!=="),
        string(">>>"),
        string(">>"),
        string("<<"),
        string("<="),
        string(">="),
        string("in") |> ignore(whitespace()),
        string("instanceof") |> ignore(whitespace()),
        string("-"),
        string(">"),
        string("<"),
        string("*"),
        string("/"),
        string("%"),
        string("|"),
        string("^"),
        string("&"),
        string("+")
      ])
      |> reduce({__MODULE__, :binary_atom_operator, []})
      |> unwrap_and_tag(:operator)

    optional(space_chars())
    |> concat(operator)
    |> optional(whitespace())
    |> concat(expr |> unwrap_and_tag(:right))
    |> tag(:dangling_binary)
  end

  @operators ["===","!==",">>>",">>","<<","<=",">=","in","instanceof","-",">","<","*","/","%","|","^","&","+"]
  def binary_atom_operator(args) do
    Enum.map(args, fn
      v when v in @operators ->
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
        IO.inspect(a, label: "invariant------binary_atom_operator----------")
    end
  end
end
