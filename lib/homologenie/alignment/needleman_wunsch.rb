require 'homologenie/structure/multidimensional_array'

include HomoloGenie::Structure

module HomoloGenie
  module Alignment
    class NeedlemanWunsch

      public

      attr_reader :alignments
      attr_reader :score
      attr_reader :table

      ReferencePath = Struct.new(:score, :index)

      def initialize()
      end

      def align(*sequences, &calculator)
        @sequences = sequences.map {|sequence| sequence.clone}
        construct_table(sequences)
        generate_component_combinations()
        calculate_score(calculator)
        construct_alignments()
      end

      private

      AlignmentState = Struct.new(:score, :paths)

      def calculate_state(index, calculator)
        intermediate = Hash.new
        references = generate_references(index)
        references.each do |reference|
          path = nil
          if !reference.include?(-1)
            path = ReferencePath.new
            path.score = @table[*reference].score
            path.index = reference.map {|c| c - 1}
          end
          adjusted_index = index.map {|c| c - 1}
          result = calculator.call(adjusted_index, path)
          intermediate[result] ||= Array.new
          if !reference.include?(-1)
            intermediate[result] << reference
          end
        end
        maximum = intermediate.keys.max
        state = AlignmentState.new
        state.score = maximum
        state.paths = intermediate[maximum]
        return state
      end

      def calculate_score(calculator)
        @table.each_index do |index|
          @table[*index] = calculate_state(index, calculator)
        end
        final = @table.shape.map {|length| length - 1}
        @score = @table[*final].score
      end

      def construct_alignments()
        @alignments = Array.new
        @alignments << Array.new(@table.dimensions, String.new)
        # @alignments << Array.new(@table.dimensions)
        # @alignments[0].each_index do |i|
        #   @alignments[0][i] = Array.new
        # end

        initial_index = Array.new(@table.dimensions, 0)
        unit = Array.new(@table.dimensions, 0)
        gap = "-"

        stack = Array.new

        index = @table.shape.map {|length| length - 1}
        depth = 0
        align = 0

        stack.push([index, depth, align, true])

        while !stack.empty?
          reference = stack.pop
          index = reference[0]
          depth = reference[1]
          align = reference[2]
          needs = reference[3]

          if needs
            @table[*index].paths.each_with_index do |path, i|
              final_path = @table[*index].paths.length - 1
              temp = align
              if i < final_path
                temp = @alignments[align].map {|s| s.clone}
                @alignments << temp
                next_align = @alignments.length - 1
                stack.push([path, depth + 1, next_align, true])
                stack.push([index, depth, next_align, false])
              else
                stack.push([path, depth + 1, align, true])
              end
            end
          end

          next if index == initial_index
          next if stack.empty?

          path = stack[-1][0]

          unit.each_index {|i| unit[i] = (index[i] - path[i]) == 1}
          unit.each_with_index do |aligned, dimension|
            if aligned
              element = @sequences[dimension][index[dimension] - 1]
              @alignments[align][dimension] += element
            else
              @alignments[align][dimension] += gap
            end
          end
        end

        @alignments.each do |alignment|
          alignment.map! {|sequence| sequence.reverse}
        end
      end      

      def construct_table(sequences)
        shape = Array.new(sequences.length)
        sequences.each_with_index do |sequence, dimension|
          shape[dimension] = sequence.length + 1
        end
        @table = MultidimensionalArray.new(*shape)
      end

      def generate_component_combinations()
        components = Array.new(@table.dimensions)
        components.each_index {|i| components[i] = i}
        combinations = Array.new
        initial_size = 1
        initial_size.upto(components.length) do |size|
          combinations += components.combination(size).to_a
        end
        @combinations = combinations
      end

      def generate_references(index)
        references = Array.new
        @combinations.each do |dimensions|
          reference = index.clone
          dimensions.each {|dimension| reference[dimension] -= 1}
          references << reference
        end
        return references
      end

    end
  end
end
