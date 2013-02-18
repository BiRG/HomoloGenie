module HomoloGenie
	class Homolog

		public

		attr_reader :id
		attr_reader :taxonomies

		def initialize(id)
			@id = id
			@taxonomies = Hash.new()
		end

	end
end
