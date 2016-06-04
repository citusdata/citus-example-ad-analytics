# Note that for simplicity's sake this is not thread-safe

class SqlMonitor
  def initialize
    reset
  end

  def start(name, id, payload)
    return if %w(CACHE SCHEMA).include?(payload[:name])

    @last_start = Time.now
  end

  def finish(name, id, payload)
    return if %w(CACHE SCHEMA).include?(payload[:name])

    @queries << { sql: payload[:sql], duration_ms: (Time.now - @last_start) * 1000 }
  end

  def reset
    ret = @queries
    @queries = []
    ret
  end
end

SQL_MONITOR = SqlMonitor.new

ActiveSupport::Notifications.subscribe('sql.active_record', SQL_MONITOR)
