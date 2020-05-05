require_relative "../../test_helper"

describe Parse::Stack do
  it "must be defined" do
    _(Parse::Stack::VERSION).wont_be_nil
  end
end
