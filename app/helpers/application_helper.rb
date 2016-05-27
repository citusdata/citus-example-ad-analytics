module ApplicationHelper
  def current_account
    Account.first
  end
end
