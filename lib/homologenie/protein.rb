module HomoloGenie
	class Protein

		public

		def initialize(accession, sequence)
			@accession = accession
			@sequence = sequence
		end

		def accession()
			return @accession.clone()
		end

		def sequence()
			return @sequence.clone()
		end

	end
end