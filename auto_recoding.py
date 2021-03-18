
from os import listdir,system
from os.path import isfile, join

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files


# get_files('original_files')
source_path = 'original_files'
target_path = 'collected_from_clients'

for fn in get_files(source_path):
    format_str =  "Get-Content %s | Set-Content -Encoding utf8 %s"%(join(source_path,fn),join(target_path,fn))
    print (format_str)
    


