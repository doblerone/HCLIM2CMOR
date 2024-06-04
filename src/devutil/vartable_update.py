#!/usr/bin/env python3

import csv
import json
import pooch
import pathlib

INDEX_VAR_CM_SUB = 8
INDEX_VAR_CM_DAY = 9
INDEX_VAR_CM_MON = 10
INDEX_UNIT = 13
INDEX_VAR_LONG_NAME = 24
INDEX_VAR_STD_NAME = 26


def main():
    cmor_table_files = {
        "1hr": "CORDEX-CMIP6_1hr.json",
        "6hr": "CORDEX-CMIP6_6hr.json",
        "day": "CORDEX-CMIP6_day.json",
        "mon": "CORDEX-CMIP6_mon.json",
        "fx": "CORDEX-CMIP6_fx.json",
    }

    # Let pooch deal with downloading and caching cmor table files
    #
    cmor_table_file_manager = pooch.create(
        path=pooch.os_cache("hclim2cmor"),
        base_url="https://github.com/WCRP-CORDEX/cordex-cmip6-cmor-tables/raw/main/Tables",
        registry={f: None for f in cmor_table_files.values()},
    )
    cmor_tables = {}
    for freq, file in cmor_table_files.items():
        table_file_path = cmor_table_file_manager.fetch(file)
        with open(table_file_path) as f:
            cmor_tables[freq] = json.load(f)["variable_entry"]

    # Load current csv
    #
    csv_path = (
        pathlib.Path(__file__).parent.parent
        / "CMORlight"
        / "Config"
        / "CORDEX6_CMOR_HCLIM_variables_table.csv"
    )
    table = []
    with open(csv_path, newline="") as f:
        reader = csv.reader(f, delimiter=";")
        for row in reader:
            table.append(row)

    # Fetch and insert values from cmor tables
    #
    for row in table[1:]:
        var = row[0]

        # Subdaily cell method
        #
        if var in cmor_tables["1hr"]:
            row[INDEX_VAR_CM_SUB] = cmor_tables["1hr"][var]["cell_methods"]
        elif var in cmor_tables["6hr"]:
            row[INDEX_VAR_CM_SUB] = cmor_tables["6hr"][var]["cell_methods"]
        else:
            row[INDEX_VAR_CM_SUB] = ""

        # Daily cell method
        #
        if var in cmor_tables["day"]:
            row[INDEX_VAR_CM_DAY] = cmor_tables["day"][var]["cell_methods"]
        else:
            row[INDEX_VAR_CM_DAY] = ""

        # Monthly cell_method
        #
        if var in cmor_tables["mon"]:
            row[INDEX_VAR_CM_MON] = cmor_tables["mon"][var]["cell_methods"]
        else:
            row[INDEX_VAR_CM_MON] = ""

        # units, long_name and standard_name
        #
        if var in cmor_tables["day"]:
            var_info = cmor_tables["day"][var]
        elif var in cmor_tables["fx"]:
            var_info = cmor_tables["fx"][var]
        else:
            raise KeyError("Couldn't find information about variable")

        row[INDEX_UNIT] = var_info["units"]
        row[INDEX_VAR_LONG_NAME] = var_info["long_name"]
        row[INDEX_VAR_STD_NAME] = var_info["standard_name"]

    # Save generated table to csv
    #
    with open(csv_path, "w") as f:
        writer = csv.writer(f, delimiter=";", lineterminator="\n")
        writer.writerows(table)


if __name__ == "__main__":
    main()
