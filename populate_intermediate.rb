#!/usr/bin/ruby

#enables using path to classes without installed in path
$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), '.' ) )

require 'set'
require 'psych'
require 'gchart'
require 'lib/homologenie/homolog'
require 'lib/homologenie/protein'
require 'lib/homologenie/taxonomy'
require 'lib/homologenie/results'
require 'lib/homologenie/species_set'
require 'lib/homologenie/cost/cost'
#require 'lib/homologenie/species_gene'

if __FILE__ == $0

    file_prepend = "test_"



    tax_ids_to_use = [  #7955,   #Danio rerio
                    9606,   #Homo sapiens
                    #9598,   #Pan troglodytes
                    # 9544,   #Macaca mulatta
                    # 9615,   #Canis lupus familiaris
                    # 9913,   #Bos taurus
                    # 10090,  #Mus musculus
                    # 10116,  #Rattus norvegicus
                    9031]   #Gallus gallus

    name_lookup = {  7955 => "Danio rerio",
                    9606 => "Homo sapiens",
                    9598 => "Pan troglodytes",
                    9544 => "Macaca mulatta",
                    9615 => "Canis lupus familiaris",
                    9913 => "Bos taurus",
                    10090 => "Mus musculus",
                    10116 => "#Rattus norvegicus",
                    9031 => "Gallus gallus"}

    results = Hash.new()

    # homologs_in = File.new( 'data/small_database.yaml', 'r')
    homologs_in = File.new( 'data/small_database.data', 'r')

    raw_homologs = Psych.load_file( homologs_in )

    #puts raw_homologs[9776].taxonomies[7955].proteins

    # puts raw_homologs

    raw_homologs.each do |homologene_id, taxonomies|
        inner_array = tax_ids_to_use.dup()

        # itereates until last tax id in list since 2 are needed for a set
        # TODO: replace with recursive function so >2 pair sets can be used
        (0..( tax_ids_to_use.length() - 2 ) ).each do |i|
            #grab remaining tax ids from list
            inner_array = tax_ids_to_use.values_at((i + 1)..( tax_ids_to_use.length - 1))
            outer_tax = tax_ids_to_use[i]

            if raw_homologs[homologene_id].taxonomies.has_key?(outer_tax)

                #avoids duplicating data reads for outer tax

                outer_protein_obj = raw_homologs[homologene_id].taxonomies[outer_tax].proteins[raw_homologs[homologene_id].taxonomies[outer_tax].proteins.keys[0]]
                #TODO add functionality to class so .calc_cost automatically performed
                outer_protein_obj.set_cost( HomoloGenie::Cost.calc_cost(outer_protein_obj.sequence) )

                if outer_protein_obj.cost == nil
                    next
                else
                    # p outer_protein_obj

                    outer_taxonomy_obj = HomoloGenie::Taxonomy.new(raw_homologs[homologene_id].taxonomies[outer_tax].id,
                                                    raw_homologs[homologene_id].taxonomies[outer_tax].name)
                    outer_taxonomy_obj.proteins[outer_protein_obj.accession()] = outer_protein_obj

                    inner_array.each do |inner_tax|
                        if outer_tax != inner_tax #avoid duplicate taxes
                            if raw_homologs[homologene_id].taxonomies.has_key?(inner_tax)
                                #has both keys
                                tax_set = Set.new [outer_tax, inner_tax]
                                # inner_taxonomy_obj = prep_tax(homologene_id, inner_tax)


                                #p raw_homologs[homologene_id].taxonomies[inner_tax].proteins[raw_homologs[homologene_id].taxonomies[inner_tax].proteins.keys[0]]
                                inner_protein_obj = raw_homologs[homologene_id].taxonomies[inner_tax].proteins[raw_homologs[homologene_id].taxonomies[inner_tax].proteins.keys[0]]

                                #TODO add functionality to class so .calc_cost automatically performed
                                inner_protein_obj.set_cost( HomoloGenie::Cost.calc_cost(inner_protein_obj.sequence) )

                                if inner_protein_obj.cost == nil
                                    next
                                else
                                    # puts "Inner:" + inner_tax.to_s
                                    # p inner_protein_obj
                                    inner_taxonomy_obj = HomoloGenie::Taxonomy.new(raw_homologs[homologene_id].taxonomies[inner_tax].id,
                                                                    raw_homologs[homologene_id].taxonomies[inner_tax].name)
                                    inner_taxonomy_obj.proteins[inner_protein_obj.accession] = inner_protein_obj

                                    #add species to homolog object
                                    temp_homolog = HomoloGenie::Homolog.new(homologene_id)
                                    temp_homolog.taxonomies[outer_taxonomy_obj.id] = outer_taxonomy_obj
                                    temp_homolog.taxonomies[inner_taxonomy_obj.id] = inner_taxonomy_obj

                                    temp_homolog.set_match

                                    temp_species_set = HomoloGenie::SpeciesSet.new(tax_set)

                                    temp_species_set.homologs[homologene_id] = temp_homolog

                                    #will either create results[tax_set] or mod existing
                                    if results.has_key?(tax_set)
                                        results[tax_set].push(temp_species_set)
                                    else
                                        results[tax_set] = [temp_species_set]
                                    end #if
                                end #if
                            end #if
                        else
                            puts "Duplicate keys at homologene id " + homologene_id.to_s()
                        end #if
                    end #do
                end #if

            end #if
        end #do
    end #do

    puts "Results:"
    # p results
    # p results.keys

    if true
    # if nil
        results.each do |key, value|
            set_graphs = Hash.new

            species_names = String.new
            puts species_names.length.to_s

            key.each do |taxii|
                set_graphs[taxii] = { "cost" => Array.new, "match" => Array.new }

                puts species_names.length.to_s
                if species_names.length == 0
                    species_names = name_lookup[taxii]
                else
                    species_names += " vs " + name_lookup[taxii]
                end #if
            end #do
            p key
            puts "Homologs:"
            value.each do |homolog|
                p homolog.homologs.keys
                puts "\tSet"

                homolog.homologs.each do |homologene_id, set_val|

                    set_val.taxonomies.each do |tax_key, tax_val|
                        set_graphs[tax_key]["cost"].push((tax_val.proteins[tax_val.proteins.keys[0]].cost / tax_val.proteins[tax_val.proteins.keys[0]].sequence.length).round(2))
                        set_graphs[tax_key]["match"].push(set_val.match.round(4))
                        puts "\t\t" + tax_val.proteins[tax_val.proteins.keys[0]].accession.to_s
                        puts "\t\t\tAvg cost:" + ( tax_val.proteins[tax_val.proteins.keys[0]].cost / tax_val.proteins[tax_val.proteins.keys[0]].sequence.length ).to_s
                    end #do

                    puts "\t\tMatch: " + set_val.match.to_s
                end #do
            end #do
            key.each do |taxii|
                species_names
                Gchart.scatter(:data => [set_graphs[taxii]["match"], set_graphs[taxii]["cost"]],
                            :format => 'file',
                            :filename => ( file_prepend + species_names + ".png").sub(' ','_'),
                            :title => species_names,
                            :axis_with_labels => ['x','y'],
                            :axis_labels => [[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],[0,10,20,30,40,50,60,70,80]],
                            :set_axis_range => [[0.0,0.9], [0,80]],
                            #:max_value => 80,
                            :size => '600x400',
                            :encoding => 'text')
                puts set_graphs[taxii]["match"].to_s

            end #do
        end #do
    end #if

    homologs_in.close()

    # def prep_tax(temp_homologene_id, temp_tax_id)
    #     protein_temp = raw_homologs[temp_homologene_id].taxonomies[temp_tax_id].proteins[0].clone()
    #     taxonomy_temp = Taxonomy.new(raw_homologs[temp_homologene_id].taxonomies[temp_tax_id].id.clone(),
    #                                     raw_homologs[temp_homologene_id].taxonomies[temp_tax_id].name.clone())
    #     taxonomy_temp.proteins[protein_temp.accession] = protein_temp

    #     return taxonomy_temp
    # end #def

end #if