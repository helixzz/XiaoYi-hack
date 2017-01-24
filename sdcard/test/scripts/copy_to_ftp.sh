#!/bin/sh
# FTP_COPY version 0.3 by MP77V www.4pda.ru
# ----------------------------
ftp_dir="/"
ftp_host="NAS_IP"
ftp_port="FTP_PORT"
ftp_login="NAS_USER"
ftp_pass="NAS_PASS_User"
# ----------------------------

rec_dir="/tmp/hd1/record"
idx_tmp="/tmp/hd1/file_index.ftp"
idx_rec="/tmp/hd1/ftp_copy.idx"
ftp_log="/tmp/hd1/ftp_copy.log"
ftp_pid="/tmp/hd1/ftp_copy.pid"
ftp_debug="0"

dtm()
{
date '+%Y.%m.%d_%H:%M:%S'
}

wrk()
{
echo "$((`date '+%s'` - $1))"
}

mkd()
{
(sleep 1
echo "USER ${ftp_login}"
sleep 1
echo "PASS ${ftp_pass}"
sleep 1
echo "MKD ${ftp_dir}/$1"
sleep 1
echo "QUIT"
sleep 1 ) | telnet ${ftp_host} ${ftp_port}
}

cfg()
{
echo " [C]------------------------------"
echo " [C] ftp_dir=\"${ftp_dir}\""
echo " [C] ftp_host=\"${ftp_host}\""
echo " [C] ftp_port=\"${ftp_port}\""
echo " [C] ftp_login=\"${ftp_login}\""
echo " [C] ftp_pass=\"${ftp_pass}\""
echo " [C]------------------------------"
}

ftp_copy()
{
echo -e "\n$(dtm) [B] BEGIN `sed -e 's/^# //;2q;d;' $0`"
cfg

l=0
c=0
d=""
dir=""

cp_cmd="ftpput -u ${ftp_login} -p ${ftp_pass} -P ${ftp_port} ${ftp_host}"

while (sleep 30) ; do
l=$(($l + 1))
c=0
b="`date '+%s'`"
for f in `find ${rec_dir} -type f -name '*.mp4' -mmin -10 |grep -vf ${idx_tmp}` ; do
d="`dirname $f`"
d="${d##*\/}"
if [ "$d" != "$dir" ] ; then
if [ "${ftp_debug:-0}" == "1" ]; then
mkd ${d}
else
mkd ${d} &>/dev/null
fi
dir="${d}"
echo "$(dtm) [i] DIR: $d"
fi
echo -n "$(dtm) [i] copy: ${f} [`ls -l ${f}|awk '{ printf(\"%8d\",$5) }'` ] - "
$(${cp_cmd} "${ftp_dir}/${dir}/${f##*\/}" "${f}")
if [ "$?" == "0" ] ; then
echo "OK"
sed -i -e :a -e '$q;N;24,$D;ba' ${idx_tmp}
echo "${f}">>${idx_tmp}
c=$(($c + 1))
else
echo "$(dtm) [E] copy '${f}' ERROR"
fi
done
echo "$(dtm) [i] Loop ${l} copy ${c} wrk $(wrk $b) sec"
if [ "${c}" -gt 0 ]; then
cp -f ${idx_tmp} ${idx_rec}
fi
done
echo "$(dtm) Quit"
}

# begin

test -f ${idx_rec} || echo "#START#" >${idx_rec}
cp -f ${idx_rec} ${idx_tmp}
ftp_copy >>${ftp_log} 2>&1 &
echo $! >${ftp_pid}
echo "$(dtm) Start process [ $! ] - write log to file '${ftp_log}'"
exit 0
