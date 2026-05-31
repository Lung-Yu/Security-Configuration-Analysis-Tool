
from os import listdir,system
from os.path import isfile, join

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files


# get_files('original_files')
source_path = 'original_files'
target_path = 'collected_from_clients'
encoding = 'utf8'

print ('Please put the data obtained from the client into the 【%s】 directory folder.'%(source_path))


for fn in get_files(source_path):
    format_str =  "powershell -Command \"Get-Content %s | Set-Content -Encoding %s %s\""%(join(source_path,fn),
        encoding,
        join(target_path,fn))
    system(format_str)
    # print (format_str)
    print ("[+] %s processing"%fn)
    
print('The data has been encoded as UTF-8 and stored in the 【%s】 folder'%target_path)