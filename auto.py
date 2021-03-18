from IniHelper import *
from SecurityConfiguration import *
import pandas as pd # for output report

from ProgressBar import ProgressBar


from os import listdir
from os.path import isfile, join

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files


from time import sleep

def test(parser:GPResult_Parser):
     for i in range(parser.Get_Item_Count()):
            item = parser.Get_Item(index=i)
            print (item)


def main():
    path = IniHelper.get_instance().get_value(
        session=E_INI_Session.DATA,
        key=E_INI_KEY.SOURCE_PATH)
    filenames = get_files(path)

    progress = ProgressBar(len(filenames), fmt=ProgressBar.FULL)
    progress()
    # start analyze
    dataframes = []

    for fn in filenames:
        # TODO: analyze the gpresult.html file
        
        parser = GPResult_Parser(filename=join(path,fn))
        lst = parser.GetAllSetting()

        dataframes.append(parser.GetAllSettingsAsDataFrame())
        
        # TODO: draw on ui
        progress.current += 1
        progress()
        sleep(0.1)
    progress.done() 

    result = pd.concat(dataframes)
    result.to_csv('raw_data.csv',index=False)


if __name__ == '__main__':
    main()