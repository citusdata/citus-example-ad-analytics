class ApplicationController < ActionController::Base
  set_current_tenant_through_filter
  before_action :set_current_company

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  around_action :replace_sql_monitor_marker

  def replace_sql_monitor_marker(&block)
    SQL_MONITOR.reset
    ret = yield
    queries = SQL_MONITOR.reset
    response.body = response.body.gsub('SQL_MONITOR', queries.map { |q| format("%0.2fms %s", q[:duration_ms], q[:sql]) }.join("<br>"))
    ret
  end

  private

  def current_company
    company_id = session[:company_id] || 1
    puts "Param Company Id: #{company_id}"
    @current_company ||= Company.find(company_id)
  end

  def set_current_company

    set_session_from_url_param

    puts "session[:company_id]: #{session[:company_id]}"
    company = Company.find(session[:company_id])
    set_current_tenant(company)
    puts "current_company: #{company.id}"
  end

  def set_session_from_url_param
    if session[:company_id].present?
      if params[:company_id].present? && session[:company_id] != params[:company_id]
        session[:company_id] = params[:company_id]
      end
    else
      session[:company_id] = params[:company_id].present? ? params[:company_id] : 1
    end
  end
end
