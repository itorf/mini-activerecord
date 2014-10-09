require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map { |key, value| "#{key} = ? " }.join(" AND ")
    attributes = params.values
    
    results = DBConnection.execute(<<-SQL, attributes)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{where_line}
    SQL
    
    parse_all(results)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end