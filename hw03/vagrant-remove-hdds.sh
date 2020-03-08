
export GUEST=testwirequard_node4
vboxmanage list hdds | sed -e '/./{H;$!d;}' -e 'x;/'"$GUEST"'/!d;' | grep UUID | egrep -v Parent| awk '{print $2}'

vboxmanage list hdds | sed -e '/./{H;$!d;}' -e 'x;/'"$GUEST"'/!d;'

vboxmanage storagectl --name 'SATA Controller' --portcount 1 --remove

UUIDS=`vboxmanage list hdds | sed -e '/./{H;$!d;}' -e 'x;/'"$GUEST"'/!d;'| grep UUID | egrep -v Parent| awk '{print $2}'`
for u in $UUIDS
do
 echo '--->> Deleteing: '$u
 vboxmanage closemedium disk $u --delete 
done