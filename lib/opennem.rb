require 'httparty'
module Opennem
  class Base
    def self.source_id
      "opennem"
    end
    REGION_MAP = {
      "AUS-NSW" => "NSW1",
      "AUS-QLD" => "QLD1",
      "AUS-SA" => "SA1",
      "AUS-TAS" => "TAS1",
      "AUS-VIC" => "VIC1",
      "AUS-WA" => "WEM",
    }
    NETWORK_MAP = {
      "AUS-NSW" => "NEM",
      "AUS-QLD" => "NEM",
      "AUS-SA" => "NEM",
      "AUS-TAS" => "NEM",
      "AUS-VIC" => "NEM",
      "AUS-WA" => "WEM",
    }
    FUEL_MAP = {
      "coal_black" => "fossil_hard_coal",
      "coal_brown" => "fossil_brown_coal/lignite",
      "gas_ccgt" => "fossil_gas_ccgt",
      "gas_ocgt" => "fossil_gas_ocgt",
      "gas_recip" => "fossil_gas_reciprocating",
      "gas_steam" => "fossil_gas_steam",
      "gas_wcmg" => "fossil_gas_coal_mine_waste",
      "distillate" => "fossil_oil_distillate",
      "hydro" => "hydro",
      "wind" => "wind",
      "bioenergy_biogas" => "biogas",
      "bioenergy_biomass" => "biomass",
      "solar_utility" => "solar_utility",
      "solar_rooftop" => "solar_rooftop",
      # Storage
      "battery_charging" => "battery_charging",
      "battery_discharging" => "battery",
      "pumps" => "hydro_pumped_storage",
    }

    def parse_interval(interval)
      case interval
      when "5m"
        5.minutes
      when "30m"
        30.minutes
      else
        raise interval
      end
    end

    def points
      return if @load_r

      @load_r = []
      @gen_r = []
      @res['data'].each do |blob|
        next if blob['type'] == 'price' #FIXME ingest price data
        next if blob['type'] == 'temperature'
        next if blob['type'].starts_with? 'emissions'
        next if blob['code'].include? '>'
        next if blob['code'] == 'imports' || blob['code'] == 'exports'
        raise blob['units'] unless blob['units'] == 'MW'
        country = "#{blob['network']}-#{blob['region']}".upcase
        country = "WEM-WEM" if blob['network'] == 'WEM'
        start = Time.strptime(blob['history']['start'], '%Y-%m-%dT%H:%M:%S%:z')
        interval = parse_interval(blob['history']['interval'])

        if blob['code'] == 'demand'
          blob['history']['data'].each_with_index do |value,index|
            time = start + interval * index
            @load_r << {
              time: time,
              country: country,
              value: value
            }
          end
        else
          type = FUEL_MAP[blob['fuel_tech']]
          require 'pry' ; binding.pry if type.nil?
          raise blob['fuel_tech'] if type.nil?

          blob['history']['data'].each_with_index do |value,index|
            time = start + interval * index
            next if value.nil?

            if blob['fuel_tech'] == 'battery_charging' || blob['fuel_tech'] == 'pumps'
              value = -value
            end
            @gen_r << {
              time: time,
              production_type: type,
              country: country,
              value: value.round
            }
          end
        end
      end

      #require 'pry' ; binding.pry
    end
    def points_load
      points
      logger.info("#{@load_r.length} points")

      @load_r
    end
    def points_generation
      points
      logger.info("#{@gen_r.length} points")

      @gen_r
    end
  end

  class Month < Base
    include SemanticLogger::Loggable
    include Out::Generation

    def initialize(country: nil, date: nil)
      @from = date
      @to = date + 1.month
      network, region = country.split(/-/)
      query = {
        month: date.strftime('%Y-%m-%d')
      }
      url = "https://api.opennem.org.au/stats/power/network/fueltech/#{network}/#{region}"
      @res = logger.benchmark_info(url) do
        HTTParty.get(
          url,
          query: query,
          timeout: 180,
          #debug_output: $stdout
        )
      end
    end
  end

  class Week < Base
    include SemanticLogger::Loggable
    include Out::Generation

    def initialize(country: nil, date: nil)
      @from = date.beginning_of_week
      @to = @from + 1.week
      network, region = country.split(/-/)
      url = "https://data.opennem.org.au/v3/stats/historic/weekly/#{network}/#{region}/year/#{date.strftime('%Y')}/week/#{date.strftime('%U').to_i + 1}.json"
      @res = logger.benchmark_info(url) do
        HTTParty.get(
          url,
          timeout: 180,
          #debug_output: $stdout
        )
      end
    end
  end

  class Year < Base
    include SemanticLogger::Loggable
    include Out::Generation

    def initialize(country: nil, date: nil)
      network, region = country.split(/-/)
      url = "https://data.opennem.org.au/v3/stats/au/#{network}/#{region}/energy/#{date.strftime('%Y')}.json"
      @res = logger.benchmark_info(url) do
        HTTParty.get(
          url,
          timeout: 180,
          debug_output: $stdout
        )
      end
    end
  end

  class Latest < Base
    include SemanticLogger::Loggable
    include Out::Generation
    def initialize
      url = "https://data.opennem.org.au/v3/clients/em/latest.json"
      @res = logger.benchmark_info(url) do
        HTTParty.get(url)
      end
      @from = @res['data'][0]['history']['start']
      @to = @res['data'][0]['history']['last']
    end
  end

  # NOTE: Missing WEM-WEM data
  class LatestWeek < Base
    include SemanticLogger::Loggable
    include Out::Load
    include Out::Generation

    def initialize(country)
      network, region = country.split(/-/)
      url = "https://data.opennem.org.au/v3/stats/au/#{network}/#{region}/power/7d.json"
      @res = logger.benchmark_info(url) do
        HTTParty.get(url)
      end
      @from = @res['data'][0]['history']['start']
      @to = @res['data'][0]['history']['last']
    end
    def process
      process_load
      process_generation
    end
  end
end
