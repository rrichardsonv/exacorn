defmodule ExAcorn.Operators do
  import NimbleParsec
  import ExAcorn.Utils


  @operators [
    {:"===", 11, :left, :logical_expression},
    {:"!==", 11, :left, :logical_expression},
    {:"==", 11, :left, :logical_expression},
    {:"!=", 11, :left, :logical_expression},
    {:">>>=", 3, :left, :binary_expression},
    {:">>>", 13, :left, :binary_expression},
    {:"<<=", 3, :left, :binary_expression},
    {:">>=", 3, :left, :binary_expression},
    {:"**", 16, :left, :binary_expression},
    {:"||", 5, :left, :logical_expression},
    {:"&&", 6, :left, :logical_expression},
    {:"??", 7, :left, :binary_expression},
    # {:"--",, :left},
    # {:"++",, :left},
    {:">>", 13, :left, :binary_expression},
    {:"<<", 13, :left, :binary_expression},
    {:"<=", 12, :left, :binary_expression},
    {:">=", 12, :left, :binary_expression},
    {:"+=", 3, :left, :binary_expression},
    {:"-=", 3, :left, :binary_expression},
    {:"**=", 3, :left, :binary_expression},
    {:"*=", 3, :left, :binary_expression},
    {:"/=", 3, :left, :binary_expression},
    {:"%=", 3, :left, :binary_expression},
    {:"|=", 3, :left, :binary_expression},
    {:"^=", 3, :left, :binary_expression},
    {:"&=", 3, :left, :binary_expression},
    {:in, 12, :left, :binary_expression},
    {:instanceof, 12, :left, :binary_expression},
    {:"=", 3, :left, :binary_expression},
    {:"-", 14, :left, :maybe_binary_expression},
    {:">", 12, :left, :binary_expression},
    {:"<", 12, :left, :binary_expression},
    {:"*", 15, :left, :binary_expression},
    {:"/", 15, :left, :binary_expression},
    {:"%", 15, :left, :binary_expression},
    {:"|", 8, :left, :binary_expression},
    {:"^", 9, :left, :binary_expression},
    {:"&", 10, :left, :binary_expression},
    {:"+", 14, :left, :binary_expression},
    {:".", 20, :left, :member_access}
  ]

  def grouping_operator do
    optional(space_chars())
    |> choice([
      ignore(string("(")) |> reduce({__MODULE__, :tag_special, [:left_paren, 21]}),
      ignore(string(")")) |> reduce({__MODULE__, :tag_special, [:right_paren, 21]}),
      ignore(string("[")) |> reduce({__MODULE__, :tag_special, [:left_bracket, 20]}),
      ignore(string("]")) |> reduce({__MODULE__, :tag_special, [:right_bracket, 20]}),
      ignore(string(",")) |> reduce({__MODULE__, :tag_special, [:seq, 1]})
    ])
  end


  def operator do
    operators =
      Enum.map(@operators, fn {o, r, a, k} ->
          o
          |> Atom.to_string()
          |> string()
          |> ignore()
          |> reduce({__MODULE__, :tag_operator, [o, r, a, k]})
      end)

    optional(space_chars()) |> choice(operators)
  end

  def tag_operator(_, opp, rank, assoc, key) do
    {:op, [id: opp, rank: rank, assoc: assoc, key: key]}
  end

  def tag_special(_, tag_nm, rank) do
    {tag_nm, [rank: rank]}
  end
end
