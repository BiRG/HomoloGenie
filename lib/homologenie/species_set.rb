#!/usr/bin/ruby

require 'set'
require 'lib/homologenie/homolog'

module HomoloGenie
    class SpeciesSet
        attr_reader :species
        attr_reader :millions_of_years
        attr_reader :homologs

        # def initialize(species_a, species_b)
        #     @species = Set.new [species_a, species_b]
        #     @millions_of_years = 0
        #     @homologs = Hash.new
        # end #def

        #provide taxid's of species to include. Can be later converted to hash to
        #contain (taxid,name of species) as (key,value)
        def initialize(*species)
            @species = Set.new species
            @millions_of_years = 0
            #to later add protein homologs with (taxid, Protein) as
            #(key, value)
            @homologs = Hash.new
        end #def

        #TODO :implement deep clone using initialize_clone in homolog
            #and protein classes
        def add_homolog(new_homolog)
            @homologs[new_homolog.id] = new_homolog

            #TODO :implement for multiple alignments
            if @homologs.size == 2
                # HomoloGenie::Cost::calc_cost(@homologs[new_homolog.id])
                puts "Calculating cost for: "
                p @species
                puts "At homolog " + new_homolog.id.to_s + "\n\n"
            end #if
        end #def


    end #class
end #module