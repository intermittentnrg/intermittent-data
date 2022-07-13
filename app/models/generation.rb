require 'semantic_logger'
require './lib/elexon'

class Generation < ActiveRecord::Base
  @@logger = SemanticLogger[Generation]
  self.table_name = 'generation'
  belongs_to :area

  def self.parsers_each(source)
    self.joins(:area).group(:'area.code').where("time > ?", 2.months.ago).where(area: {source: source.source_id}).pluck(:'area.code', Arel.sql("LAST(time, time)")).each do |country, from|
      from = from.to_datetime
      to = [from + 1.year, DateTime.now.beginning_of_hour].min
      if from > 4.hours.ago
        @@logger.info "has data in last 4 hours. skipping"
        next
      end
      SemanticLogger.tagged(country) do
        # support source per day and date-range
        #require 'pry' ; binding.pry
        if source == Elexon::Generation
          (from..to).each do |date|
            yield source.new date
          end
        else
          yield source.new(country: country, from: from, to: to)
        end
      end
    end
  end
end