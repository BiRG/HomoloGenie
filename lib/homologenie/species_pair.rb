#!/usr/bin/ruby

require 'json'
require 'lib/homologenie/species_gene'

module HomoloGenie
    class SpeciesPair
        # TODO initialize MUST be SpeciesGene object???

        #parameters must be SpeciesGene object????

        attr_reader :score
        #attr_reader :pair

        def initialize(species_a, species_b, score = 0)
            @pair = [species_a, species_b]
            @score = score
        end #def


        def set_score(new_score)
            @score = new_score
        end #def


        #if species pair already exists
        def exists?(species_a, species_b)
            if ( @pair[0] == species_a && @pair[1] == species_b ) || \
                ( @pair[0] == species_b && @pair[1] == species_a )
                return 1
            end #if

            return nil
        end #def


        #if test_score is a better score
        def higher_score?(test_score)
            if test_score > @score
                return 1
            end #if

            return nil
        end #def


        def to_json(*obj)
            {
                "json_class" => self.class.name,
                "data" => {"pair" => @pair,
                            "score" => @score }
            }.to_json(*obj)
        end


        def self.json_create(obj)
            new(obj["data"]["pair"],
                obj["data"]["score"])
        end

    end #class
end #module
