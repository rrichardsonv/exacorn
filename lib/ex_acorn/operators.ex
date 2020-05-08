defmodule ExAcorn.Operators do
  import NimbleParsec
  import ExAcorn.Utils


  @operators [
    # {:"===", , :left},
    # {:"!==", , :left},
    # {:">>>", , :left},
    # {:"<<=", , :left},
    # {:">>=", , :left},
    # {:"||",, :left},
    # {:"&&",, :left},
    # {:"--",, :left},
    # {:"++",, :left},
    # {:">>", , :left},
    # {:"<<", , :left},
    # {:"<=", , :left},
    # {:">=", , :left},
    # {:"+=",, :left},
    # {:"-=",, :left},
    # {:"*=",, :left},
    # {:"/=",, :left},
    # {:"%=",, :left},
    # {:"|=",, :left},
    # {:"^=",, :left},
    # {:"&=",, :left},
    # {:"in", , :left},
    # {:"instanceof", , :left},
    {:"=", 3, :left, :binary_expression},
    {:"-", 14, :left, :binary_expression},
    # {:">", , :left},
    # {:"<", , :left},
    {:"*", 15, :left, :binary_expression},
    {:"/", 15, :left, :binary_expression},
    # {:"%", , :left},
    # {:"|", , :left},
    # {:"^", , :left},
    # {:"&", , :left},
    {:"+", 14, :left, :binary_expression}
  ]


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
end
