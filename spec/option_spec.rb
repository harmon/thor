require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/option'

describe Thor::Option do
  def parse(key, value)
    Thor::Option.parse(key, value)
  end

  def option(name, description=nil, required=false, type=:default, default=nil, aliases=[])
    @option ||= Thor::Option.new(name, description, required, type, default, aliases)
  end

  describe "#parse" do

    describe "with value as a symbol" do
      describe "and symbol is a valid type" do
        it "has type equals to the symbol" do
          parse(:foo, :string).type.must == :string
          parse(:foo, :numeric).type.must == :numeric
        end

        it "has not default value" do
          parse(:foo, :string).default.must be_nil
          parse(:foo, :numeric).default.must be_nil
        end
      end

      describe "equals to :required" do
        it "has type equals to :string" do
          parse(:foo, :required).type.must == :string
        end

        it "has no default value" do
          parse(:foo, :required).default.must be_nil
        end
      end

      describe "equals to :optional" do
        it "has type equals to :default" do
          parse(:foo, :optional).type.must == :default
        end

        it "has no default value" do
          parse(:foo, :optional).default.must be_nil
        end
      end

      describe "and symbol is not a reserved key" do
        it "has type equals to :default" do
          parse(:foo, :bar).type.must == :default
        end

        it "has no default value" do
          parse(:foo, :bar).default.must be_nil
        end
      end
    end

    describe "with value as hash" do
      it "has default type :hash" do
        parse(:foo, :a => :b).type.must == :hash
      end

      it "has default value equals to the hash" do
        parse(:foo, :a => :b).default.must == { :a => :b }
      end
    end

    describe "with value as array" do
      it "has default type :array" do
        parse(:foo, [:a, :b]).type.must == :array
      end

      it "has default value equals to the array" do
        parse(:foo, [:a, :b]).default.must == [:a, :b]
      end
    end

    describe "with value as string" do
      it "has default type :string" do
        parse(:foo, "bar").type.must == :string
      end

      it "has default value equals to the string" do
        parse(:foo, "bar").default.must == "bar"
      end
    end

    describe "with value as numeric" do
      it "has default type :numeric" do
        parse(:foo, 2.0).type.must == :numeric
      end

      it "has default value equals to the numeric" do
        parse(:foo, 2.0).default.must == 2.0
      end
    end

    describe "with value as boolean" do
      it "has default type :boolean" do
        parse(:foo, true).type.must == :boolean
        parse(:foo, false).type.must == :boolean
      end

      it "has default value equals to the boolean" do
        parse(:foo, true).default.must == true
        parse(:foo, false).default.must == false
      end
    end

    describe "with key as a symbol" do
      it "sets the name equals to the key" do
        parse(:foo, true).name.must == "foo"
      end
    end

    describe "with key as an array" do
      it "sets the first items in the array to the name" do
        parse([:foo, :bar, :baz], true).name.must == "foo"
      end

      it "sets all other items as aliases" do
        parse([:foo, :bar, :baz], true).aliases.must == [:bar, :baz]
      end
    end
  end

  it "can be required" do
    parse(:foo, :required).must be_required
    parse(:foo, :required).must_not be_optional
  end

  it "can be optional" do
    parse(:foo, :optional).must_not be_required
    parse(:foo, :optional).must be_optional
  end

  it "requires an input when type is a string, array, hash or numeric" do
    [:string, :array, :hash, :numeric].each do |type|
      parse(:foo, type).input_required?.must be_true
    end
  end

  it "does not require an input when type is default or boolean" do
    [:default, :boolean].each do |type|
      parse(:foo, type).input_required?.must be_false
    end
  end

  it "returns the switch name" do
    option("foo").switch_name.must == "--foo"
    option("--foo").switch_name.must == "--foo"
  end

  it "returns the human name" do
    option("foo").human_name.must == "foo"
    option("--foo").human_name.must == "foo"
  end

  it "converts underscores to dashes" do
    option("foo_bar").switch_name.must == "--foo-bar"
  end

  it "is not an argument" do
    option(:task).must_not be_argument
  end

  it "has higher priority on sort when is required" do
    array = [ Thor::Option.parse(:foo, :optional), Thor::Option.parse(:foo, :required) ]
    array.sort.first.must be_required
  end

  describe "errors" do
    it "raises an error if name is not supplied" do
      lambda {
        option(nil)
      }.must raise_error(ArgumentError, "Option name can't be nil.")
    end

    it "raises an error if a default value is provided when required" do
      lambda {
        option(:task, nil, true, :string, "bla")
      }.must raise_error(ArgumentError, "Option cannot be required and have default values.")
    end

    it "raises an error if type is unknown" do
      lambda {
        option(:task, nil, true, :unknown)
      }.must raise_error(ArgumentError, "Type :unknown is not valid for options.")
    end
  end

  describe "#usage" do

    describe "with default values" do
      it "returns usage for string types" do
        parse(:foo, "bar").usage.must == "[--foo=bar]"
      end

      it "returns usage for numeric types" do
        parse(:foo, 2.0).usage.must == "[--foo=2.0]"
      end

      it "returns usage for array types" do
        parse(:foo, [1,2,3]).usage.must == "[--foo=1 2 3]"
      end

      it "returns usage for hash types" do
        value = parse(:foo, { :a => :b, :c => :d }).usage
        value.must =~ /\[-\-foo=/
        value.must =~ /a:b/
        value.must =~ /c:d/
      end

      it "returns usage for boolean types" do
        parse(:foo, true).usage.must == "[--foo]"
      end

      describe "and default value is empty" do
        it "returns usage for string types" do
          parse(:foo, :string).usage.must == "[--foo=FOO]"
        end

        it "returns usage for numeric types" do
          parse(:foo, :numeric).usage.must == "[--foo=N]"
        end

        it "returns usage for array types" do
          parse(:foo, :array).usage.must == "[--foo=one two three]"
        end

        it "returns usage for hash types" do
          parse(:foo, :hash).usage.must == "[--foo=key:value]"
        end
      end
    end

    describe "without default values" do
      it "returns usage for string types" do
        parse(:foo, :string).usage.must == "[--foo=FOO]"
      end

      it "returns usage for numeric types" do
        parse(:foo, :numeric).usage.must == "[--foo=N]"
      end

      it "returns usage for array types" do
        parse(:foo, :array).usage.must == "[--foo=one two three]"
      end

      it "returns usage for hash types" do
        parse(:foo, :hash).usage.must == "[--foo=key:value]"
      end

      it "returns usage for hash types" do
        parse(:foo, :boolean).usage.must == "[--foo]"
      end
    end

    describe "with required values" do
      it "does not show the usage between brackets" do
        parse(:foo, :required).usage.must == "--foo=FOO"
      end
    end

    describe "with aliases" do
      it "does not show the usage between brackets" do
        parse([:foo, "-f", "-b"], :required).usage.must == "-f, -b, --foo=FOO"
      end
    end

  end
end

describe Thor::Argument do

  def argument(name, type=:string, default=nil)
    @argument ||= Thor::Argument.new(name, nil, default.nil?, type, default)
  end

  it "is an argument" do
    argument(:task).must be_argument
  end

  describe "errors" do
    it "raises an error if name is not supplied" do
      lambda {
        argument(nil)
      }.must raise_error(ArgumentError, "Argument name can't be nil.")
    end

    it "raises an error if type is unknown" do
      lambda {
        argument(:task, :unknown)
      }.must raise_error(ArgumentError, "Type :unknown is not valid for arguments.")
    end
  end

  describe "#usage" do
    it "returns usage for string types" do
      argument(:foo, :string).usage.must == "FOO"
    end

    it "returns usage for numeric types" do
      argument(:foo, :numeric).usage.must == "N"
    end

    it "returns usage for array types" do
      argument(:foo, :array).usage.must == "one two three"
    end

    it "returns usage for hash types" do
      argument(:foo, :hash).usage.must == "key:value"
    end
  end

  it "has higher priority than options on sort" do
    [ Thor::Option.parse(:foo, "bar"), argument(:task) ].sort.first.must be_kind_of(Thor::Argument)
  end
end
