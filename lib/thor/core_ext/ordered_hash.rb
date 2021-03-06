class Thor #:nodoc:
  module CoreExt #:nodoc:

    # This class is based on the Ruby 1.9 ordered hashes.
    #
    # It keeps the semantics and most of the efficiency of normal hashes
    # while also keeping track of the order in which elements were set.
    #
    class OrderedHash #:nodoc:
      include Enumerable

      Node = Struct.new(:key, :value, :next, :prev)

      def initialize
        @hash = {}
      end

      # Called on clone. It gets all the notes from the cloned object, dup them
      # and assign the duped objects siblings.
      #
      def initialize_copy(other)
        @hash = {}

        array = []
        other.each do |key, value|
          array << (@hash[key] = Node.new(key, value))
        end

        array.each_with_index do |node, i|
          node.next = array[i + 1]
          node.prev = array[i - 1] if i > 0
        end

        @first = array.first
        @last  = array.last
      end

      def [](key)
        @hash[key] && @hash[key].value
      end

      def []=(key, value)
        if old = @hash[key]
          node = old.dup
          node.value = value

          @first = node if @first == old
          @last  = node if @last  == old

          old.prev.next = node if old.prev
          old.next.prev = node if old.next
        else
          node = Node.new(key, value)

          if @first.nil?
            @first = @last = node
          else
            node.prev = @last
            @last.next = node
            @last = node
          end
        end

        @hash[key] = node
        value
      end

      def delete(key)
        if node = @hash[key]
          prev_node = node.prev
          next_node = node.next

          next_node.prev = prev_node if next_node
          prev_node.next = next_node if prev_node

          @first = next_node if @first == node
          @last = prev_node  if @last  == node

          value = node.value
        end

        @hash[key] = nil
        value
      end

      def keys
        self.map { |k, v| k }
      end

      def values
        self.map { |k, v| v }
      end

      def each
        return unless @first
        yield [@first.key, @first.value]
        node = @first
        yield [node.key, node.value] while node = node.next
        self
      end

      def group_values_by
        assoc = self.class.new
        each do |_, element|
          key = yield(element)
          assoc[key] ||= []
          assoc[key] << element
        end
        assoc
      end

      def merge(other)
        dup.merge!(other)
      end

      def merge!(other)
        other.each do |key, value|
          self[key] = value
        end
        self
      end

      def empty?
        @hash.empty?
      end

      def to_a
        array = []
        each { |k, v| array << [k, v] }
        array
      end

      def to_s
        to_a.inspect
      end
      alias :inspect :to_s
    end
  end
end
