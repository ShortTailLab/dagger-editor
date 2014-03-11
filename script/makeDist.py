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
import thread
from cStringIO import StringIO

BUCKET = "dagger-static"

CLIENT_DIRECTORIES = ["ccbi", "res", "src"]
VERSION_FILE = "CLIENT-VERSION.json"
IS_MERGE = True

# utils 
def hashfile(afile, hasher, blocksize=65536):
    buf = afile.read(blocksize)
    while len(buf) > 0:
        hasher.update(buf)
        buf = afile.read(blocksize)
    return hasher.hexdigest()

def gzipFile(filepath):
    gzipBuffer = StringIO()
    f_in = open(filepath, "rb")
    f_out = gzip.GzipFile(fileobj=gzipBuffer, mode="wb", mtime=1388534400)
    f_out.writelines(f_in)
    f_in.close()
    f_out.close()
    return gzipBuffer

# upload files
def uploadAux(oss, filepath):
    if os.path.splitext(filepath)[1] in [".js", ".json"]:
        gzipBuffer = gzipFile(filepath)
        hash = hashlib.md5(gzipBuffer.getvalue()).hexdigest().upper()
        if oss.head_object(BUCKET, filepath, headers={"If-None-Match": hash}).status in [200, 404]:
            # print 'Uploading', filepath, "\t Gzipped"
            oss.put_object_with_data(BUCKET, filepath, gzipBuffer.getvalue(), headers={'Content-Encoding': 'gzip'})
            return True
        else:
            # print 'Skipping', filepath
            return False
    else:
        hash = hashfile(open(filepath, "rb"), hashlib.md5()).upper()
        if oss.head_object(BUCKET, filepath, headers={"If-None-Match": hash}).status in [200, 404]:
            # print 'Uploading', filepath
            oss.put_object_from_file(BUCKET, filepath, filepath)
            return True
        else:
            # print 'Skipping', filepath
            return False

#
## useless ?..
def compareVersion( oss, tag ):
    path = tag + "/" + VERSION_FILE
    gzipBuffer = gzipFile(path)
    hash = hashlib.md5(gzipBuffer.getvalue()).hexdigest().upper()
    return oss.head_object(BUCKET, path, headers={"If-None-Match": hash}).status in [200, 404]

## filter invalid directories in root
def genAndWriteLocalVersion( root, tag ):
    version = {}

    for item in os.listdir( root ):
        filepath = root + "/" + item
        if not os.path.isdir( filepath ) :
            continue
        if item in CLIENT_DIRECTORIES:
            genLocalVersion2( filepath, tag, version )

    with open( root+"/"+VERSION_FILE, "w" ) as f:
        f.write( json.dumps(version) )

    if not IS_MERGE: return version

    remoteVersion = oss.get_object(BUCKET, tag+"/"+VERSION_FILE)
    if remoteVersion.status == 200:
        gzipBuffer = StringIO(remoteVersion.fp.read())
        g_in = gzip.GzipFile(fileobj=gzipBuffer, mode="rb")
        remoteVersion = json.loads(g_in.read())
        for k,v in remoteVersion.iteritems():
            if k not in version:
                version[k] = remoteVersion[k]

    return version


## generate version for every valid file
def genLocalVersion2( root, tag, table ):
    for item in os.listdir(root):
        filepath = root + "/" + item
        if item.startswith(".") or item in [VERSION_FILE]:
            continue
        if os.path.isdir(filepath):
            genLocalVersion2( filepath, tag, table )
        else:
            subpath = filepath
            if filepath.startswith( tag+"/" ):
                subpath = filepath[ len(tag)+1: ]
            table[subpath] = {
                "d": tag,
                "p": 0 if filepath.endswith(".js") else 1,
                "h": hashfile(open(filepath, "rb"), hashlib.md5())
            }


# task dispatch in mult-threads
def header(str):
    return "[\033[94m" + str + "\033[0m]"

def wrapper(oss, filepath, handler):
    handler(uploadAux(oss, filepath), filepath)

total, count, connection = 0, 0, 0

lock = thread.allocate_lock()
def sync_print( str ):
    lock.acquire()
    print str
    lock.release()

def after( has_upload, filepath ):
    global connection, count, total

    connection -= 1
    count += 1
    if has_upload: prefix = header("上传")
    else: prefix = header("跳过")
    sync_print(prefix+"\t"+str(count)+"/"+str(total)+"("+str(int(count*100/total))+"%)\t"+filepath)

def dispatcher(oss, version, tag, limit):
    global connection, total, count

    total = len( version )
    for item in version:
        filepath = tag + "/" + item
        while( True ):
            if connection < limit:
                connection += 1
                thread.start_new( wrapper, (oss, filepath, after) )
                break
            time.sleep(0.16)

    while( True ):
        if count == total: return

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("directory")
    parser.add_argument("tag")
    parser.add_argument("target")
    parser.add_argument("version")
    parser.add_argument("key")
    parser.add_argument("token")
    parser.add_argument("-m", "--merge", default=True)

    args = parser.parse_args()
    oss = OssAPI("oss.aliyuncs.com", args.key, args.token);
    
    VERSION_FILE = args.version
    CLIENT_DIRECTORIES = [args.target]
    IS_MERGE = args.merge

    shutil.copytree(args.directory, args.tag)
    try:

        version = genAndWriteLocalVersion( args.tag, args.tag )
        dispatcher( oss, version, args.tag, 32 )
        # finnally, upload version file
        uploadAux( oss, args.tag+"/"+VERSION_FILE )

    finally:
        print "removing directory " + args.tag
        shutil.rmtree(args.tag)
