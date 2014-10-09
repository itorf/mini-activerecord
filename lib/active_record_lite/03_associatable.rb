require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    unless options.keys.include?(:foreign_key)
      @foreign_key = ("#{name}_id").to_sym 
    else
      @foreign_key = options[:foreign_key].to_sym
    end
    
    unless options.keys.include?(:primary_key)
      @primary_key = :id
    else
      @primary_key = options[:primary_key]
    end
    
    unless options.keys.include?(:class_name)
      @class_name = name.to_s.singularize.camelcase
    else
      @class_name = options[:class_name].singularize.camelcase
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    unless options.keys.include?(:foreign_key)
      @foreign_key = ("#{self_class_name}_id").underscore.to_sym
    else
      @foreign_key = options[:foreign_key].to_s.underscore.to_sym
    end
    
    unless options.keys.include?(:primary_key)
      @primary_key = :id
    else
      @primary_key = options[:primary_key]
    end
    
    unless options.keys.include?(:class_name)
      @class_name = name.to_s.singularize.camelcase
    else
      @class_name = options[:class_name].singularize.camelcase
    end
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    
    define_method(name) do
      options = self.class.assoc_options[name]
      
      foreign_key = self.send(options.foreign_key)
      
      options
        .model_class
        .where(options.primary_key => foreign_key)
        .first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    
    define_method(name) do
      primary_key = self.send(options.primary_key)
      
      options
        .model_class
        .where(options.foreign_key => primary_key)
    end
  end

  def assoc_options
    # Wait to implement this in Phase V. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
