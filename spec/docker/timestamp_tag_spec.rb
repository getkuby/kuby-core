RSpec.describe Kuby::Docker::TimestampTag, ".try_parse" do
  context "with valid timestamp string" do
    it "returns a new timestamp tag" do
      tag = Kuby::Docker::TimestampTag.try_parse("20200810165134")

      expect(tag).to be_kind_of(Kuby::Docker::TimestampTag)
    end
  end
end
