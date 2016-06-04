class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  around_action :replace_sql_monitor_marker

  def replace_sql_monitor_marker(&block)
    SQL_MONITOR.reset
    ret = yield
    queries = SQL_MONITOR.reset
    response.body = response.body.gsub('SQL_MONITOR', queries.map {|q| format("%0.2fms %s", q[:duration_ms], q[:sql]) }.join("<br>"))
    ret
  end
end
