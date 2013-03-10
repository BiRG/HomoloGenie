require 'homologenie/alignment/needleman_wunsch'
include HomoloGenie::Alignment

# sequences = %w(ACAGTAG ACTCG)
# sequences = %w(AJCJNRCKCRBP ABCNJRQCLCRPM)
# sequences = %w(MPEPTKSAPAPKKGSKKAVTKAQKKDGKKRKRSRKESYSVYVYKVLKQVHPDTGISSKAMGIMNSFVNDIFERIAGEASRLAHYNKRSTITSREIQTAVRLLLPGELAKHAVSEGTKAVTKYTSSK MRCRFHFDSYLQNSEGSMPEPAKSAPAPKKGSKKAVTKAQKKDGKKRKRSRKESYSVYVYKVLKQVHPDTGISSKAMGIMNSFVNDIFERIAGEASRLAHYNKRSTITSREIQTAVRLLLPGELAKHAVSEGTKAVTKYTSSK)
sequences = %w(MERSPDVSPGPSRSFKEELLCAVCYDPFRDAVTLRCGHNFCRGCVSRCWEVQVSPTCPVCKDRASPADLRTNHTLNNLVEKLLREEAEGARWTSYRFSRVCRLHRGQLSLFCLEDKELLCCSCQADPRHQGHRVQPVKDTAHDFRAKCRNMEHALREKAKAFWAMRRSYEAIAKHNQVEAAWLEGRIRQEFDKLREFLRVEEQAILDAMAEETRQKQLLADEKMKQLTEETEVLAHEIERLQMEMKEDDVSFLMKHKSRKRRLFCTMEPEPVQPGMLIDVCKYLGSLQYRVWKKMLASVESVPFSFDPNTAAGWLSVSDDLTSVTNHGYRVQVENPERFSSAPCLLGSRVFSQGSHAWEVALGGLQSWRVGVVRVRQDSGAEGHSHSCYHDTRSGFWYVCRTQGVEGDHCVTSDPATSPLVLAIPRRLRVELECEEGELSFYDAERHCHLYTFHARFGEVRPYFYLGGARGAGPPEPLRICPLHISVKEELDG MASLNVSAEELSCPVCCEIFRNPVVLSCSHSVCKECLQQFWRTKTTQECPVCRKSSRDDPPCNLVLKNLCELFLKDRNERCSSGSEEICSLHSEKLKLFCLEDKQPVCLVCRDSKQHDNHKFRPISEVASSYKEALNTALKSLQKKLKHNEKMIVEFEKTFQHIKSQVDHTERQIKHEFEKLHQFLRDEEEATITALREEEEQKKQMMKEKLEEMNTHISALSHTIKDTEEMLKANDVCFLKEFPVSMERVQISQPDPQTPSGALIHVSRYLGNLPFRVWKKMQDIVYYSPVILDSNTAHPRLVLSDDLTSMRYSGKDQPVPDNPERFDCYYCVLGSEGFTSGKHCWDVEVKESEYWNLGVTTASNQWTGRVFYNTGVWSVKYKQSAGSGFVVNQDLERVRVDLDCDRGTVSFSDPVTNTHLHTYTTTFTESVFPFFYSLGSLKILPSLLGVCGYSTI)

def calculate_gap_score(index, path)
  return path.score - 1
end

def calculate_match_score(index, path, sequences)
  element_0 = sequences[0][index[0]]
  element_1 = sequences[1][index[1]]
  return element_0 == element_1 ? path.score + 1 : path.score
end

def calculate_preliminary_score(index, path)
  initial_index = Array.new(index.length, -1)
  score = nil
  if index == initial_index
    score = 0
  else
    other_dimension = index[0] == -1 ? 1 : 0
    score = -1 * index[other_dimension] - 1
  end
  return score
end

def gap?(index, path)
  return (index[0] - path.index[0]) != (index[1] - path.index[1])
end

def preliminary?(index)
  return index.include?(-1)
end

processor = NeedlemanWunsch.new
processor.align(*sequences) do |index, path|
  score = nil
  if preliminary?(index)
    score = calculate_preliminary_score(index, path)
  else
    if gap?(index, path)
      score = calculate_gap_score(index, path)
    else
      score = calculate_match_score(index, path, sequences)
    end
  end
  next score
end

puts " ALIGNMENT SCORE: #{processor.score}"

processor.alignments.each do |alignment|
  puts "\n"
  alignment.each do |sequence|
    puts " #{sequence}"
  end
end

puts
puts " ALIGNMENT COUNT: #{processor.alignments.length}"
puts
