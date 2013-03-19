module HomoloGenie
    class Protein

        #added reader 2013-03-05 Nathan
        attr_reader :cost

        public

        #added cost argument 2013-03-05 Nathan
        def initialize(accession, sequence, cost = nil)
            @accession = accession
            @sequence = sequence
            @cost = cost
        end

        def accession()
            return @accession.clone()
        end

        def sequence()
            return @sequence.clone()
        end

        #added 2013-03-05 Nathan
        def set_cost(cost)
            @cost = cost
            return cost
        end #def

    end
end