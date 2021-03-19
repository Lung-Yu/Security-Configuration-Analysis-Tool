from bs4 import BeautifulSoup
import codecs 
from html.parser import HTMLParser # for HTML Cleaner
import pandas as pd # for output report
from html.parser import HTMLParser
from typing import List
import re   #for policy compare


class HTMLCleaner(HTMLParser):
    def __init__(self, *args, **kwargs):
        super(HTMLCleaner, self).__init__(*args, **kwargs)
        self.tag_stack = []
        self.data_list = []
        self.hasdata = False

    def handle_starttag(self, tag, attrs):
        self.tag_stack.append(tag)
        self.hasdata = False

    def handle_endtag(self, tag):
        pop_tag = self.tag_stack.pop()
        if pop_tag == tag and self.hasdata == False:
            self.data_list.append('')

    def handle_data(self, data):
        self.hasdata = True
        self.data_list.append(data)


class INFO_GPO(object):
    def __init__(self):
        self.__Policy = None
        self.__Setting = None
        self.__Winning_GPO = None
    def setPolicy(self, policy):
        self.__Policy = policy
    def getPolicy(self):
        return self.__Policy
    def setSetting(self, setting):
        self.__Setting = setting
    def getSetting(self):
        return self.__Setting
    def setWinning_GPO(self,winning_gpo):
        self.__Winning_GPO = winning_gpo
    def getWinning_GPO(self):
        return self.__Winning_GPO
    def toString(self):
        return (self.__Policy,self.__Setting,self.__Winning_GPO)

    def toArray(self):
        return [self.__Policy,self.__Setting,self.__Winning_GPO]

class GPResult_Parser(object):
    def __init__(self,filename):
        self._filename = filename
        self._soup = BeautifulSoup(self.loadingFile(self._filename),"html.parser")
        self._tables = self._soup.find_all('table',{'class':'info3'})
    
    def loadingFile(self,filename):
        fn = codecs.open(filename, 'r',encoding="utf-8")
        src_html = fn.read()
        return src_html

    def get_current_computer_name(self):
        t_info = self._soup.find_all('table',{'class':'info'})
        # return find_index(get_text_from_html(t_info[0]),)
        return self._get_values_from_text(
            self._get_text_from_html(t_info[0]),target='Computer name')

    def Get_Item_Count(self):
        return len(self._tables)

    def Get_Item(self,index):
        return self._tables[index]

    def _get_text_from_html(self,str_html):
        new_str = str(str_html).replace('\n','').replace('<td></td>','<td> </td>')
        cleaner = HTMLCleaner()
        cleaner.feed(new_str)
        return cleaner.data_list

    def _find_index_from_html_txt_dict(self,dict_values,target):
        res_idx = -1
        for i in range(len(dict_values)):
            if dict_values[i] == target:
                res_idx = i
                break
        return res_idx

    def _get_values_from_text(self,dict_values,target,offset_idx=1):
        idx = self._find_index_from_html_txt_dict(dict_values,target)    
        if idx > -1:
            return dict_values[idx + offset_idx]
        else:
            return None

    def Get_ComputerSettingValue(self,tag_of_target):
        return self._get_values_from_text(
            self._get_text_from_html(self._tables),target=tag_of_target)

    def Get_WinningGPO(self,tag_of_target):
        return self._get_values_from_text(
            self._get_text_from_html(self._tables),target=tag_of_target,offset_idx=2)

    def GetAllSetting(self):
        lst_info_gpo = []

        for idx in range(0,self.Get_Item_Count()):
            item_html = self.Get_Item(index=idx)
            dicts = self._get_text_from_html(item_html)
            if len(dicts) % 3 == 0 and 'Policy' in dicts and 'Setting' in dicts and 'Winning GPO' in dicts:
                for idx_words in range(3,len(dicts),3): 
                    
                    setting_tag = dicts[idx_words]
                    setting_val = dicts[idx_words + 1]
                    setting_gpo = dicts[idx_words + 2]

                    info_gpo = INFO_GPO()
                    info_gpo.setPolicy(setting_tag)
                    info_gpo.setSetting(setting_val)
                    info_gpo.setWinning_GPO(setting_gpo)



                    lst_info_gpo.append(info_gpo)
        return lst_info_gpo

    def GetAllSettingsAsDataFrame(self):
        lst = []
        computer_name = self.get_current_computer_name()

        for item in self.GetAllSetting():
            lst_item = [computer_name]
            for val in item.toArray():
                lst_item.append(val)
            lst.append(lst_item)

        df = pd.DataFrame (lst, columns = ['ComputerName','Policy','Setting','Winning GPO'])
        return df


class PolicyComparator(object):
    _instance = None
    @staticmethod
    def get_instance():
        if PolicyComparator._instance is None:
            PolicyComparator()
        return PolicyComparator._instance

    def __init__(self):
        if PolicyComparator._instance is not None:
            raise Exception('only one instance can exist')
        else:
            PolicyComparator._instance = self
    
    def _get_float_from_setting(self,sources):
        val = [float(s) for s in re.findall(r'-?\d+\.?\d*', sources)]
        if len(val) > 0:
            return val[0]
        else:
            return None
    
    def get_compared_results(self,computer_settings:str,policy_settings:List,operation='=') -> bool: 
        IsPass = False
        for policy_setting in policy_settings:
            if operation == '>=':
                IsPass =True if self._get_float_from_setting(computer_settings) >= self._get_float_from_setting(policy_setting) else IsPass
            elif operation == '<=':
                IsPass =True if self._get_float_from_setting(computer_settings) <= self._get_float_from_setting(policy_setting) else IsPass
            # begin : The purpose of this code is performance optimization
            elif operation=='=': 
                IsPass = True if (computer_settings == policy_setting) else IsPass
            # endbegin
            elif operation=='!=' or operation =='<>': 
                IsPass = True if (computer_settings != policy_setting) else IsPass
            elif operation == '>':
               IsPass =True if self._get_float_from_setting(computer_settings) > self._get_float_from_setting(policy_setting) else IsPass
            elif operation == '<': 
                IsPass = True if self._get_float_from_setting(computer_settings) < self._get_float_from_setting(policy_setting) else IsPass
            else:
                IsPass = True if computer_settings == policy_setting else IsPass
        return IsPass