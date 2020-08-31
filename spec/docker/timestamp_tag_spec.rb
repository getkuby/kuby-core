require "spec_helper"

describe Kuby::Docker::TimestampTag do
  context '.try_parse' do
    let(:tag_str) { '20200810165134' }

    it 'creates a new timestamp tag' do
      tag = described_class.try_parse(tag_str)
      expect(tag).to be_a(described_class)
    end

    it 'correctly parses the timestamp contained in the tag' do
      time = described_class.try_parse(tag_str).time
      expect([time.year, time.month, time.day, time.hour, time.min, time.sec]).to(
        eq([2020, 8, 10, 16, 51, 34])
      )
    end

    context 'with an invalid tag' do
      let(:tag_str) { 'abc123' }

      it 'returns nil' do
        expect(described_class.try_parse(tag_str)).to eq(nil)
      end
    end
  end

  context '#to_s' do
    it 'serializes the tag as a timestamp' do
      tag = described_class.new(Time.new(2020, 8, 10, 16, 51, 34))
      expect(tag.to_s).to eq('20200810165134')
    end
  end

  context 'comparison' do
    it 'ensures tags can be compared by their timestamp values' do
      seed_time = Time.now
      times = [seed_time, seed_time + 5, seed_time + 10, seed_time + 15].shuffle
      tags = times.map { |t| described_class.new(t) }
      expect(tags.sort.map(&:time)).to eq(times.sort)
    end
  end

  context 'equality' do
    it 'ensures tags with equal times are considered equal' do
      time = Time.now
      tag1 = described_class.new(time)
      tag2 = described_class.new(time)
      expect(tag1).to eq(tag2)
      expect(tag1.hash).to eq(tag2.hash)
    end

    it 'ensures tags with inequal times are not considered equal' do
      time = Time.now
      tag1 = described_class.new(time)
      tag2 = described_class.new(time + 5)
      expect(tag1).to_not eq(tag2)
      expect(tag1.hash).to_not eq(tag2.hash)
    end
  end
end
