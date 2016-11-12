import csv

infile_path = "./county_election_results_2016.csv"
outfile_path = "./county_election_results_2016_row_per_county.csv"

fields_to_match = ["abbr_state","county","fips"]
candidate_names = ["Donald Trump", "Hillary Clinton", "Gary Johnson", "Jill Stein", "Other"]

def get_zeroed_dictionary(row):
    dictionary = dict([(name, 0) for name in candidate_names])
    for field in fields_to_match:
        dictionary[field] = row[field]
    return dictionary

def is_next_county(row, current_dict):
    for field in fields_to_match:
        if not current_dict[field] == row[field]:
            return True
    return False
        
def translate_infile_to_outfile(reader, writer):
    writer.writeheader()
    is_first = True

    for row in reader:
        if is_first:
            current_dict = get_zeroed_dictionary(row)
            is_first = False
        elif is_next_county:
            writer.writerow(current_dict)
            current_dict = get_zeroed_dictionary(row)
        else:
            pass #Just adding to the current dataset
        candidate = row["candidate"]
        votes = row["votes"]
        if candidate in candidate_names:
            current_dict[candidate] = votes
    writer.writerow(current_dict)


with open(infile_path) as infile:
    reader = csv.DictReader(infile)
    with open(outfile_path, "w") as outfile:
        writer = csv.DictWriter(outfile, fieldnames = fields_to_match + candidate_names)
        translate_infile_to_outfile(reader, writer)



