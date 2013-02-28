module HomoloGenie
  module Structure
    class MultidimensionalArray

      include Enumerable

      public

      attr_reader :dimensions
      attr_reader :shape

      def initialize(*shape)
        validate_shape(shape)
        @shape = shape.clone()
        @dimensions = shape.length
        @array = build()
      end

      def [](*index)
        validate_index(index)
        internal = convert_to_internal_index(index)
        return @array[internal]
      end

      def []=(*index, value)
        validate_index(index)
        internal = convert_to_internal_index(index)
        @array[internal] = value
      end

      def each()
        return to_enum() unless block_given?
        @array.each do |element|
          yield element
        end
      end

      def each_index()
        return to_enum(:each_index) unless block_given?
        initial_index = 0
        final_index = @array.length - 1
        initial_index.upto(final_index) do |index|
          eulerian = convert_to_eulerian_index(index)
          yield eulerian
        end
      end

      def each_with_index()
        return to_enum(:each_with_index) unless block_given?
        @array.each.with_index do |element, index|
          eulerian = convert_to_eulerian_index(index)
          yield element, eulerian
        end
      end

      private

      def build()
        size = 1
        @shape.each do |length|
          size *= length
        end
        return Array.new(size)
      end

      def calculate_internal_offset_factor(dimension)
        initial = dimension + 1
        final = @dimensions - 1
        factor = 1
        initial.upto(final).each do |dimension|
          factor *= @shape[dimension]
        end
        return factor
      end

      def convert_to_eulerian_index(index)
        eulerian = Array.new(@dimensions)
        initial = @dimensions - 1
        final = 0
        initial.downto(final).each do |dimension|
          factor = calculate_internal_offset_factor(dimension)
          previous = dimension + 1
          eulerian[dimension] = index
          eulerian[previous..initial].each do |component|
            eulerian[dimension] -= component
          end
          eulerian[dimension] /= factor
          eulerian[dimension] %= @shape[dimension]
        end
        return eulerian
      end

      def convert_to_internal_index(index)
        internal = 0
        index.each.with_index do |component, dimension|
          factor = calculate_internal_offset_factor(dimension)
          internal += component * factor
        end
        return internal
      end

      def validate_dimension(dimension, size)
        unless size.is_a?(Integer)
          message = "shape: not an Integer"
          details = "(for dimension #{dimension})"
          raise ArgumentError, [message, details].join(" ")
        end
        unless size > 0
          message = "shape: out of range"
          details = "(for dimension #{dimension})"
          raise ArgumentError, [message, details].join(" ")
        end
      end

      def validate_component(component, dimension)
        unless component.is_a?(Integer)
          message = "index: not an Integer"
          details = "(for dimension #{dimension})"
          raise ArgumentError, [message, details].join(" ")
        end
        unless component >= 0 && component < @shape[dimension]
          message = "index: out of range"
          details = "(for dimension #{dimension})"
          raise ArgumentError, [message, details].join(" ")
        end
      end

      def validate_index(index)
        unless index.length == @dimensions
          message = "index: wrong number of dimensions"
          details = "(#{index.length} for #{@dimensions})"
          raise ArgumentError, [message, details].join(" ")
        end
        index.each.with_index do |component, dimension|
          validate_component(component, dimension)
        end
      end

      def validate_shape(shape)
        unless shape.length > 0
          message = "shape: missing dimensions"
          raise ArgumentError, message
        end
        shape.each.with_index do |size, dimension|
          validate_dimension(dimension, size)
        end
      end

    end
  end
end
