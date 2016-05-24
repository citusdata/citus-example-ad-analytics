module DistributedCitusTable
  extend ActiveSupport::Concern

  included do
    disable_transactions
  end
end
