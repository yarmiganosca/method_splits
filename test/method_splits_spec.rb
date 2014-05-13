require_relative 'test_helper'

describe MethodSplits do
  before do
    class Thing
      include MethodSplits

      def do_something_to_stuff(something, *other_things)
        [something, other_things]
      end

      split_method(:do_something_to_stuff, :do_something, :to_stuff)
    end
  end

  let(:thing) { Thing.new }

  it "splits the method" do
    thing.do_something(:something).to_stuff(:thing, :other_thing).must_equal [:something, [:thing, :other_thing]]
  end
end
