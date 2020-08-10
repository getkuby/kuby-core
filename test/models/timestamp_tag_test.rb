require "test_helper"
require 'time'

class TimestampTagTest < Minitest::Test

  def test_try_parse_returns_tag_if_input_is_valid_timestamp
    assert Kuby::Docker::TimestampTag.try_parse("20200810165134")
  end

  def test_try_parse_returns_nil_on_nil
    assert_nil Kuby::Docker::TimestampTag.try_parse(nil)
  end

  def test_try_parse_returns_nil_on_invalid_timestamp
    assert_nil Kuby::Docker::TimestampTag.try_parse("2020")
  end
end
