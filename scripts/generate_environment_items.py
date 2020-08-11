#!/usr/bin/python
from subprocess import Popen, PIPE,STDOUT
import os
import subprocess
import logging
import string

log = logging.getLogger('UFW')
log_handler = logging.StreamHandler()
log_handler.setFormatter(logging.Formatter("%(name)s (" + os.environ['PLATFORM_NAME'] + "): %(levelname)s: %(message)s"))
log.addHandler(log_handler)
log.setLevel(logging.INFO)

log.info("running script...")

ignored = ['LD_MAP_FILE_PATH',
        'HEADER_SEARCH_PATHS',
        'LIBRARY_SEARCH_PATHS',
        'FRAMEWORK_SEARCH_PATHS']

build_root = os.environ['BUILD_ROOT']

temp_root = os.environ['TEMP_ROOT']
newenv = {}
f = open(os.environ['PROJECT_DIR']+"/build/build_environs.sh", "w")
for key, value in os.environ.items():
    if key not in ignored and not key.startswith('LINK_FILE_LIST_') and not key.startswith('LD_DEPENDENCY_'):
        if build_root in value or temp_root in value:
            f.write(key+"="+value+" ");

f.close()



