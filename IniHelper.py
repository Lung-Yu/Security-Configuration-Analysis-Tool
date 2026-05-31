#-*- encoding: utf-8 -*-
'''
Created on 2021-03-18 01:54:45

@author: lungyu
'''
from enum import Enum
import configparser


class E_INI_Session(Enum):
    DATA = 'Data'
    RULE ="Rule"

class E_INI_KEY(Enum):
    # DATA 
    SOURCE_PATH = 'SourcePath'
    # RULE
    WINDOWS_FILE_NAME = "Windows"
    LINUX_FILE_NAME = "Linux"

class IniHelper:
    __instance = None
    @staticmethod
    def get_instance():
        if not IniHelper.__instance:
            IniHelper.__instance = IniHelper()
        return IniHelper.__instance

    def __init__(self,filename='settings.ini'):
        if IniHelper.__instance is not None:
            raise Exception('only one instance can exist')
        else:
            self._id = id(self)
            IniHelper.__instance = self

        self._config = configparser.ConfigParser()
        self._config.read(filename)
        pass

    def get_value(self,session,key):
        return self._config[session.value][key.value]
