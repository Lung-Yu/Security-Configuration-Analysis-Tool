from IniHelper import *
from SecurityConfiguration import *
import pandas as pd # for output report

from ProgressBar import ProgressBar

from os import listdir
from os.path import isfile, join

error_files = []

def IsEmptyData(size):
    if size == 0:
        return True
    else:
        return False

def get_files(path):
    files = [f for f in listdir(path) if isfile(join(path, f))]
    return files

def load_rule():
    windows_rule_filename = IniHelper.get_instance().get_value(E_INI_Session.RULE,E_INI_KEY.WINDOWS_FILE_NAME)
    print(windows_rule_filename)
    csv = pd.read_csv(windows_rule_filename)
    return csv

def get_computer_setting(df,computer_name):
    return df.loc[df['ComputerName'] == computer_name]

def current_computer_setting_at_current_rule_tag(current_rule_tag,computer_settings):
    computer_settings_size = min(computer_settings.count())
    for row in computer_settings.iterrows():
        policy = row[1]['Policy']
        setting = row[1]['Setting']
        compared = row[1]['Compared Result']
        # print (policy,setting,compared,current_rule_tag)
        for tag in current_rule_tag:
            if policy == tag.replace('\n',''):
                computer_settings = setting
                compared_results = compared
                return (computer_settings,compared_results)
    return (None, None)
def get_rule_names(rules):
    lst = []

    for rule in rules:
        lst.append(rule)
        lst.append('check for %s'%rule)  # for compare results
    
    return lst

def get_policy_wording(operations,words):
    if len(words) != len(operations):
        raise ArgumentError("input size is not match.")
    results = []
    for idx,operation in enumerate(operations):
        if (operation == '='):
            results.append((" .%s %s"%(operation,words[idx])))
        else:    
            results.append((" %s %s"%(operation,words[idx])))
        results.append('')  # for compared result
    return results

def step1_extract_security_setting_from_htmls(output_filename='raw_data.csv'):
    path = IniHelper.get_instance().get_value(
        session=E_INI_Session.DATA,
        key=E_INI_KEY.SOURCE_PATH)
    print ('Step 1：Extract config from ', path)
    
    filenames = get_files(path)
    size_filename = len(filenames)
    if (IsEmptyData(size_filename)):
        print ("[-] No data in the 【%s】 folder"%(path))
        return False

    progress = ProgressBar(size_filename, fmt=ProgressBar.FULL)
    progress()
    # start analyze
    dataframes = []

    for fn in filenames:
        # TODO: analyze the gpresult.html file
        try:
            parser = GPResult_Parser(filename=join(path,fn))
            lst = parser.GetAllSetting()
            _dataFrame = parser.GetAllSettingsAsDataFrame()
            dataframes.append(_dataFrame)
            
            # TODO: draw on ui
            progress.current += 1
            progress()
        except IndexError as e:
            error_files.append(fn)
        except Exception as e:
            print (e)
            pass
    progress.done() 

    result = pd.concat(dataframes)
    result.to_csv(output_filename,index=False)

