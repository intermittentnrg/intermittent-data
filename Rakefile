require './lib/init'
@logger = logger = SemanticLogger['Rakefile']

require 'active_record_migrations'
ActiveRecordMigrations.load_tasks
ActiveRecordMigrations.configure do |c|
  c.schema_format = :sql
end

def pump_task(name, source, model)
  desc "Run refresh task"
  task name do |t|
    SemanticLogger.tagged(task: t.to_s) do
      Pump::Process.new(source, model).run
    end
  rescue
    @logger.error "Exception", $!
  end
end

def loop_task(name, clazz)
  desc "Run refresh task"
  task name do |t|
    SemanticLogger.tagged(task: t.to_s) do
      clazz.each &:process
    end
  rescue
    @logger.error "Exception", $!
  end
end

task :ping do |t|
  SemanticLogger.tagged(task: t.to_s) { logger.info "ping" }
end

desc "Run all refresh tasks"
multitask all: ["ieso:all", "eia:all", "caiso:all", "elexon:all", "entsoe:all", "nordpool:all", :opennem, 'aemo:all', :ree, :aeso, :hydroquebec]
namespace :ieso do
  desc "Run refresh tasks"
  task all: [:generation, :load]
  pump_task :generation, Ieso::Generation, Generation
  pump_task :load, Ieso::Load, Load
end

namespace :eia do
  desc "Run refresh tasks"
  task all: [:generation, :load]
  pump_task :generation, Eia::Generation, Generation
  pump_task :load, Eia::Load, Load
end

namespace :caiso do
  task all: [:generation, :load]
  pump_task :generation, Caiso::Generation, Generation
  pump_task :load, Caiso::Load, Load
end

namespace :elexon do
  desc "Run refresh tasks"
  task all: [:generation, :fuelinst, :load, :unit]
  pump_task :generation, Elexon::Generation, Generation
  pump_task :fuelinst, Elexon::Fuelinst, Generation
  pump_task :load, Elexon::Load, Load
  pump_task :unit, Elexon::Unit, GenerationUnit
end

namespace :entsoe do
  desc "Run refresh tasks"
  task all: [:generation, :unit, :load, :price, :transmission]
  loop_task :generation, EntsoeSFTP::Generation
  loop_task :unit, EntsoeSFTP::Unit
  loop_task :load, EntsoeSFTP::Load
  loop_task :price, EntsoeSFTP::Price
  pump_task :transmission, ENTSOE::Transmission, Transmission
end

namespace :nordpool do
  desc "Run refresh tasks"
  task all: [:transmission, :capacity, :price]
  pump_task :transmission, Nordpool::Transmission, Transmission
  pump_task :capacity, Nordpool::Capacity, Transmission
  pump_task :price, Nordpool::Price, Price
  pump_task :price_sek, Nordpool::PriceSEK, Price
end

desc "Run refresh task"
task :opennem do
  Opennem::Latest.new.process
rescue
  logger.error "Exception", $!
end

namespace :aemo do
  desc "Run refresh tasks"
  task all: ['nem:all', 'wem:all']
  namespace :nem do
    desc "Run refresh tasks"
    task all: [:trading, :scada, :rooftoppv]
    loop_task :trading, AemoNem::Trading
    loop_task :scada, AemoNem::Scada
    loop_task :rooftoppv, AemoNem::RooftopPv
  end
  namespace :wem do
    desc "Run refresh tasks"
    task all: [:scada, :balancing]
    task :scada do |t|
      SemanticLogger.tagged(task: t.to_s) do
        AemoWem::ScadaLive.new.process
      end
    end
    loop_task :balancing, AemoWem::Balancing
    #AemoWem::BalancingLive.new.process
  end
end

pump_task :ree, Ree::Generation, Generation

desc "Run refresh tasks"
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
