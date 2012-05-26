require 'dynamoid'

module Dynamoid
  module Document
    module ClassMethods
      include OrmAdapter::ToAdapter
    end

    class OrmAdapter < ::OrmAdapter::Base
      # Do not consider these to be part of the class list
      def self.except_classes
        @@except_classes ||= []
      end

      # Gets a list of the available models for this adapter
      def self.model_classes
        ObjectSpace.each_object(Class).to_a.select {|klass| klass.ancestors.include? Dynamoid::Document}
      end

      # get a list of column names for a given class
      def column_names
        klass.new.attributes.keys
      end

      # @see OrmAdapter::Base#get!
      def get!(id)
        rec = klass.find_by_id(wrap_key(id))
        raise "Record not found" if rec.nil?
        rec
      end

      # @see OrmAdapter::Base#get
      def get(id)
        klass.find(id)
      end

      # @see OrmAdapter::Base#find_first
      def find_first(options)
        conditions, order = extract_conditions_and_order!(options)
        record = klass.where(conditions_to_fields(conditions)).limit(1)
        record.empty? ? nil : record.first
      end

      # @see OrmAdapter::Base#find_all
      def find_all(options)
        conditions, order = extract_conditions_and_order!(options)
        order_field, asc_or_desc = order
        klass.where(conditions_to_fields(conditions)).sort do |a,b|
          if asc_or_desc == :asc
            a.send(order) <=> b.send(order)
          else
            b.send(order) <=> a.send(order)
          end
        end #.order_by(order)
      end

      # @see OrmAdapter::Base#create!
      def create!(attributes)
        klass.create!(attributes)
      end

    protected

      # converts and documents to ids
      def conditions_to_fields(conditions)
        conditions.inject({}) do |fields, (key, value)|
          if value.is_a?(Dynamoid::Document) && klass.attributes.keys.include?("#{key}_ids".to_sym)
            fields.merge("#{key}_ids".to_sym => Set[value.id])
          else
            fields.merge(key => value)
          end
        end
      end
    end
  end
end
