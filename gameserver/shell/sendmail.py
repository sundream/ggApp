#coding=utf-8
import sys
import types
import smtplib
from email.mime.text import MIMEText

def sendmail(to_list,subject,content,mail_smtp,mail_user,mail_password):
    me = mail_user
    msg = MIMEText(content,_subtype="plain",_charset="utf-8")
    msg["Subject"] = subject
    msg["From"] = me
    msg["To"] = to_list
    if type(to_list) == types.ListType:
            msg["To"] = ",".join(to_list)
    if type(to_list) == str:
        to_list = to_list.split(",")
    try:
       print "start connect"
       #server = smtplib.SMTP(mail_smtp,25)
       server = smtplib.SMTP_SSL(mail_smtp,465)
       print "connect ok"
       server.login(mail_user,mail_password)
       print "login ok"
       server.sendmail(me,to_list,msg.as_string())
       print "sendmail ok"
       server.close()
       return True
    except Exception,e:
       print(e)
       return False

if __name__ == "__main__":
    if len(sys.argv) != 7:
        print "usage: python sendmail.py 'to_list' subject content mail_smtp mail_user mail_password"
        exit(0)
    sendmail(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5],sys.argv[6])
