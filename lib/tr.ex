defmodule TR do
  @external_resource "README.md"
  @moduledoc "README.md" |> File.read!()

  @source :tr

  # record helper to ease pattern matching
  require Record

  @record_config Record.extract(
                   @source,
                   from_lib: "erlang_doctor/include/tr.hrl"
                 )

  @record_keys Keyword.keys(@record_config)

  defstruct @record_keys

  Record.defrecord(@source, @record_config)

  @doc ~S"""
  Converts tr records into structs, which are more
  inspectable and navigable in Elixir.
  """
  def pretty(tr_record) when elem(tr_record, 0) == :tr do
    [:tr | rest] = Tuple.to_list(tr_record)

    for {value, index} <- Enum.with_index(rest), reduce: %TR{} do
      %TR{} = struct ->
        key = Enum.at(@record_keys, index)
        Map.put(struct, key, value)
    end
  end

  def pretty(tr_records) when is_list(tr_records) do
    Enum.map(tr_records, &pretty/1)
  end

  # capturing, data manipulation
  defdelegate start_link, to: @source
  defdelegate start_link(opts), to: @source
  defdelegate start, to: @source
  defdelegate start(opts), to: @source
  defdelegate trace_calls(modules), to: @source
  defdelegate stop_tracing_calls, to: @source
  defdelegate stop, to: @source
  defdelegate tab, to: @source
  defdelegate set_tab(tab), to: @source
  defdelegate load(file), to: @source
  defdelegate dump(file), to: @source
  defdelegate clean, to: @source

  # analysis
  defdelegate select, to: @source
  defdelegate select(selector_fun), to: @source
  defdelegate select(selector_fun, data_value), to: @source
  defdelegate filter(predicate), to: @source
  defdelegate filter(predicate, tab), to: @source
  defdelegate filter_tracebacks(predicate), to: @source
  defdelegate filter_tracebacks(predicate, tab), to: @source
  defdelegate filter_ranges(predicate), to: @source
  defdelegate filter_ranges(predicate, opts), to: @source
  defdelegate print_sorted_call_stat(selector_fun, length), to: @source
  defdelegate sorted_call_stat(selector_fun), to: @source
  defdelegate call_stat(selector_fun), to: @source
  defdelegate call_stat(selector_fun, tab), to: @source

  # utilities
  defdelegate contains_data(data_value, trace), to: @source
  defdelegate call_selector(selector_fun), to: @source
  defdelegate app_modules(app_name), to: @source
end
