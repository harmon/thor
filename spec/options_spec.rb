require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/options'

describe Thor::Options do
  def create(opts)
    opts.each do |key, value|
      opts[key] = Thor::Option.parse(key, value) unless value.is_a?(Thor::Option)
    end

    @opt = Thor::Options.new(opts)
  end

  def parse(*args)
    @opt.parse(args.flatten)
  end

  def usage
    @opt.formatted_usage
  end

  def sorted_usage
    usage.split(" ").sort.join(" ")
  end

  describe "#to_switches" do
    it "turns true values into a flag" do
      Thor::Options.to_switches(:color => true).must == "--color"
    end

    it "ignores nil" do
      Thor::Options.to_switches(:color => nil).must == ""
    end

    it "ignores false" do
      Thor::Options.to_switches(:color => false).must == ""
    end

    it "writes --name value for anything else" do
      Thor::Options.to_switches(:format => "specdoc").must == '--format "specdoc"'
    end

    it "joins several values" do
      switches = Thor::Options.to_switches(:color => true, :foo => "bar").split(' ').sort
      switches.must == ['"bar"', "--color", "--foo"]
    end

    it "works with arrays" do
      Thor::Options.to_switches(:count => [1,2,3]).must == "--count 1 2 3"
    end

    it "works with hashes" do
      Thor::Options.to_switches(:count => {:a => :b}).must == "--count a:b"
    end
  end

  describe "#initialize" do
    it "automatically aliases long switches with their first letter" do
      create "--foo" => true
      parse("-f")["foo"].must be_true
    end

    it "doesn't auto-alias switches that have multiple names given" do
      create ["--foo", "--bar"] => :boolean
      parse("-f")["foo"].must_not be
    end

    it "allows multiple aliases for a given switch" do
      create ["--foo", "--bar", "--baz"] => :optional
      parse("--foo", "12")["foo"].must == "12"
      parse("--bar", "12")["foo"].must == "12"
      parse("--baz", "12")["foo"].must == "12"
    end

    it "allows custom short names" do
      create "-f" => :optional
      parse("-f", "12").must == {"f" => "12"}
    end

    it "allows custom short-name aliases" do
      create ["--bar", "-f"] => :optional
      parse("-f", "12").must == {"bar" => "12"}
    end

    it "doesn't recognize long switch format for a switch that is originally short" do
      create 'f' => :optional
      parse("-f", "1").must == {"f" => "1"}

      create 'f' => :optional
      parse("--f", "1").must == {}
    end
  end

  describe "#parse" do
    it "accepts conjoined short switches" do
      create "--foo" => true, "--bar" => true, "--app" => true
      opts = parse("-fba")
      opts["foo"].must be_true
      opts["bar"].must be_true
      opts["app"].must be_true
    end

    it "accepts conjoined short switches with input" do
      create "--foo" => true, "--bar" => true, "--app" => :required
      opts = parse "-fba", "12"
      opts["foo"].must be_true
      opts["bar"].must be_true
      opts["app"].must == "12"
    end

    it "extracts trailing inputs" do
      create "--foo" => :required, "--bar" => true
      args = [ "foo", "bar", "--baz", "--foo", "12", "--bar", "-T", "bang" ]

      parse(*args).must == { "foo" => "12", "bar" => true }
      @opt.trailing.must == ["foo", "bar", "--baz", "-T", "bang"]
    end

    describe "with no input" do
      it "and no switches returns an empty hash" do
        create({})
        parse.must == {}
      end

      it "and several switches returns an empty hash" do
        create "--foo" => :boolean, "--bar" => :optional
        parse.must == {}
      end

      it "and a required switch raises an error" do
        create "--foo" => :required
        lambda { parse }.must raise_error(Thor::RequiredArgumentMissingError, "no value provided for required arguments '--foo'")
      end
    end

    describe "with one required and one optional switch" do
      before :each do
        create "--foo" => :required, "--bar" => :optional
      end

      it "raises an error if the required switch has no argument" do
        lambda { parse("--foo") }.must raise_error(Thor::RequiredArgumentMissingError)
      end

      it "raises an error if the required switch isn't given" do
        lambda { parse("--bar") }.must raise_error(Thor::RequiredArgumentMissingError)
      end

      it "raises an error if a switch name is given as the argument to the required switch" do
        lambda { parse("--foo", "--bar") }.must raise_error(Thor::MalformattedArgumentError, "cannot pass switch '--bar' as an argument")
      end
    end

    describe "with default values" do
      before(:each) do
        create "--branch" => "master", "--force" => false
      end

      it "must get the specified value" do
        parse("--branch", "bugfix", "--force").must == { "branch" => "bugfix", "force" => true }
      end

      it "must get the default value when not specified" do
        parse.must == { "branch" => "master", "force" => false }
      end
    end

    describe "with arguments" do
      before(:each) do
        @ordered_hash = Thor::CoreExt::OrderedHash.new
        @ordered_hash[:interval] = Thor::Argument.new(:interval, nil, true, :numeric, nil)
        @ordered_hash[:unit]     = Thor::Option.new(:unit, nil, false, :string, "days", [])
      end

      it "parses leading arguments and assign them" do
        ordered_hash = Thor::CoreExt::OrderedHash.new
        ordered_hash[:class_name] = Thor::Argument.new(:class_name, nil, true, :string, nil)
        ordered_hash[:attributes] = Thor::Argument.new(:attributes, nil, true, :hash, nil)

        create ordered_hash
        parse("User", "name:string", "age:integer")

        @opt.arguments.must == [ "User", { "name"=>"string", "age"=>"integer" } ]
      end

      it "parses leading arguments and just then parse optionals" do
        create @ordered_hash
        parse("3.0", "--unit", "months")

        @opt.arguments.must == [ 3.0 ]
        @opt.options.must == {"unit" => "months"}
      end

      it "does not assign leading arguments to optionals" do
        create @ordered_hash
        parse("3.0", "months")

        @opt.arguments.must == [ 3.0 ]
        @opt.options.must == {"unit" => "days"}
      end

      it "assigns switches to arguments" do
        create @ordered_hash
        parse("--unit", "months", "--interval", "3.0")

        @opt.arguments.must == [ 3.0 ]
        @opt.options.must == {"unit" => "months"}
      end

      it "ignores switches that match arguments" do
        create @ordered_hash
        parse("1.0", "--unit", "months", "--interval", "3.0")

        @opt.arguments.must == [ 1.0 ]
        @opt.options.must == {"unit" => "months"}
      end

      it "raises an error if required arguments are not provided" do
        create @ordered_hash
        lambda { parse("--unit", "months") }.must raise_error(Thor::RequiredArgumentMissingError,
          "no value provided for required arguments 'interval'")
      end
    end
  end

  describe "on general" do

    describe "with :string type" do
      before(:each) do
        create "--foo" => :required
      end

      it "accepts a switch=<value> assignment" do
        parse("-f=12")["foo"].must == "12"
        parse("--foo=12")["foo"].must == "12"
        parse("--foo=bar=baz")["foo"].must == "bar=baz"
      end

      it "accepts a switch <value> assignment" do
        parse("--foo", "12")["foo"].must == "12"
      end
    end

    describe "with :boolean type" do
      before(:each) do
        create "--foo" => false
      end

      it "accepts --opt assignment" do
        parse("--foo")["foo"].must == true
      end

      it "doesn't set nonexistant switches" do
        parse("--foo")["bar"].must_not be
      end

      it "accepts --[no-]opt variant, setting false for value" do
        parse("--no-foo")["foo"].must == false
      end

      it "will prefer 'no-opt' variant over inverting 'opt' if explicitly set" do
        create "--no-foo" => true
        parse("--no-foo")["no-foo"].must == true
      end
    end

    describe "with :hash type" do
      before(:each) do
        create "--attributes" => :hash
      end

      it "accepts a switch=<value> assignment" do
        parse("--attributes=name:string", "age:integer")["attributes"].must == {"name" => "string", "age" => "integer"}
      end

      it "accepts a switch <value> assignment" do
        parse("--attributes", "name:string", "age:integer")["attributes"].must == {"name" => "string", "age" => "integer"}
      end

      it "must not mix values with other switches" do
        parse("--attributes", "name:string", "age:integer", "--baz", "cool")["attributes"].must == {"name" => "string", "age" => "integer"}
      end
    end

    describe "with :array type" do
      before(:each) do
        create "--attributes" => :array
      end

      it "accepts a switch=<value> assignment" do
        parse("--attributes=a", "b", "c")["attributes"].must == ["a", "b", "c"]
      end

      it "accepts a switch <value> assignment" do
        parse("--attributes", "a", "b", "c")["attributes"].must == ["a", "b", "c"]
      end

      it "must not mix values with other switches" do
        parse("--attributes", "a", "b", "c", "--baz", "cool")["attributes"].must == ["a", "b", "c"]
      end
    end

    describe "with :default type" do
      before :each do
        create "--foo" => :optional, "--bar" => :optional
      end

      it "sets switches without arguments to true" do
        parse("--foo")["foo"].must be_true
      end

      it "doesn't set nonexistant switches" do
        parse("--foo")["bar"].must_not be
      end

      it "sets switches with arguments to their arguments" do
        parse("--foo", "12")["foo"].must == "12"
        parse("--bar", "12")["bar"].must == "12"
      end

      it "assumes something that could be either a switch or an argument is a switch" do
        parse("--foo", "--bar")["foo"].must be_true
      end

      it "overwrites earlier values with later values" do
        parse("--foo", "--foo", "12")["foo"].must == "12"
        parse("--foo", "12", "--foo", "13")["foo"].must == "13"
      end
    end

    describe "with :numeric type" do
      before(:each) do
        create "n" => :numeric, "m" => 5
      end

      it "accepts a -nXY assignment" do
        parse("-n12")["n"].must == 12
      end

      it "supports numeric defaults" do
        parse["m"].must == 5
      end

      it "converts values to numeric types" do
        parse("-n", "3", "-m", ".5").must == {"n" => 3, "m" => 0.5}
      end

      it "raises error when value isn't numeric" do
        lambda { parse("-n", "foo") }.must raise_error(Thor::MalformattedArgumentError,
          "expected numeric value for '-n'; got \"foo\"")
      end

      it "raises error when switch is present without value" do
        lambda { parse("-n") }.must raise_error(Thor::RequiredArgumentMissingError,
          "no value provided for required argument '-n'")
      end
    end

  end
end
