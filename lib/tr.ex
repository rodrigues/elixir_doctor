defmodule TR do
  @moduledoc """
  This provides easier access to `:tr` module,
  defined by the [erlang_doctor](https://hex.pm/packages/erlang_doctor) package.
  """

  @source :tr

  # record helper to ease pattern matching
  require Record

  @record_config Record.extract(
    @source,
    from_lib: "erlang_doctor/include/tr.hrl"
  )

  @record_keys Keyword.keys(@record_config)

  Record.defrecord(@source, @record_config)

  def record_to_map(tr_record) when elem(tr_record, 0) == :tr do
    [:tr | rest] = Tuple.to_list(tr_record)

    for {item, index} <- Enum.with_index(rest), into: %{} do
      {Enum.at(@record_keys, index), item}
    end
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
  # TODO make that map compat
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
