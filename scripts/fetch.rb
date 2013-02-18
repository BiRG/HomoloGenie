require 'yaml'
require 'homologenie/homolog'
require 'homologenie/protein'
require 'homologenie/taxonomy'
require 'vertebrae/database/homologene/fasta'
require 'vertebrae/net/request_processor'
require 'vertebrae/search/result'
require 'vertebrae/sequence/tiny_sequence_set'

# Dataset Filename
filename = "D:\\homologene.data"

# Verbosity:
# 0 = Silence
# 1 = Standard Messages
# 2 = Additional Details
$verbosity = 2

def echo(message, verbosity)
  return if verbosity > $verbosity
  print message
end

echo("* Starting Dataset Fetch\n", 1)
stotal = Time.now

# Initialize the Entrez request processor

processor = Vertebrae::Net::RequestProcessor.new()
processor.base_address = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils"
processor.maximum_concurrent_requests = 100   # Lets not wait on the server
processor.maximum_request_count = 3           # NCBI Regulation
processor.minimum_request_interval = 1        # NCBI Regulation

# Perform a HomoloGene search

terms = Array.new()
terms << "mus"
terms << "rattus"
terms << "danio"
terms << "gallus"
terms << "macaca"
terms << "pan"
terms << "homo"
terms << "canis"
terms << "bos"

parameters = Hash.new()
parameters["db"] = "homologene"
parameters["retmax"] = 0
parameters["term"] = terms.join("[organism]+")
parameters["usehistory"] = "y"

echo("* Starting HomoloGene Search\n", 1)
stime = Time.now

presult = nil
sresult = nil
while !presult || presult.error? || !sresult || sresult.has_error? do
  presult = processor.request("esearch.fcgi", parameters)
  next if presult.error?
  sresult = Vertebrae::Search::Result.new(presult.response.body)
end

etime = Time.now
echo("- Finished HomoloGene Search in #{etime - stime} Seconds\n", 1)

# Download the HomoloGene IDs from the previous search

parameters = Hash.new()
parameters["db"] = "homologene"
parameters["retmax"] = 100000
parameters["query_key"] = sresult.key
parameters["webenv"] = sresult.environment

task_count = sresult.count / parameters["retmax"] + 1
tasks = Array.new(task_count, false)

homologene_ids = Array.new()

echo("* Starting HomoloGene ID Download\n", 1)
stime = Time.now

count = sresult.count
echo("- #{count} IDs Remaining", 2)

successful = false
until successful do
  tasks.each.with_index do |t, i|
    next unless tasks[i] == false
    parameters["retstart"] = i * parameters["retmax"]
    processor.enqueue("esearch.fcgi", parameters) do |result|
      next if result.error?
      sresult = Vertebrae::Search::Result.new(result.response.body)
      next if sresult.has_error?
      tasks[i] = true
      homologene_ids += sresult.id_list
      count -= parameters["retmax"]
      if count > 0
        echo("\r- #{count} IDs Remaining     ", 2)
      else
        echo("\r- 0 IDs Remaining     \n", 2)
      end
    end
  end
  processor.wait()
  status = true
  tasks.each do |completed|
    status = status && completed
  end
  successful = status
end

etime = Time.now
echo("- Finished HomoloGene ID Download in #{etime - stime} Seconds\n", 1)

# Download a temporary set of FASTA records for each protein

temporary_homolog_groups = Hash.new()

parameters = Hash.new()
parameters["db"] = "homologene"
parameters["retmode"] = "text"
parameters["rettype"] = "fasta"

task_size = 500
task_count = homologene_ids.length / task_size + 1
tasks = Array.new(task_count, false)

echo("* Starting HomoloGene FASTA Download\n", 1)
stime = Time.now

count = homologene_ids.length
echo("- #{count} FASTA Records Remaining", 2)

