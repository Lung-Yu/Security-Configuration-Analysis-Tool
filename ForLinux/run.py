
from os import listdir,system
from os.path import isfile, join
import pandas as pd

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files


# get_files('original_files')
source_path = 'PWC'
encoding = 'utf8'

dataframes = []

for fn in get_files(source_path):
    full_path = join(source_path,fn)
    try:
        # ['RuleId','Rule','ComputerSetting','IsPass']
        item_df = pd.read_csv(full_path, header=None)
        print ("[+] %s"%full_path)
        print (item_df)
        computer_names = [fn] * min(item_df.count())
        item_df.insert(0, "Computer Name", computer_names)
        
        dataframes.append(item_df)
    except UnicodeDecodeError:
        print ("[-] %s"%full_path)
        continue
    except Exception :
        print ("[-] %s"%full_path)
        continue

total_df = pd.concat(dataframes)
print (total_df)
total_df.to_csv('total.csv',index=False,header=False)