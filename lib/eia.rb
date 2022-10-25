require 'httparty'
module Eia
  class Base
    def self.source_id
      "eia"
    end
    FUEL_MAP = {
      'COL' => 'fossil_hard_coal',
      'NG' => 'fossil_gas',
      'NUC' => 'nuclear',
      'OIL' => 'fossil_oil',
      'OTH' => 'other',
      'SUN' => 'solar',
      'WAT' => 'hydro',
      'WND' => 'wind_onshore'
    }
    def httparty_retry(&block)
      retries = 0
      loop do
        r = yield
        return r if r.ok?

        retries += 1
        raise if retries >= 5
        sleep 5
      end
    end
  end

  class Load < Base
    @@logger = SemanticLogger[Load]
    def initialize(country: nil, from: nil, to: nil)
      query = {
        api_key: ENV['EIA_TOKEN'],
        frequency: 'hourly',
        start: from.strftime("%Y-%m-%d"),
        end: to.strftime("%Y-%m-%d"),
        'data[]': 'value',
        #'facets[fueltype][]': '{}',
        'facets[type][]': 'D'
      }
      @@logger.info("from: #{query[:start]} to: #{query[:end]}")
      query['facets[respondent][]'] = country if country
      query[:offset] = 0
      @res = []
      loop do
        res = httparty_retry do
          HTTParty.get(
            "https://api.eia.gov/v2/electricity/rto/region-data/data/",
            query: query,
            #debug_output: $stdout
          )
        end
        @@logger.info "eia.gov query execution: #{res.parsed_response['response']['query execution']}"
        @@logger.info "eia.gov count query execution: #{res.parsed_response['response']['count query execution']}"
        @res << res
        #require 'pry' ; binding.pry
        if query[:offset] + res.parsed_response['response']['data'].length >= res.parsed_response['response']['total']
          break
        end
        query[:offset] += res.parsed_response['response']['data'].length
      end
    end
    def points
      r = []
      @res.each do |res|
        res.parsed_response['response']['data'].each do |row|
          if row['value'].nil?
            @@logger.warn "Skip #{row.inspect}"
            next
          end
          time = DateTime.strptime(row['period'], '%Y-%m-%dT%H')
          r << {
            time: time,
            country: "US-#{row['respondent']}",
            value: row['value']
          }
        end
      end
      #require 'pry' ; binding.pry

      r
    end
  end

  class Generation < Base
    @@logger = SemanticLogger[Generation]
    def initialize(country: nil, from: nil, to: nil)
      query = {
        api_key: ENV['EIA_TOKEN'],
        frequency: 'hourly',
        start: from.strftime("%Y-%m-%d"),
        end: to.strftime("%Y-%m-%d"),
        'data[]': 'value',
        #'facets[fueltype][]': '{}',
      }
      @@logger.info("from: #{query[:start]} to: #{query[:end]}")
      query['facets[respondent][]'] = country if country
      query[:offset] = 0
      @res = []
      loop do
        res = httparty_retry do
          HTTParty.get(
            "https://api.eia.gov/v2/electricity/rto/fuel-type-data/data/",
            query: query,
            #debug_output: $stdout
          )
        end
        @@logger.info "eia.gov query execution: #{res.parsed_response['response']['query execution']}"
        @@logger.info "eia.gov count query execution: #{res.parsed_response['response']['count query execution']}"
        @res << res
        #require 'pry' ; binding.pry
        if query[:offset] + res.parsed_response['response']['data'].length >= res.parsed_response['response']['total']
          break
        end
        query[:offset] += res.parsed_response['response']['data'].length
      end
    end

    def points
      r = []
      @res.each do |res|
        res.parsed_response['response']['data'].each do |row|
          raise row['fueltype'] if FUEL_MAP[row['fueltype']].nil?
          if row['value'].nil?
            @@logger.warn "Skip #{row.inspect}"
            next
          end
          time = DateTime.strptime(row['period'], '%Y-%m-%dT%H')
          r << {
            time: time,
            country: "US-#{row['respondent']}",
            production_type: FUEL_MAP[row['fueltype']],
            value: row['value']
          }
        end
      end
      #require 'pry' ; binding.pry

      r
    end
  end
end
