defmodule ExAcorn.Statement.ImportStatement do
  import NimbleParsec
  # import ExAcorn.Common
  # import ExAcorn.Utils

  def import_meta_statement do
    string("import.meta") |> tag(:import_meta_statement)
  end

  def import_statement do
    string("import") |> tag(:import_statement)
  end
end
