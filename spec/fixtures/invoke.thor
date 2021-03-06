class A < Thor
  include Thor::Actions

  desc "one", "invoke one"
  def one
    p 1
    invoke :two
    invoke :three
  end

  desc "two", "invoke two"
  def two
    p 2
    invoke :three
  end

  desc "three", "invoke three"
  def three
    p 3
  end

  desc "four", "invoke four"
  def four
    p 4
    invoke "d:five"
  end
end

class B < Thor
  argument :last_name, :type => :string

  desc "one FIRST_NAME", "invoke one"
  def one(first_name)
    puts "#{last_name}, #{first_name}"
  end

  desc "two", "invoke two"
  def two
    options
  end

  desc "three", "invoke three"
  def three
    _dump_config
  end
end

class C < Thor::Group
  include Thor::Actions

  def one
    p 1
  end

  def two
    p 2
  end

  def three
    p 3
  end
end

class D < Thor
  desc "one", "invoke one"
  def one
    p 1
    invoke "a:two"
    invoke "a:three"
    invoke "a:four"
    invoke "d:five"
  end

  desc "five", "invoke five"
  def five
    p 5
  end
end

class E < Thor::Group
  include Thor::Actions

  def one
    p 1
    invoke :two
    invoke :three
  end

  def two
    p 2
    invoke :three
  end

  def three
    p 3
  end
end
