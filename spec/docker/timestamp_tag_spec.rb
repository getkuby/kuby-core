require "spec_helper"

describe Kuby::Docker::TimestampTag do
  context ".try_parse" do
    it "returns a new timestamp tag" do
      tag = described_class.try_parse("20200810165134")

      expect(tag).to be_kind_of(described_class)
    end
  end
end
