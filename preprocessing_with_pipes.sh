#!/bin/bash

in_file=$1
out_file="cleaned_data_with_pipes.csv"

# Check that input file is provided
if [[ -z "$in_file" ]]; then
	echo "Usage: $0 <in_file>"
	exit 1
fi


# Check that input file also exists before continuing
if [[ ! -f "$in_file" ]]; then
	echo "Input file '$in_file' cannot be found"
    	exit 1
fi

# Store header row 
header=$(head -n 1 "$in_file")


# Handle leading/trailing spaces, tabs, new lines.
echo "Trimming spaces from each column and handling tabs/new lines..."
awk -F, '{
	for (i=1; i<=NF;i++) {
		# Trim leading/trailing spaces
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
		
		# Handle tabs
        	gsub(/\t/, "", $i)
        
        	# Handle newlines
        	gsub(/\n/, "", $i)
	}
	print
}' "$in_file" > temp_file1


# Check format of dates (yyyy-mm-dd), which is the second column
echo "Checking format of dates..."
awk -F',' -v OFS=',' '
{
	date = $2
	
	# Check that date has right format
	if (date ~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/) {		
		print $0
	}
}' temp_file1 > temp_file2


# Check for missing values
echo "Checking for missing values (empty or 'NA')..."
awk -F',' -v OFS=',' 'NR == 1 {
	# Store header row into array
	for (i=1; i<=NF; i++) {
		headers[i] = $i
	}
}
{
	# Iterate through the rows and count missing values
	for (i=1; i<=NF; i++) {
		if ($i == "" || $i == "NA") {
			missing[i]++
		}
	}
}
END {	
	# Print column names and NA counts
	for (col in missing) {
		print "Column \"" headers[col] "\" has " missing[col] " missing values"
	}
}' temp_file1 > most_missing_values_with_pipes.txt


# Remove first column and last 6 columns-- not needed for our questions of interest
echo "Removing first column and last 6 columns..."
cut -d',' -f2-14 temp_file2 > temp_file3


# Adjust header to be consistent with new columns
header=$(echo "$header" | cut -d',' -f2-14)

# Add header to cleaned data
echo "$header" > "$out_file"
cat temp_file3 >> "$out_file"


# Clean up
rm -f temp_file1 temp_file2 temp_file3
mv most_missing_values_with_pipes.txt data/cleaned
mv $out_file data/cleaned

echo "Preprocessing completed."

