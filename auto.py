from IniHelper import *
from SecurityConfiguration import *
import pandas as pd # for output report

from ProgressBar import ProgressBar


from os import listdir
from os.path import isfile, join

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files

def load_rule() -> pd.DataFrame:
    windows_rule_filename = IniHelper.get_instance().get_value(E_INI_Session.RULE,E_INI_KEY.WINDOWS_FILE_NAME)
    csv = pd.read_csv(windows_rule_filename)
    return csv
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
    
    raw_data = pd.read_csv(src_filename)
    df_rule = load_rule()

    compared_results = []
    computer_size = min(raw_data.count())
    rule_size = min(df_rule.count())

    progress = ProgressBar(computer_size, fmt=ProgressBar.FULL)
    progress()
    for idx_rawdata in range(computer_size):
        item_policy = raw_data['Policy'][idx_rawdata]
        item_setting = raw_data['Setting'][idx_rawdata]

        item_result = None
        isFound = False
        for idx in range(rule_size):   
            if item_policy == df_rule['ch'][idx] or item_policy == df_rule['en'][idx]:
                # print ('policy ',item_policy,
                # 'rules',[df_rule['rule_main'][idx],df_rule['rule_sec'][idx]],'operation ',str(df_rule['operations'][idx]))
                isPass = PolicyComparator.get_instance().get_compared_results(
                    item_setting,
                    policy_settings=[df_rule['rule_main'][idx],df_rule['rule_sec'][idx]],
                    operation=df_rule['operations'][idx])

                compared_results.append(isPass)
                isFound = True
            
        if not isFound:
            compared_results.append('NAN')
        # TODO: draw on ui
        progress.current += 1
        progress()

    progress.done()
    # TODO : export data as csv file.
    raw_data.insert(3,'Compared Result',compared_results)
    raw_data.to_csv(output_filename,index=False)
    

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