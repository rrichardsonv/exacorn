defmodule ExAcorn.Expression.Conditional do
  import NimbleParsec
  import ExAcorn.Utils

  def dangling_conditional(expr \\ empty()) do
    alternate = expr |> unwrap_and_tag(:alternate)
    consequent = expr |> unwrap_and_tag(:consequent)


    optional(space_chars())
    |> ignore(question_mark())
    |> optional(whitespace())
    |> concat(consequent)
    |> optional(whitespace())
    |> ignore(colon())
    |> optional(whitespace())
    |> concat(alternate)
    |> tag(:dangling_conditional)
  end
end
