require './lib/init'
@logger = logger = SemanticLogger['Rakefile']

require 'active_record_migrations'
ActiveRecordMigrations.load_tasks
ActiveRecordMigrations.configure do |c|
  c.schema_format = :sql
end

def pump_task(name, source, model)
  task name do
    Pump::Process.new(source, model).run
  rescue
    @logger.error "Exception", $!
  end
end

def loop_task(name, clazz)
  task name do
    clazz.each &:process
  end
end

task :ping do
  logger.info "ping"
end

multitask all: ["ieso:all", "eia:all", "caiso:generation", "elexon:all", "entsoe:all", "nordpool:all", :opennem, 'aemo:all', :ree, :aeso, :hydroquebec]
namespace :ieso do
  task all: [:generation, :load]
  pump_task :generation, Ieso::Generation, Generation
  pump_task :load, Ieso::Load, Load
end

namespace :eia do
  task all: [:generation, :load]
  pump_task :generation, Eia::Generation, Generation
  pump_task :load, Eia::Load, Load
end

namespace :caiso do
  pump_task :generation, Caiso::Generation, Generation
end

namespace :elexon do
  task all: [:generation, :fuelinst, :load, :unit]
  pump_task :generation, Elexon::Generation, Generation
  pump_task :fuelinst, Elexon::Fuelinst, Generation
  pump_task :load, Elexon::Load, Load
  pump_task :unit, Elexon::Unit, GenerationUnit
end

namespace :entsoe do
  task all: [:generation, :unit, :load, :price, :transmission]
  loop_task :generation, EntsoeSFTP::Generation
  loop_task :unit, EntsoeSFTP::Unit
  loop_task :load, EntsoeSFTP::Load
  loop_task :price, EntsoeSFTP::Price
  pump_task :transmission, ENTSOE::Transmission, Transmission
end

namespace :nordpool do
  task all: [:transmission, :capacity, :price]
  pump_task :transmission, Nordpool::Transmission, Transmission
  pump_task :capacity, Nordpool::Capacity, Transmission
  pump_task :price, Nordpool::Price, Price
end

task :opennem do
  Opennem::Latest.new.process
rescue
  logger.error "Exception", $!
end

namespace :aemo do
  task all: ['nem:all', 'wem:all']
  namespace :nem do
    task all: [:trading, :scada, :rooftoppv]
    task :trading do
      AemoNem::Trading.each(&:process)
    end
    task :scada do
      AemoNem::Scada.each(&:process)
    end
    task :rooftoppv do
      AemoNem::RooftopPv.each(&:process)
    end
  end
  namespace :wem do
    task all: [:scada, :balancing]
    task :scada do
      AemoWem::Scada.each(&:process)
      #AemoWem::ScadaLive.new.process
    end
    task :balancing do
      AemoWem::Balancing.each(&:process)
      #AemoWem::BalancingLive.new.process
    end
  end
end

pump_task :ree, Ree::Generation, Generation

task :aeso do
  Aeso::Generation.new.process
rescue
  logger.error "Exception", $!
end

task :hydroquebec do
  HydroQuebec::Generation.new.process
rescue
  logger.error "Exception", $!
end

# task :nspower do
#   Nspower::Combined.new.process
# rescue
#   logger.error "Exception", $!
# end
