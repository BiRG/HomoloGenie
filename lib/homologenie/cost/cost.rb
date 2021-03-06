#!/usr/bin/ruby

module HomoloGenie
    class Cost
        @@aa_costs = { "A" => 14.5,
                "C" => 26.5,
                "D" => 15.5,
                "E" => 9.5,
                "F" => 61.0,
                "G" => 14.5,
                "H" => 29.0,
                "I" => 38.0,
                "K" => 36.0,
                "L" => 37.0,
                "M" => 36.5,
                "N" => 18.5,
                "P" => 14.5,
                "Q" => 10.5,
                "R" => 20.5,
                "S" => 14.5,
                "T" => 21.5,
                "V" => 29.0,
                "W" => 75.5,
                "Y" => 59.0 }

        def self.calc_cost(sequence)
            total = 0
            sequence.split("").each do |char|
                #only accept AA's from list
                if @@aa_costs.has_key?(char)
                    total += @@aa_costs[char]
                else
                    return nil
                end #if
            end #do

            #ignore initial M
            return (total - 36.5)
        end #def

    end #class
end #module
