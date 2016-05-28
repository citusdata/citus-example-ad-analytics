module PostgresCopyFromClient
  extend ActiveSupport::Concern

  class CopyHandler
    def initialize(columns:, model_class:, batch_size: 50_000)
      @columns      = columns
      @model_class  = model_class
      @connection   = model_class.connection.raw_connection
      @batch_size   = batch_size
      @column_types = columns.map { |c| model_class.columns_hash[c.to_s].type }

      reset
    end

    def <<(row)
      @encoder.add row
      @row_count += 1
      run_copy if @row_count > @batch_size
    end

    def close
      run_copy if @row_count > 0
    end

    private

    def run_copy
      io = @encoder.get_io

      @connection.copy_data %{COPY #{@model_class.quoted_table_name}("#{@columns.join('","')}") FROM STDIN BINARY} do
        begin
          while chunk = io.readpartial(10240)
            @connection.put_copy_data chunk
          end
        rescue EOFError
        end
      end

      @encoder.remove
      reset

      nil
    end

    def reset
      @encoder = PgDataEncoder::EncodeForCopy.new column_types: @column_types
      @row_count = 0
    end
  end

  class_methods do
    def copy_from_client(columns, &block)
      handler = CopyHandler.new(columns: columns, model_class: self)
      block.call(handler)
      handler.close
      true
    end
  end
end
