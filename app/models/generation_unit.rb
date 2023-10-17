require 'composite_primary_keys'

class GenerationUnit < ActiveRecord::Base
  include SemanticLogger::Loggable
  self.table_name = 'generation_unit'
  #self.primary_keys = :time, :unit_id
  belongs_to :unit

  def self.aggregate_to_generation(from, to, where)
    logger.benchmark_info("aggregate_to_generation") do
      r = connection.exec_query <<-SQL
        INSERT INTO generation_data (area_id, production_type_id, areas_production_type_id, time, value)
        SELECT u.area_id, u.production_type_id, apt.id AS areas_production_type_id, time, SUM(value) AS value
        FROM generation_unit g
        INNER JOIN units u ON(g.unit_id=u.id)
        INNER JOIN areas a ON(u.area_id=a.id)
        INNER JOIN areas_production_types apt ON(u.area_id=apt.area_id AND u.production_type_id=apt.production_type_id)
        WHERE time BETWEEN '#{from}' AND '#{to}' AND #{where}
        GROUP BY 1,2,3,4
        ON CONFLICT (areas_production_type_id, "time") DO UPDATE set value = EXCLUDED.value
      SQL
    end

    Generation.aggregate_to_capture(from, to, where)
  end
end