successful = false
until successful do
  tasks.each.with_index do |t, i|
    next unless tasks[i] == false
    index = i * task_size
    parameters["id"] = homologene_ids[index..task_size + index - 1].join(",")
    processor.enqueue("efetch.fcgi", parameters) do |result|
      next if result.error?
      fresult = Vertebrae::Database::HomoloGene::Fasta.new(result.response.body)
      next if fresult.has_error?
      tasks[i] = true
      fresult.groups.each do |id, proteins|
        temporary_homolog_groups[id] = proteins
      end
      count -= task_size
      if count > 0
        echo("\r- #{count} FASTA Records Remaining     ", 2)
      else
        echo("\r- 0 FASTA Records Remaining     \n", 2)
      end
    end
  end
  processor.wait()
  status = true
  tasks.each do |completed|
    status = status && completed
  end
  successful = status
end

etime = Time.now
echo("- Finished HomoloGene FASTA Download in #{etime - stime} Seconds\n", 1)

# Download a tiny sequence (xml FASTA) for each protein

protein_ids = Array.new()

temporary_homolog_groups.each do |id, proteins|
  protein_ids += proteins
end

protein_sequences = Hash.new()

parameters = Hash.new()
parameters["db"] = "protein"
parameters["retmode"] = "xml"
parameters["rettype"] = "fasta"

task_size = 500
task_count = protein_ids.length / task_size + 1
tasks = Array.new(task_count, false)

echo("* Starting Protein Sequence Download\n", 1)
stime = Time.now

count = protein_ids.length
echo("- #{count} Sequences Remaining", 2)

successful = false
until successful do
  tasks.each.with_index do |t, i|
    next unless tasks[i] == false
    index = i * task_size
    parameters["id"] = protein_ids[index..task_size + index - 1].join(",")
    processor.enqueue("efetch.fcgi", parameters) do |result|
      next if result.error?
      fresult = Vertebrae::Sequence::TinySequenceSet.new(result.response.body)
      next if fresult.has_error?
      tasks[i] = true
      fresult.sequences.each do |gi, sequence|
        protein_sequences[gi] = sequence
      end
      count -= task_size
      if count > 0
        echo("\r- #{count} Sequences Remaining     ", 2)
      else
        echo("\r- 0 Sequences Remaining     \n", 2)
      end
    end
  end
  processor.wait()
  status = true
  tasks.each do |completed|
    status = status && completed
  end
  successful = status
end

etime = Time.now
echo("- Finished Protein Sequence Download in #{etime - stime} Seconds\n", 1)

# Construct data set from temporary homolog groups and sequences

echo("* Starting Dataset Construction\n", 1)
stime = Time.now

homolog_groups = Hash.new()

homologene_ids.each do |id|
  homolog_groups[id] = HomoloGenie::Homolog.new(id)
end

count = protein_sequences.length
echo("- #{count} Sequences Remaining", 2)

temporary_homolog_groups.each do |hid, proteins|
  proteins.each do |pid|
    sequence = protein_sequences[pid]
    gid = sequence.gi
    acc = sequence.accession
    seq = sequence.sequence
    tax = sequence.taxonomy
    tid = sequence.tid
    protein = HomoloGenie::Protein.new(acc, seq)
    taxonomy = HomoloGenie::Taxonomy.new(tid, tax)
    homolog_groups[hid].taxonomies[tid] ||= taxonomy
    homolog_groups[hid].taxonomies[tid].proteins[gid] = protein
    count -= 1
    if count > 0
      echo("\r- #{count} Sequences Remaining     ", 2)
    else
      echo("\r- 0 Sequences Remaining     \n", 2)
    end
  end
end

etime = Time.now
echo("- Finished Dataset Construction in #{etime - stime} Seconds\n", 1)

# Write the data set to a file

echo("* Starting Dataset Write\n", 1)
stime = Time.now

data_file = File.open(filename, "w")
data_file.puts homolog_groups.to_yaml()
data_file.close()

etime = Time.now
echo("- Finished Dataset Write in #{etime - stime} Seconds\n", 1)

etotal = Time.now
echo("- Finished Dataset Fetch in #{(etotal - stotal) / 60} Minutes\n", 1)
