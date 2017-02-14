module ApplicationHelper
  def current_company
    Company.first
  end
end
