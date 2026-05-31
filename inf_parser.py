import configparser
import pandas as pd # for output report

def read_from_inf(filename,computer_name):
    lst = []
    config = configparser.ConfigParser()
    config.read(filename,encoding='utf-8-sig')

    for section in config.sections():

        for key in config[section]:
            lst_row = []
            
            lst_row.append(computer_name)
            lst_row.append(section)
            lst_row.append(config[section][key])

            lst.append(lst_row)
    return pd.DataFrame(lst)

print (read_from_inf('./for_inf_testing/TWN1571.inf','TWN1571'))