def step2_check_all_setting_is_ok_or_not(src_filename,output_filename):
    print ('Step 2：Check if the setting complies with GCB.')
    # TODO : Compare the original data(raw_data.csv) and the rule file(rule.inf) to see if they match the settings.
    
    raw_data = pd.read_csv(src_filename)
    df_rule = load_rule()
    print("*")
    compared_results = []
    computer_size = max(raw_data.count())
    rule_size = min(df_rule.count())
    if (IsEmptyData(computer_size)):
        print ("［-］ No data in the 【%s】 file"%(src_filename))
        return False
    progress = ProgressBar(computer_size, fmt=ProgressBar.FULL)
    progress()

    for idx_rawdata in range(computer_size):
        try:
            item_policy = raw_data['Policy'][idx_rawdata].strip()
            item_setting = raw_data['Setting'][idx_rawdata]

            item_result = None
            isFound = False
            for idx in range(rule_size):   
                rule_tags = [df_rule['ch'][idx].strip(), df_rule['en'][idx].strip()]
                # print (len(item_policy),type(item_policy),item_policy)
                # print (len(rule_tags[0]),type(rule_tags[0]),rule_tags[0])
                # print (len(rule_tags[1]),type(rule_tags[1]),rule_tags[1])
                # print (item_policy in rule_tags)
                # print ("================")
                # if (item_policy == df_rule['ch'][idx]) or (item_policy == df_rule['en'][idx]):
                if item_policy in rule_tags:
                    # print ('policy ',item_policy,
                    # 'rules',[df_rule['rule_main'][idx],df_rule['rule_sec'][idx]],'operation ',str(df_rule['operations'][idx]))
                    # print (item_policy,df_rule['ch'][idx],df_rule['en'][idx])
                    isPass = PolicyComparator.get_instance().get_compared_results(
                        item_setting,
                        policy_settings=[df_rule['rule_main'][idx],df_rule['rule_sec'][idx]],
                        operation=df_rule['operations'][idx])

                    compared_results.append(isPass)
                    isFound = True
                
            if not isFound:
                compared_results.append('NAN')
        except AttributeError as e:
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
    print ('Step 3：Making report.')
    rule_config_path = IniHelper.get_instance().get_value(E_INI_Session.RULE,E_INI_KEY.WINDOWS_FILE_NAME)

    df_rule = pd.read_csv(rule_config_path)
    df_rawdata_with_compared_result = pd.read_csv(src_filename)

    computer_names = computers = list(set(df_rawdata_with_compared_result['ComputerName']))
    datatable = []
    rule_name_size = len(df_rule['Name'])

    if (IsEmptyData(rule_name_size)):
        print ("[-] No rule in the 【%s】 file"%(rule_config_path))
        return False
    progress = ProgressBar(rule_name_size, fmt=ProgressBar.FULL)
    progress()

    for idx_rule in range(rule_name_size):
        
        row_data = []
        row_compare_result = []
        for computer_name in computer_names:

            # TODO : get current computer setting at current rule tag
            (computer_settings,compared_results) = current_computer_setting_at_current_rule_tag(
                current_rule_tag = [df_rule['ch'][idx_rule],df_rule['en'][idx_rule]],
                computer_settings= get_computer_setting(df_rawdata_with_compared_result,computer_name))

            if computer_settings == None:
                row_data.append("NAN")
                row_compare_result.append('False')
            else:
                row_data.append(computer_settings)
                row_compare_result.append(compared_results)
        
        datatable.append(row_data)
        datatable.append(row_compare_result)
        progress.current += 1
        progress()

    pd_dt = pd.DataFrame(datatable,columns=computer_names)
    rule_names = list(df_rule['Name'])
    pd_dt.insert(0,'Setting Name',get_rule_names(list(df_rule['Name'])))
    pd_dt.insert(1,'Rule',get_policy_wording(operations=df_rule['operations'],words=df_rule['rule_sec']))
    # print (pd_dt)

    pd_dt_translation = pd_dt.T
    # pd_dt_translation.to_csv(output_filename,header=False)
    pd_dt_translation.to_csv('roadmap_v2.csv',header=False)
    # print (pd_dt_translation)

    pass

def show_currently_error_files():
    if len(error_files) > 0:
        print ("Failed to parse the following data.")

        for filename in error_files:
            print("[-] %s"%(filename))

def main():
    try:
        step1_output_filename = 'raw_data.csv'
        step1_extract_security_setting_from_htmls(step1_output_filename)
        show_currently_error_files()

        step2_output_filename = "out.csv"
        step2_check_all_setting_is_ok_or_not(step1_output_filename,step2_output_filename)

        step3_output_filename = "report.csv"
        step3_make_report(step2_output_filename,step3_make_report)

        print("\n\n finish\n")
    except FileNotFoundError as e:
        print (e)
    except Exception as e:
        print (e)

if __name__ == '__main__':
    main()