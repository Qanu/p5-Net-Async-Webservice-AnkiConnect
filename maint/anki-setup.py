#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# See <https://github.com/krassowski/anki_testing>
import os

ANKI_LIB = '/usr/share/anki'
ANKI_ADDONS_PATH = os.path.join(
  os.path.expanduser('~'),
  'Documents/Anki/addons')

import sys
import warnings
import tempfile
import shutil
import argparse

sys.path.append(ANKI_LIB)
sys.path.append(ANKI_ADDONS_PATH)

import anki
import aqt
from aqt import _run
from aqt.profiles import ProfileManager

def argparser():
  parser = argparse.ArgumentParser(description='Set up Anki')
  required = parser.add_argument_group('required arguments')
  required.add_argument('--base', help='Base directory for Anki', required=True)
  required.add_argument('--profile', help='User profile name', required=False)

  return parser

def temporary_user(dir_name, name="__Temporary Test User__", lang="en_US"):
  # prevent popping up language selection dialog
  original = ProfileManager._setDefaultLang

  def set_default_lang(profileManager):
    profileManager.setLang(lang)

  ProfileManager._setDefaultLang = set_default_lang

  pm = ProfileManager(base=dir_name)

  pm.setupMeta()

  if name in pm.profiles():
    warnings.warn("Temporary user named {name} already exists")
  else:
    pm.create(name)

  pm.name = name

  ProfileManager._setDefaultLang = original

  return name



def main():
  parser = argparser();
  args = parser.parse_args()

  dir_name = args.base
  if args.profile:
    user_name = temporary_user( dir_name, name = args.profile )
  else:
    user_name = temporary_user( dir_name )

  app = _run(argv=["anki", "-p", user_name, "-b", dir_name], exec=False)

  # clean up what was spoiled
  aqt.mw.cleanupAndExit()

  # remove hooks added during app initialization
  from anki import hooks
  hooks._hooks = {}

  # test_nextIvl will fail on some systems if the locales are not restored
  import locale
  locale.setlocale(locale.LC_ALL, locale.getdefaultlocale())


if __name__ == "__main__":
  main()
