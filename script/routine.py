#! /usr/bin/env python
# -*- coding: utf-8 -*-f

from oss_api import *
from oss_xml_handler import *
import os

OSS_ACCESS_KEY = "tu3b4nr7ofb87ndt66zf0qzp"
OSS_ACCESS_PRIVATE_KEY = "nq6HbBzhMvV47UVv6DTb88Fxe24="
BUCKET = "dagger-static"
PREFIX = "editor-script"

def header(str):
    return "\033[94m" + str + "\033[0m"

def upload(oss, filepath):
    print header("[UPLOAD]") +" "+ filepath
    dst = PREFIX + "/" + filepath
    src = filepath
    oss.put_object_from_file(BUCKET, dst, src)

if __name__ == "__main__":
    # upload
    oss = OssAPI("oss.aliyuncs.com", OSS_ACCESS_KEY, OSS_ACCESS_PRIVATE_KEY)

    upload(oss, "makeDist.py")
    upload(oss, "oss_api.py")
    upload(oss, "oss_util.py")
    upload(oss, "oss_xml_handler.py");