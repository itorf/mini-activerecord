require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

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
    columns.each do |column|
      define_method("#{column}=") do |i|
        attributes[column] = i
      end
      
      define_method(column) do
        attributes[column]
      end
    end
    
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    records = DBConnection.execute(<<-SQL)
    SELECT
      "#{self.table_name}".*
    FROM
      "#{self.table_name}"
      
      SQL
    
      parse_all(records)

  end

  def self.parse_all(results)
    results.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    record = DBConnection.execute(<<-SQL, id)
    SELECT
    #{table_name}.*
    FROM
    #{table_name}
    WHERE
    #{table_name}.id = ?
    SQL
    
    parse_all(record)[0]
    
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    columns = self.class.columns
    col_names = columns.join(", ")
    question_marks = []
    columns.length.times do 
      question_marks << "?"
    end
    question_marks = question_marks.join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params= {})
    params.each do |name, value|
      raise "unknown attribute '#{name}'" unless self.class.columns.include?(name.to_sym)
      self.send("#{name.to_sym}=", value)
    end
  end

  def save
    if id.nil?
      self.insert
    else
      self.update
    end
  end

  def update
    columns = self.class.columns
    columns.map!(&:to_s)
    set_line = columns.map {|value| " #{value} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      #{self.class.table_name}.id = ?
    SQL
  end

  def attribute_values
    self.class.columns.map { |value| send(value)}
  end
end

