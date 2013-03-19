module HomoloGenie
	class Homolog

		public

		attr_reader :id
		attr_reader :taxonomies
        attr_reader :match

		def initialize(id)
			@id = id
			@taxonomies = Hash.new()
            @match = 0.0
		end

        def set_match
            @match = Random.rand
        end #def

	end
end
