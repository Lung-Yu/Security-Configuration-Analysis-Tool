from IniHelper import *
from SecurityConfiguration import *
import pandas as pd # for output report

from ProgressBar import ProgressBar


from os import listdir
from os.path import isfile, join

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files

def step1_extract_security_setting_from_htmls(output_filename='raw_data.csv'):
    print ('Running Step 1 ....')
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
        
    progress.done() 

    result = pd.concat(dataframes)
    result.to_csv(output_filename,index=False)

def step2_check_all_setting_is_ok_or_not(src_filename,output_filename):
    print ('Running Step 2 ....')
    # TODO : Compare the original data(raw_data.csv) and the rule file(rule.inf) to see if they match the settings.
    
    # TODO : use to_csv compared result to save as csv file.
    pass
def step3_make_report(src_filename,output_filename):
    # TODO : call my make report python script (may don't have time to refactoring).
    print ('Running Step 3 ....')
    pass

def main():
    step1_output_filename = 'raw_data.csv'
    step1_extract_security_setting_from_htmls(step1_output_filename)
    
    step2_output_filename = "out.csv"
    step2_check_all_setting_is_ok_or_not(step1_output_filename,step2_output_filename)

    step3_output_filename = "report.csv"
    step3_make_report(step2_output_filename,step3_make_report)

if __name__ == '__main__':
    main()