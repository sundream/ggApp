#coding=utf-8
import sys
import types
import smtplib
from email.mime.text import MIMEText

def sendmail(to_list,subject,content):
    mail_host = "smtp主机"
    mail_user = "邮箱账号"
    mail_pass = "邮箱密码"
    me = "发件人邮箱" 
    msg = MIMEText(content,_subtype="plain",_charset="utf-8")
    msg["Subject"] = subject
    msg["From"] = me
    msg["To"] = to_list
    if type(to_list) == types.ListType:
            msg["To"] = " ".join(to_list)
    if type(to_list) == str:
        to_list = to_list.split()
    try:
       server = smtplib.SMTP()
       #print "start connect"
       server.connect(mail_host)
       #print "connect ok"
       server.login(mail_user,mail_pass)
       #print "login ok"
       server.sendmail(me,to_list,msg.as_string())
       #print "sendmail ok"
       server.close()
       return True
    except Exception,e:
       #print(e)
       return False

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print "usage: python sendmail.py 'to_list' subject content"
        exit(0)
    sendmail(sys.argv[1],sys.argv[2],sys.argv[3])
