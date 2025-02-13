# typed: true
# frozen_string_literal: true

require "test_helper"

module RubyLsp
  class TestCollectionTest < Minitest::Test
    def setup
      @uri = URI::Generic.from_path(path: "/fake_test.rb")
      @range = Interface::Range.new(
        start: Interface::Position.new(line: 0, character: 0),
        end: Interface::Position.new(line: 10, character: 3),
      )
    end

    def test_allows_building_hierarchy_of_tests
      builder = ResponseBuilders::TestCollection.new
      test_item = Requests::Support::TestItem.new("my-id", "Test label", @uri, @range)
      nested_item = Requests::Support::TestItem.new("nested-id", "Nested label", @uri, @range)

      builder.add(test_item)
      test_item.add(nested_item)

      item = builder["my-id"]
      assert(item)
      assert(T.must(item)["nested-id"])

      builder.response.map(&:to_hash).each { |item| assert_expected_fields(item) }
    end

    def test_raises_if_trying_to_add_item_with_same_id
      builder = ResponseBuilders::TestCollection.new
      test_item = Requests::Support::TestItem.new("my-id", "Test label", @uri, @range)
      nested_item = Requests::Support::TestItem.new("nested-id", "Nested label", @uri, @range)

      builder.add(test_item)
      test_item.add(nested_item)

      assert_raises(ResponseBuilders::TestCollection::DuplicateIdError) do
        builder.add(Requests::Support::TestItem.new("my-id", "Other title, but same ID", @uri, @range))
      end

      assert_raises(ResponseBuilders::TestCollection::DuplicateIdError) do
        test_item.add(Requests::Support::TestItem.new("nested-id", "Other title, but same ID", @uri, @range))
      end
    end

    private

    def assert_expected_fields(hash)
      [:id, :label, :uri, :range, :children].each do |field|
        assert(hash[field])
      end

      hash[:children].each { |child| assert_expected_fields(child) }
    end
  end
end
