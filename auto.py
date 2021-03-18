from IniHelper import *
from ProgressBar import ProgressBar

from os import listdir
from os.path import isfile, join

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files


from time import sleep
def main():
    path = IniHelper.get_instance().get_value(
        session=E_INI_Session.DATA,
        key=E_INI_KEY.SOURCE_PATH)
    filenames = get_files(path)

    progress = ProgressBar(len(filenames), fmt=ProgressBar.FULL)
    progress()
    # start analyze
    for fn in filenames:
        # TODO: analyze the gpresult.html file
        


        
        # TODO: draw on ui
        progress.current += 1
        progress()
        sleep(0.1)
    progress.done() 


if __name__ == '__main__':
    main()