rm -rf COMBINED-DATA
mkdir -p COMBINED-DATA
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_COMMAND="sed -i ''"
else
    SED_COMMAND="sed -i"
fi

for dir in $(ls -d RAW-DATA/DNA*); do
    
    culture_name=$(basename $dir)
    new_culture_name=$(grep $culture_name RAW-DATA/sample-translation.txt | awk '{print $2}')
    MAG_counter=1
    BIN_counter=1
    cp $dir/checkm.txt COMBINED-DATA/$new_culture_name-CHECKM.txt
    cp $dir/gtdb.gtdbtk.tax COMBINED-DATA/$new_culture_name-GTDB-TAX.txt
    for fasta_file in $dir/bins/*.fasta; do
        bin_name=$(basename $fasta_file .fasta)
        completion=$(grep "$bin_name " $dir/checkm.txt | awk '{print $13}')
        contamination=$(grep "$bin_name " $dir/checkm.txt | awk '{print $14}')

        if [[ $bin_name == bin-unbinned ]]; then
            new_name="${new_culture_name}_UNBINNED.fa"
            echo "Working on $new_culture_name unbinned contigs (now called $new_name) ..."
        elif (( $(echo "$completion >= 50" | bc -l) && $(echo "$contamination < 5" | bc -l) )); then
            
            new_name=$(printf "${new_culture_name}_MAG_%03d.fa" $MAG_counter)
            echo "Working on $new_culture_name MAG $bin_name (now called $new_name) (C/R: $completion/$contamination) ..."
            MAG_counter=$(("$MAG_counter + 1"))
        else
            new_name=$(printf "${new_culture_name}_BIN_%03d.fa" $BIN_counter)
            echo "Working on $new_culture_name BIN $bin_name (now called $new_name) (C/R: $completion/$contamination) ..."
            BIN_counter=$(($BIN_counter + 1))
        fi

        $SED_COMMAND "s/ms.*${bin_name}/$(basename $new_name .fa)/g" COMBINED-DATA/$new_culture_name-CHECKM.txt
        $SED_COMMAND "s/ms.*${bin_name}/$(basename $new_name .fa)/g" COMBINED-DATA/$new_culture_name-GTDB-TAX.txt

        cp "$fasta_file" "COMBINED-DATA/$new_name"  
        awk -v prefix="$new_culture_name" '/^>/ {print ">" prefix "_" ++count; next} {print}' "$fasta_file" > "COMBINED-DATA/$new_name"
    done
done