"""
Read through HFPv2 csv files,
check given fields that should fit in PG smallint range
(or be within a more limited range),
and log erroneous lines.
"""

import csv
import argparse

RNG = [-32768, 32767]
VALIDATION = {
    'dir': [1, 2],
    'oper': RNG,
    'hdg': [0, 360],
    'line': RNG,
    'occu': [0, 100],
    'seq': RNG
}

def validate_value(name, allowed, value):
    if value == '' or value is None:
        return
    try:
        value = int(value)
    except:
        return f'{name:5}: {value}, failed to cast to int'
    if not (value >= allowed[0] and value <= allowed[1]):
        return f'{name:5}: {value}, outside allowed range {allowed[0]} ... {allowed[1]}'

def validate_record(rec_dict, line_num):
    for field_name, allowed_range in VALIDATION.items():
        field_value = rec_dict[field_name]
        res = validate_value(field_name, allowed_range, field_value)
        if res:
            print(f'{line_num:10}: {res}')

def validate_csv(filename):
    with open(filename, mode='r') as csv_file:
        csv_reader = csv.DictReader(csv_file)
        i = 0
        for line in csv_reader:
            i += 1
            validate_record(line, i)

def main():
    parser = argparse.ArgumentParser(description='Validate smallint fields of HFPv2 csv files.')
    parser.add_argument('filenames',
                        nargs='+')
    ar = parser.parse_args()
    for fn in ar.filenames:
        print(f'\n{fn}')
        validate_csv(fn)

if __name__ == '__main__':
    main()
