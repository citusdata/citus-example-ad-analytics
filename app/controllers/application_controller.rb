class ApplicationController < ActionController::Base
  set_current_tenant_through_filter
  before_filter :set_current_account

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

  private

  def current_account
    @current_account ||= Account.find(1)
  end

  def set_current_account
    set_current_tenant(current_account)
  end
end
