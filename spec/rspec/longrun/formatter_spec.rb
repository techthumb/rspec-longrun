require "rspec/longrun"
require "stringio"

describe RSpec::Longrun::Formatter do

  let(:output_buffer) { StringIO.new }
  let(:formatter) { described_class.new(output_buffer) }

  def undent(raw)
    if raw =~ /\A( +)/
      indent = $1
      raw.gsub(/^#{indent}/, '').gsub(/ +$/, '')
    else
      raw
    end
  end

  def output
    output_buffer.string
  end

  module NoColor

    def color_enabled?
      false
    end

  end

  before do
    formatter.extend(NoColor)
    suite.run(formatter)
  end

  context "for nested example groups" do

    let(:suite) do
      RSpec::Core::ExampleGroup.describe("foo") do
        describe "bar" do
          describe "baz" do
          end
        end
        describe "qux" do
        end
      end
    end

    it "outputs nested group names" do
      output.should eql(undent(<<-EOF))
        foo {
          bar {
            baz (0.00s)
          } (0.00s)
          qux (0.00s)
        } (0.00s)
      EOF
    end

  end

  context "with examples" do

    let(:suite) do
      RSpec::Core::ExampleGroup.describe("suite") do
        example "works" do; end
        example "is unimplemented" do
          pending "implement me"
        end
        example "fails" do
          fail "no worky"
        end
      end
    end

    it "outputs example names and status" do
      output.should eql(undent(<<-EOF))
        suite {
          works OK (0.00s)
          is unimplemented PENDING: implement me (0.00s)
          fails FAILED (0.00s)
        } (0.00s)
      EOF
    end

  end

  context "with steps" do

    let(:suite) do
      RSpec::Core::ExampleGroup.describe("suite") do
        include RSpec::Longrun::DSL
        example "has steps" do
          step "Collect underpants" do
          end
          step "Er ..." do
            step "(thinking)" do
            end
          end
          step "Profit!"
        end
      end
    end

    it "outputs steps" do
      output.should eql(undent(<<-EOF))
        suite {
          has steps {
            Collect underpants (0.00s)
            Er ... {
              (thinking) (0.00s)
            } (0.00s)
          } PENDING: Profit! (0.00s)
        } (0.00s)
      EOF
    end

  end

end
