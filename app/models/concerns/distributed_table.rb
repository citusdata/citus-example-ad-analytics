module DistributedTable
  extend ActiveSupport::Concern

  included do
    include PostgresCopyFromClient

    disable_transactions

    def id
      if self.class.primary_key.is_a?(Array)
        # composite-primary-keys gets confused since our id isn't marked as a primary key, so do it manually
        self.class.primary_key.map { |a| attributes[a] }
      else
        attributes[self.class.primary_key]
      end
    end
  end
end
