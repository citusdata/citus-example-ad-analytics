# Fix for https://github.com/composite-primary-keys/composite_primary_keys/issues/365
#
# Act as if the record has a single primary key column in some cases, in
# particular when we get called from _create_record with the RETURNING result:
# https://github.com/rails/rails/blob/master/activerecord/lib/active_record/persistence.rb#L560
module FixCompositeKeyInsert
  extend ActiveSupport::Concern

  included do
    def id
      if self.class.primary_key.is_a?(Array)
        return unless attributes[self.class.primary_key[0]].present?
      end
      super
    end

    def id=(value)
      if self.class.primary_key.is_a?(Array) && !value.is_a?(Array)
        return super([value] + self.class.primary_key[1..-1].map { |a| attributes[a] })
      end
      super(value)
    end
  end
end
