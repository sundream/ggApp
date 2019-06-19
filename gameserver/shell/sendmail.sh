if [ $# -lt 3 ];
then
	echo "usage: sh sendmail.sh 'mail_to' subject content mail_smtp mail_user mail_password"
fi
MAIL_CONTENT_FILE="/tmp/sendmail.txt"
MAIL_TO=$1
MAIL_SUBJECT=$2
MAIL_CONTENT=$3
MAIL_SMTP=$4
MAIL_USER=$5
MAIL_PASSWORD=$6
MAIL_FROM=$MAIL_USER
# 替换逗号为空格
MAIL_TO=`echo $MAIL_TO | sed 's/,/ /g'`
echo "From:${MAIL_FROM}
To:${MAIL_TO}
Subject: ${MAIL_SUBJECT}

${MAIL_CONTENT}" > ${MAIL_CONTENT_FILE}

for mailto in $MAIL_TO
do
	curl -s --url "${MAIL_SMTP}" --mail-from "${MAIL_FROM}" --mail-rcpt "${mailto}" \
		--upload-file ${MAIL_CONTENT_FILE} --user "${MAIL_USER}:${MAIL_PASSWORD}"
done
rm -rf ${MAIL_CONTENT_FILE}
