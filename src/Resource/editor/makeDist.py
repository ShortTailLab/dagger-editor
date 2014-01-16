#! /usr/bin/env python
# -*- coding: utf-8 -*-f

from oss_api import *
from oss_xml_handler import *
import os
import argparse
import subprocess
import shutil
import json
import hashlib
import gzip
from cStringIO import StringIO

OSS_ACCESS_KEY = "z7caZBtJU2kb8g3h"
OSS_ACCESS_PRIVATE_KEY = "fuihVj7qMCOjExkhKm2vAyEYhBBv8R"
BUCKET = "dagger-static"


def hashfile(afile, hasher, blocksize=65536):
    buf = afile.read(blocksize)
    while len(buf) > 0:
        hasher.update(buf)
        buf = afile.read(blocksize)
    return hasher.hexdigest()


def uploadAux(oss, filepath):
    if os.path.splitext(filepath)[1] in [".js", ".json"]:
        print 'Uploading', filepath, "\t Gzipped"
        gzipBuffer = StringIO()
        f_in = open(filepath, "rb")
        f_out = gzip.GzipFile(fileobj=gzipBuffer, mode="wb")
        f_out.writelines(f_in)
        f_in.close()
        f_out.close()
        oss.put_object_with_data(BUCKET, filepath, gzipBuffer.getvalue(), headers={'Content-Encoding': 'gzip'})
    else:
        print 'Uploading', filepath
        oss.put_object_from_file(BUCKET, filepath, filepath)


def upload(oss, path):
    for f in os.listdir(path):
        filePath = path + "/" + f
        if f.startswith("."):
            continue
        if os.path.isdir(filePath):
            upload(oss, filePath)
        else:
            uploadAux(oss, filePath)


def genVersionAux(versionTable, path, prefix):
    filePath = path
    if path.startswith(prefix + "/"):
        filePath = path[len(prefix) + 1:]
    versionTable[filePath] = {
        "d": prefix,
        "p": 0 if path.endswith(".js") else 1,
        "h": hashfile(open(path, "rb"), hashlib.md5())
    }

def genVersionDict(versionTable, path, prefix):
    for f in os.listdir(path):
        filePath = path + "/" + f
        if f.startswith(".") or f in ["version.json"]:
            continue
        if os.path.isdir(filePath):
            genVersionDict(versionTable, filePath, prefix)
        else:
            genVersionAux(versionTable, filePath, prefix)
    return versionTable


def genVersion(root):
    ret = {}
    with open(root+"/version.json", "w") as f:
        f.write(json.dumps(genVersionDict(ret, root, root)))


if __name__ == "__main__":
    oss = OssAPI("oss.aliyuncs.com", OSS_ACCESS_KEY, OSS_ACCESS_PRIVATE_KEY)

    parser = argparse.ArgumentParser()
    parser.add_argument("directory")
    parser.add_argument("prefix")
    args = parser.parse_args()

    shutil.copytree(args.directory, args.prefix)

    genVersion(args.prefix)
    upload(oss, args.prefix)

    print "removing directory " + args.prefix
    shutil.rmtree(args.prefix)
