module Rubaidh
  module ActsAsParam
    module ActMethods
      def acts_as_param(options = {})
        options[:from] ||= :name
        class_inheritable_accessor :acts_as_param_options
        self.acts_as_param_options = options

        unless included_modules.include?(InstanceMethods)
          include InstanceMethods
          extend ClassMethods

          validates_uniqueness_of :param, :case_insensitive => true
          before_validation_on_create :update_param
          before_validation_on_update :update_param
        end
      end
    end
    
    module ClassMethods
      # We modify the default implementation of find_by_param so that it
      # raises an exception if the record is not found.  This makes it
      # behave more like find(id) which is useful in controllers.
      def find_by_param(param, *args)
        with_scope :find => { :conditions => ["#{table_name}.param #{attribute_condition(param)}", param] } do
          returning find(:first, *args) do |record|
            raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with param=#{param}" if record.blank?
          end
        end
      end
    end

    module InstanceMethods
      def to_param
        param
      end
      
      private
      def update_param
        from = self.send(acts_as_param_options[:from])
        unless from.blank?
          self.param = from.downcase.gsub(/[^[:alnum:]]+/, '+').chomp('+')
        end
      end
    end
  end
end
ActiveRecord::Base.send(:extend, Rubaidh::ActsAsParam::ActMethods)