require './spec/spec_helper'
require 'timecop'

RSpec.describe Eia::Generation do
  subject { Eia::Generation }
  context do
    let(:e) do
      VCR.use_cassette("generation_#{country}_#{from}_#{to}") do
        subject.new(country:, from: Date.parse(from), to: Date.parse(to))
      end
    end
    describe 'EIA BANC gas validation' do
      let(:country) { 'BANC' }
      let(:from) { '2019-07-25' }
      let(:to) { '2019-07-26' }
      it { expect(e.points_generation.map { |p| p[:value] }.max).to be < 400000000 }
      include_examples "logs error", "generation"
    end
  end

  describe :cli do
  end

  describe :each do
    around(:example) { |ex| Timecop.freeze(current_time, &ex) }
    around(:example) { |ex| VCR.use_cassette('eia_generation_parsers_each', &ex) }
    let(:current_time) { Time.new(2023,1,1) }
    let(:datapoint_time) { Time.new(2023,1,1) }
    before do
      areas = Area.find_by! code: 'CISO', source: 'eia'
      production_type = ProductionType.find_by! name: 'wind'
      apt = areas.areas_production_type.find_by!(production_type:)
      apt.generation.create(time: datapoint_time, value: 1000)
    end

    it do
      expect(::Generation).to receive(:upsert_all)
      subject.each &:process
    end
  end
end

RSpec.describe Eia::Load do
  subject { Eia::Load }

  describe :cli do
  end

  describe :each do
    around(:example) { |ex| Timecop.freeze(current_time, &ex) }
    around(:example) { |ex| VCR.use_cassette('eia_load_parsers_each', &ex) }
    let(:current_time) { Time.new(2023,1,1) }
    let(:datapoint_time) { Time.new(2023,1,1) }
    before do
      areas = Area.find_by! code: 'BANC', source: 'eia'
      areas.load.create time: datapoint_time, value: 1000
    end

    it do
      expect(::Load).to receive(:upsert_all)
      subject.each &:process
    end
  end
end

RSpec.describe Eia::Interchange do
  subject { Eia::Interchange }

  describe :cli do
    around(:example) { |ex| VCR.use_cassette('eia_interchange', &ex) }
    it do
      expect(Transmission).to receive(:upsert_all)
      Eia::Interchange.cli(['2024-01-01', '2024-01-02', 'CISO'])
    end
  end
end
