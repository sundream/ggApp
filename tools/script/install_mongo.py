#coding: utf8

import sys
import io
import optparse
import os
import json

def has_install_version(version):
   cmd = "mongod --version"
   fd = os.popen(cmd)
   line = fd.read()
   fd.close()
   if line.find("v"+version) >= 0:
       return True
   else:
       return False

def install(download_url,install_path,db_path):
    db_path = os.path.abspath(db_path)
    install_path = os.path.abspath(install_path)
    program = os.path.basename(download_url)
    # a-b-c.tar.gz
    ext = ".tgz"
    program = program.replace(ext,"")
    filename = "%s/%s%s" % (install_path,program,ext)
    if sys.platform.startswith("linux"):
        platform = "linux"
    elif sys.platform.startswith("darwin"):
        platform = "macosx"
    else:
        raise Exception("invalid platform %s" % (sys.platform))
    cmds = []
    if not os.path.isfile(filename):
        cmds = [
            "mkdir -p %s" % (install_path),
            "cd %s && curl -R -O %s" % (install_path,download_url),
            "cd %s && tar -zxvf %s%s" % (install_path,program,ext),
        ]
    if platform == "macosx":
            cmds.append("sudo install %s/%s/bin/* /usr/local/bin" % (install_path,program.replace("-ssl","")))
    else:
        #linux
        cmds.append("sudo install %s/%s/bin/* /usr/local/bin" % (install_path,program))

    result = 0
    for cmd in cmds:
        print(cmd)
        result = os.system(cmd)
        if result != 0:
            break
    old = "$WORKDIR/db"
    new = db_path
    mongo_config_path = os.path.join(db_path,"mongodb")
    for root,dirs,files in os.walk(mongo_config_path):
        for filename in files:
            if filename != "mongodb.conf":
                continue
            abs_filename = os.path.join(root,filename)
            fd = io.open(abs_filename,"rb")
            content = fd.read()
            fd.close()
            content = content.replace(old,new)
            fd = io.open(abs_filename,"wb")
            fd.write(content)
            fd.close()
    return result == 0

def main():
    usage = u'''usage: python %prog [options]
    e.g: python %prog --soft_version=版本 --install_path=安装路径 --db_path=db路径
    '''
    parser = optparse.OptionParser(usage=usage,version="%prog 0.0.1")
    parser.add_option("-s","--soft_version",help=u"[optional,default=%default] 版本",default="4.0.5")
    parser.add_option("-i","--install_path",help=u"[optional,default=%default] 安装路径",default="./install")
    parser.add_option("-d","--db_path",help=u"[optional,default=%default] db路径",default="./db")
    options,args = parser.parse_args()
    soft_version = options.soft_version
    install_path = options.install_path
    db_path = options.db_path
    if sys.platform.startswith("linux"):
        download_url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-%s.tgz" % (soft_version)
    elif sys.platform.startswith("darwin"):
        download_url = "https://fastdl.mongodb.org/osx/mongodb-osx-ssl-x86_64-%s.tgz" % (soft_version)

    if has_install_version(soft_version):
        print("already install %s" % soft_version)
        return
    succ = install(download_url,install_path,db_path)
    if not succ:
        print("install fail")
    else:
        print("install success")

if __name__ == "__main__":
    main()

