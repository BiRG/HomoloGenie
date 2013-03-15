#!/usr/bin/ruby

#enables using path to classes without installed in path
$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), '.' ) )

require 'set'
require 'psych'
require 'lib/homologenie/homolog'
require 'lib/homologenie/protein'
require 'lib/homologenie/taxonomy'
require 'lib/homologenie/results'
require 'lib/homologenie/species_set'
#require 'lib/homologenie/species_gene'

if __FILE__ == $0

    tax_ids_to_use = [  7955,   #Danio rerio
                    9606,   #Homo sapiens
                    9598,   #Pan troglodytes
                    # 9544,   #Macaca mulatta
                    # 9615,   #Canis lupus familiaris
                    # 9913,   #Bos taurus
                    # 10090,  #Mus musculus
                    # 10116,  #Rattus norvegicus
                    9031]   #Gallus gallus

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
                # outer_taxonomy_obj = prep_tax(homologene_id, outer_tax)

                outer_protein_obj = raw_homologs[homologene_id].taxonomies[outer_tax].proteins[raw_homologs[homologene_id].taxonomies[outer_tax].proteins.keys[0]]
                # puts "Outer: " + tax_ids_to_use[i].to_s
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

                            # if homologene_id == 9776 && inner_tax == 9606
                            #     p raw_homologs[homologene_id].taxonomies[inner_tax].proteins
                            #     next
                            # end
                            #p raw_homologs[homologene_id].taxonomies[inner_tax].proteins[raw_homologs[homologene_id].taxonomies[inner_tax].proteins.keys[0]]
                            inner_protein_obj = raw_homologs[homologene_id].taxonomies[inner_tax].proteins[raw_homologs[homologene_id].taxonomies[inner_tax].proteins.keys[0]]
                            # puts "Inner:" + inner_tax.to_s
                            # p inner_protein_obj
                            inner_taxonomy_obj = HomoloGenie::Taxonomy.new(raw_homologs[homologene_id].taxonomies[inner_tax].id,
                                                            raw_homologs[homologene_id].taxonomies[inner_tax].name)
                            inner_taxonomy_obj.proteins[inner_protein_obj.accession] = inner_protein_obj

                            #add species to homolog object
                            temp_homolog = HomoloGenie::Homolog.new(homologene_id)
                            temp_homolog.taxonomies[outer_taxonomy_obj.id] = outer_taxonomy_obj
                            temp_homolog.taxonomies[inner_taxonomy_obj.id] = inner_taxonomy_obj

                            temp_species_set = HomoloGenie::SpeciesSet.new(tax_set)
                            # temp_species_set.add_homolog(outer_taxonomy_obj)
                            # temp_species_set.add_homolog(inner_taxonomy_obj)

                            temp_species_set.homologs[homologene_id] = temp_homolog

                            #will either create results[tax_set] or mod existing
                            if results.has_key?(tax_set)
                                results[tax_set].push(temp_species_set)
                            else
                                results[tax_set] = [temp_species_set]
                            end #if
                        end #if
                    else
                        puts "Duplicate keys at homologene id " + homologene_id.to_s()
                    end #if
                end #do

            end #if
        end #do
    end #do

    puts "Results:"
    # p results
    # p results.keys

    if true
    # if nil
        results.each do |key, value|
            p key
            puts "Homologs:"
            value.each do |homolog|
                p homolog.homologs.keys
                puts "\tSet"
                homolog.homologs.each do |homologene_id, set_val|
                    set_val.taxonomies.each do |tax_key, tax_val|
                        puts "\t\t" + tax_val.proteins[tax_val.proteins.keys[0]].accession.to_s
                    end #do
                end #do
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