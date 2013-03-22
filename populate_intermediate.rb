#!/usr/bin/ruby

#enables using path to classes without installed in path
$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), '.' ) )

require 'set'
require 'psych'
# require 'gchart'
require 'uri'
require 'net/http'
require 'lib/homologenie/homolog'
require 'lib/homologenie/protein'
require 'lib/homologenie/taxonomy'
require 'lib/homologenie/results'
require 'lib/homologenie/species_set'
require 'lib/homologenie/cost/cost'
#require 'lib/homologenie/species_gene'

if __FILE__ == $0

    file_prepend = "test_"
    CHART_URI = "http://chart.googleapis.com/chart?"

    post_uri = URI.parse("http://chart.googleapis.com/chart")
    graph_options = {'cht' => 's',          #chart type = scatter
                    'chs' => '650x450',     #chart size
                    'chd' => '',            #chart data will be filled later
                    'chds' => "0,1.0,0,80",  #x,y data range
                    'chtt' => '',           #chart title will be filled later
                    'chxt' => "x,x,y,y",        #chart axes visible
                    'chxl' => '0:|0.0|0.2|0.4|0.6|0.8|1.0|1:|||Match|||2:|0|10|20|30|40|50|60|70|80|3:|||Cost||',
                    'chxs' => '1,333333,14|3,333333,14'
                    # 'chxr' => '0,0,1,.2|2,0,80,10'
                }


    tax_ids_to_use = [  7955,   #Danio rerio
                    # 9606,   #Homo sapiens
                    # 9598,   #Pan troglodytes
                    # 9544,   #Macaca mulatta
                    # 9615,   #Canis lupus familiaris
                    # 9913,   #Bos taurus
                    # 10090,  #Mus musculus
                    # 10116,  #Rattus norvegicus
                    9031]   #Gallus gallus

    # tax_ids_to_use = [  7955,   #Danio rerio
    #                 9606,   #Homo sapiens
    # #                 9598,   #Pan troglodytes
    # #                 9544,   #Macaca mulatta
    # #                 9615,   #Canis lupus familiaris
    # #                 9913,   #Bos taurus
    # #                 10090,  #Mus musculus
    # #                 10116,  #Rattus norvegicus
    #                 # 9031    #Gallus gallus
    #                 ]

    name_lookup = {  7955 => "Danio rerio",
                    9606 => "Homo sapiens",
                    9598 => "Pan troglodytes",
                    9544 => "Macaca mulatta",
                    9615 => "Canis lupus familiaris",
                    9913 => "Bos taurus",
                    10090 => "Mus musculus",
                    10116 => "Rattus norvegicus",
                    9031 => "Gallus gallus"}

    results = Hash.new()

    # homologs_in = File.new( 'data/small_database.yaml', 'r')
    homologs_in = File.new( 'data/homologene_database.data', 'r')

    raw_homologs = Psych.load_file( homologs_in )

    homolog_count = 0

    #puts raw_homologs[9776].taxonomies[7955].proteins

    # puts raw_homologs

    puts ""

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
        homolog_count += 1
        print "\rHomologs processed: " + ( homolog_count / raw_homologs.size ).round(0).to_s + "%"
    end #do

#    puts "Results:"
    # p results
    # p results.keys

    if true
    # if nil
        results.each do |key, value|
            set_graphs = Hash.new

            species_names = String.new
#            puts species_names.length.to_s

            key.each do |taxii|
                #set_graphs[taxii] = { "cost" => Array.new, "match" => Array.new }

                #Binning
                set_graphs[taxii] = Hash.new

#                puts species_names.length.to_s
                if species_names.length == 0
                    species_names = name_lookup[taxii]
                else
                    species_names += " vs " + name_lookup[taxii]
                end #if
            end #do
#            p key
#            puts "Homologs:"
            value.each do |homolog|
#                p homolog.homologs.keys
#                puts "\tSet"

                homolog.homologs.each do |homologene_id, set_val|

                    set_val.taxonomies.each do |tax_key, tax_val|
                        #Binning - match score rounded to nearest .01
                        #Average cost rounded to nearest whole number,
                        # -length used does not include initial M

                        #ignore
                        set_graphs[tax_key][set_val.match.round(2)] = (tax_val.proteins[tax_val.proteins.keys[0]].cost / ( tax_val.proteins[tax_val.proteins.keys[0]].sequence.length - 1 ) ).round(0)
                        #set_graphs[tax_key]["match"].push(set_val.match.round(4))



#                        puts "\t\t" + tax_val.proteins[tax_val.proteins.keys[0]].accession.to_s
#                        puts "\t\t\tAvg cost:" + ( tax_val.proteins[tax_val.proteins.keys[0]].cost / tax_val.proteins[tax_val.proteins.keys[0]].sequence.length ).to_s
                    end #do

#                    puts "\t\tMatch: " + set_val.match.to_s
                end #do
            end #do
            key.each do |taxii|

                chd = 't:'
                # set_graphs[taxii]["match"].each do |data|
                #     chd += data.to_s + ','
                # end #do
                # chd = chd.chop + '|'

                # set_graphs[taxii]["cost"].each do |data|
                #     chd += data.to_s + ','
                # end #do
                # chd.chop!

                #binning

                chd_match = String.new
                chd_cost = String.new

                set_graphs[taxii].each do |match_binned,cost_binned|
                    chd_match += match_binned.to_s + ','
                    chd_cost += cost_binned.to_s + ','
                end #do

                chd += chd_match.chop! + '|' + chd_cost.chop!

                graph_options["chd"] = chd

                graph_options["chtt"] = name_lookup[taxii] + " for " + species_names

                filename = ("temp " + graph_options["chtt"] + ".png").gsub(' ','_')

                query = CHART_URI
                graph_options.each do |feature, attribute|
                    query += feature + '=' + attribute + '&'
                end

                query = query.chop!.gsub(' ','%20')

                #puts "length: " + query.length.to_s
                #puts query


                http = Net::HTTP.new(post_uri.host, post_uri.port)
                # http.use_ssl = true

                request = Net::HTTP::Post.new(post_uri.request_uri)
                request.set_form_data(graph_options)

                response = http.request(request)
                out_file = File.new('./data/charts/' + filename, 'w')

                out_file.write(response.body)

                out_file.close
                # puts set_graphs[taxii]["match"].to_s
                #puts chd_cost
                #puts chd_match
                #p graph_options

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