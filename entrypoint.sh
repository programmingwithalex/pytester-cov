#!/bin/bash

# --- Parameters --- #
# $1: pytest-root-dir
# $2: tests dir
# $3: cov-omit-list
# $4: requirements filepath
# $5: cov-threshold-single
# $6: cov-threshold-total

cov_config_fname=.coveragerc
cov_threshold_single_fail=false
cov_threshold_total_fail=false

# must reinstall requirements in container to prevent ImportErrors
if test -f "$4"; then
    python3 -m pip install -r $4 --no-cache-dir --user;
fi

# write omit str list to coverage file
cat << EOF > $cov_config_fname
[run]
omit = $3
EOF

# get list recursively of dirs to run pytest-cov on
find_cmd_str="find $1 -type d"
pytest_dirs=$(eval "$find_cmd_str")

# build cov argument for pytest cmd with list of dirs
pytest_cov_dirs=""
for dir in $pytest_dirs; do
  pytest_cov_dirs+="--cov=${dir} "
done

output=$(python3 -m pytest $pytest_cov_dirs --cov-config=.coveragerc $2)

# remove pytest-coverage config file
if [ -f $cov_config_fname ]; then
   rm $cov_config_fname
fi

parse_title=false  # parsing title (not part of table)
parse_contents=false  # parsing contents of table
parsed_content_header=false  # finished parsing column headers of table
item_cnt=0 # four items per row in table
items_per_row=4

output_table_title=''
output_table_contents=''
file_covs=()
total_cov=0

for x in $output; do
  if [[ $x =~ ^-+$ && $x != '--' ]]; then
    if [[ "$parse_title" = false && "$parse_contents" = false ]]; then
      parse_title=true
    else
      output_table_title+="$x "

      parse_title=false
      parse_contents=true
      continue
    fi
  fi

  if [ "$parse_contents" = true ]; then
    # reached end of coverage table contents
    if [[ "$x" =~ ^={5,}$ ]]; then
      break
    fi
  fi

  if [ "$parse_title" = false ]; then
    if [ "$parse_contents" = false ]; then
      continue
    else  # parse contents
      if [[ "$parsed_content_header" = false && $item_cnt == 4 ]]; then
        # needed between table headers and values for markdown table
        output_table_contents+="
| ------ | ------ | ------ | ------ |"
      fi

      if [[ $item_cnt == 3 ]]; then
        # store individual file coverage
        file_covs+=( ${x::-1} )  # remove percentage at end
        total_cov=${x::-1}  # will store last one
      fi

      if [[ $item_cnt == 4 ]]; then
        parsed_content_header=true
      fi

      item_cnt=$((item_cnt % items_per_row))

      if [ $item_cnt = 0 ]; then
        output_table_contents+="
"
      fi

      output_table_contents+="| $x "

      item_cnt=$((item_cnt+1))

      if [ $item_cnt == 4 ]; then
        output_table_contents+="|"
      fi
    fi
  else
    # parse title
    output_table_title+="$x "
  fi

  output_table+="$x"
done

# remove last file-cov b/c it's total-cov
unset 'file_covs[${#file_covs[@]}-1]'

# remove first file-cov b/c it's table header
file_covs=("${file_covs[@]:1}") #removed the 1st element

# check if any file_cov exceeds threshold
for file_cov in "${file_covs[@]}"; do
  if [ "$file_cov" -lt $5 ]; then
    cov_threshold_single_fail=true
  fi
done

# check if total_cov exceeds threshold
if [ "$total_cov" -lt $6 ]; then
  cov_threshold_total_fail=true
fi

# set badge color
if [ "$total_cov" -le 20 ]; then
  color="red"
elif [ "$total_cov" -gt 20 ] && [ "$total_cov" -le 50 ]; then
  color="orange"
elif [ "$total_cov" -gt 50 ] && [ "$total_cov" -le 70 ]; then
  color="yellow"
elif [ "$total_cov" -gt 70 ] && [ "$total_cov" -le 90 ]; then
  color="green"
elif [ "$total_cov" -gt 90 ]; then
  color="brightgreen"
fi

badge="![pytest-coverage-badge](https://img.shields.io/static/v1?label=pytest-coverage🛡️&message=$total_cov%&color=$color)"
output_table_contents="${badge}${output_table_contents}"

# github actions truncates newlines, need to do replace
# https://github.com/actions/create-release/issues/25
output_table_contents="${output_table_contents//'%'/'%25'}"
output_table_contents="${output_table_contents//$'\n'/'%0A'}"
output_table_contents="${output_table_contents//$'\r'/'%0D'}"

# set output variables to be used in workflow file
echo "::set-output name=output-table::$output_table_contents"
echo "::set-output name=cov-threshold-single-fail::$cov_threshold_single_fail"
echo "::set-output name=cov-threshold-total-fail::$cov_threshold_total_fail"
