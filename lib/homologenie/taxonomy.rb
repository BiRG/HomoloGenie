module HomoloGenie
	class Taxonomy

		public

		attr_reader :id
		attr_reader :name
		attr_reader :proteins

		def initialize(id, name)
			@id = id
			@name = name
			@proteins = Hash.new()
		end

	end
end