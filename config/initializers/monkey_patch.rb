class ActiveRecord::Base
  def self.disable_transactions
    @disable_transactions = true
  end

  def self.transactions_disabled?
    !!@disable_transactions
  end
end

module ActiveRecord::Transactions
  def with_transaction_returning_status_with_disable_transactions(&block)
    if self.class.transactions_disabled?
      yield
    else
      with_transaction_returning_status_without_disable_transactions(&block)
    end
  end

  alias_method_chain :with_transaction_returning_status, :disable_transactions
end
