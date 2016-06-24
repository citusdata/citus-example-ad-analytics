module ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements
  def default_sequence_name_with_composite_keys(table_name, pk = nil)
    return nil if pk.is_a?(Array)
    default_sequence_name_without_composite_keys(table_name, pk)
  end
  alias_method_chain :default_sequence_name, :composite_keys
end
