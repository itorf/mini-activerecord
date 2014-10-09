require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    columns = DBConnection.execute2(<<-SQL)
    SELECT 
      *
    FROM
      "#{table_name}"
    SQL
    
    column_names = columns[0]
    column_names.map!(&:to_sym)
  end

  def self.finalize!
    columns.each do |column_name|
      define_method(column_name) do 
        attributes[column_name]
      end
      
      define_method("#{column_name}=") do  |i|
        attributes[column_name] = i
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name.tableize
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
      "#{table_name}".*
    FROM
      "#{table_name}"
    SQL
    
    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    record = DBConnection.execute(<<-SQL, id)
    SELECT
      "#{table_name}".*
    FROM
      "#{table_name}"
    WHERE
      "#{table_name}".id = ?
    SQL
    
    parse_all(record)[0]
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'" 
      else
        self.send("#{attr_name.to_sym}=", value)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |column| send(column) }
  end

  def insert
    columns = self.class.columns
    column_names = columns.join(', ')
    question_marks = []
    columns.length.times do 
      question_marks << "?"
    end
    
    question_marks = question_marks.join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{column_names})
    VALUES
   (#{question_marks})
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns
    set_line = columns.map { |name| "#{name} = ?"}.join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    
    UPDATE 
      #{self.class.table_name}
    SET
    #{set_line}
    WHERE
      id = ?
    
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
