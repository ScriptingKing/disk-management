#!/usr/bin/ksh

>hwm-host-vg.txt
DATE=`date "+%d-%m-%y-%H"`
>vg-reduce-$DATE.txt
echo "Hostname,VGName,Removed-Disks" > vg-reduce-$DATE.txt
count=`cat hwm.txt | wc -l`

i=1

while [ $i -le $count ]
        do
ip=`cat hwm.txt  | awk '{print $1}' | sed -n ${i}p`
lv=`cat hwm.txt  | awk '{print $2}' | sed -n ${i}p | awk -F '/' '{print $3}'`

vg=`ssh -t aixuser@$ip "lslv $lv" | sed -n 1p | awk '{print $6}'`

echo "$ip $vg" >> hwm-host-vg.txt
i=`expr $i + 1`
done
j=1
cat hwm-host-vg.txt | sort | uniq > hwm-host-vg-uniq.txt
countv=`cat hwm-host-vg-uniq.txt | wc -l`
while [ $j -le $countv ]
        do
host=`cat hwm-host-vg-uniq.txt | awk '{print $1}' | sed -n ${j}p`
vgg=`cat hwm-host-vg-uniq.txt | awk '{print $2}' | sed -n ${j}p`
echo "Executing for $host  $vgg"
echo "Press y/n"
                read ch
                        if [ "$ch" = "y" ] || [ "$ch" = "Y" ]
                        then
echo "#!/usr/bin/ksh" > vg-reduce-v2.sh
echo "vgname=$vgg" >> vg-reduce-v2.sh
cat vg-reduce-v2.copy.sh >> vg-reduce-v2.sh
strings  vg-reduce-v2.sh > vg-reduce-v2-final.sh
chmod 755 vg-reduce-v2-final.sh
scp vg-reduce-v2-final.sh rajtiw@$host:~/
ssh -t rajtiw@$host "./vg-reduce-v2-final.sh"
scp rajtiw@$host:~/hdd.txt .
countd=`cat hdd.txt | wc -l`
>info-disk.txt
h=1;
while [ $h -le $countd ]
        do
disk=`cat hdd.txt | awk '{print $1}' | sed -n ${h}p`
echo "$host" >> vg-reduce-$DATE.txt
echo "$vgg" >> vg-reduce-$DATE.txt
echo "$disk" >> vg-reduce-$DATE.txt
echo "" >> vg-reduce-$DATE.txt
h=`expr $h + 1`
done
else
exit
fi
j=`expr $j + 1`
done
cat vg-reduce-$DATE.txt  > vg-reduce-$DATE.csv
echo "Output file vg-reduce-$DATE.csv"
rajtiw@nastsm01:/u/rajtiw$ cat vg-reduce-v2-final.sh
#!/usr/bin/ksh
vgname=mqm01vg
######### Checking Free Disk
>hdd.txt
x="$vgname"
echo "executing for $x"
ans="y"
    while [ $ans = "y" ]
    do
lsvg -p $x | grep -v PV_NAME | grep -v "$x" > vginfo.txt
count=`cat vginfo.txt | wc -l`
i=1;
while [ $i -le $count ]
        do
        a=`cat vginfo.txt | awk '{print $1}' | sed -n ${i}p`
        h[$i]=$a
        b=`cat vginfo.txt | awk '{print $3}' | sed -n ${i}p`
        t[$i]=$b
        c=`cat vginfo.txt | awk '{print $4}' | sed -n ${i}p`
        f[$i]=$c
        i=`expr $i + 1`
        done
        h=1
        while [ $h -le $count ]
        do
                if [ ${t[$h]} = ${f[$h]} ]
                then
                echo "Free disk found It's going to remove ${h[$h]} of vg $x"
                echo "Press y/n"
                read ch
                        if [ "$ch" = "y" ] || [ "$ch" = "Y" ]
                        then
                        echo "removing"
                                        sudo reducevg  $x ${h[$h]}
echo "${h[$h]}" >> hdd.txt
                        else
                        echo "doing nothing"
                                        echo "null" >> hdd.txt
                        exit
                        fi
                fi
          h=`expr $h + 1`
        done
########### Extracting Remaining Disks Detail

echo "Second Thread"
echo "============="
        lsvg -p $x | grep -v PV_NAME | grep -v "$x"> vginfo.txt
        count=`cat vginfo.txt | wc -l`
                j=1
                while [ $j -le $count ]
                do
                a=`cat vginfo.txt | awk '{print $1}' | sed -n ${j}p`
                h[$j]=$a
                b=`cat vginfo.txt | awk '{print $3}' | sed -n ${j}p`
                t[$j]=$b
                c=`cat vginfo.txt | awk '{print $4}' | sed -n ${j}p`
                f[$j]=$c
                d=`expr ${t[$j]} - ${f[$j]}`
                u[$j]=$d
echo "disk ${h[$j]} used space ${u[$j]}"
                j=`expr $j + 1`
                done
echo "Total $count disks"

################ Finding disk with minimum used space

s=${u[1]}
sh="${h[1]}"
                k=2
                while [ $k -le $count ]
                do
                        if [ ${u[$k]} -lt $s ]
                        then
                        s=${u[$k]}
                        sh="${h[$k]}"
                        fi
                 k=`expr $k + 1`
                done
echo "min used space disk is $sh with size $s"
###### Extracting disks info except the disk with minimum used space
cat vginfo.txt | grep -v $sh > vginfo1.txt
count=`cat vginfo1.txt | wc -l`
                l=1
                while [ $l -le $count ]
                do
                a=`cat vginfo1.txt | awk '{print $1}' | sed -n ${l}p`
                h[$l]=$a
                c=`cat vginfo1.txt | awk '{print $4}' | sed -n ${l}p`
                f[$l]=$c
                l=`expr $l + 1`
               done
echo "Remaining disks with count $count"
#######  Finding disks with free space greater than the min used space disk
touch vginfo2.txt
>vginfo2.txt
                y=1
                while [ $y -le $count ]
               do
                        if [ ${f[$y]} -gt $s ]
                        then
                        cat vginfo1.txt | grep -w ${h[$y]} >> vginfo2.txt
                        fi
                 y=`expr $y + 1`
                done
############### Migrating the disk

count=`cat vginfo2.txt | wc -l`
echo "$count free space disks found"
                if [ $count -gt 1 ]
                then
                        m=1
                        while [ $m -le $count ]
                        do
                        a=`cat vginfo2.txt | awk '{print $1}' | sed -n ${m}p`
                        h[$m]=$a
                        c=`cat vginfo2.txt | awk '{print $4}' | sed -n ${m}p`
                        f[$m]=$c
                         m=`expr $m + 1`
                        done
s1=${f[1]}
sh1="${h[1]}"
                         n=2
                         while [ $n -le $count ]
                        do
                                if [ ${f[$n]} -lt $s1 ]
                                then
                                s1=${f[$n]}
                                sh1="${h[$n]}"
                                fi
                        n=`expr $n + 1`
                        done
echo "going to migrate $sh on  $sh1"
echo "Press y/n"
read ch
                        if [ "$ch" = "y" ] || [ "$ch" = "Y" ]
                        then
                                sudo migratepv $sh  $sh1
                                ans="y"
                        echo "loop continue"
                        else
                        echo "not migrating"
                        ans='n'
                        fi
                fi
                if [ $count -eq 1 ]
                then
                         a=`cat vginfo2.txt | awk '{print $1}' | sed -n 1p`
                        h[1]=$a
                sh1="${h[1]}"
                echo "going to migrate $sh  $sh1"
                echo "Press y/n"
                read ch
                        if [ "$ch" = "y" ] || [ "$ch" = "Y" ]
                        then
                        sudo migratepv $sh $sh1
                        ans='y'
                        echo "loop continue"
                        else
                        echo "Not migrating"
                        ans='n'
                        fi
                fi
                if [ $count -eq 0 ]
                then
echo "no disk found "
                ans='n'
                fi
echo "press enter to continue the loop"
read t
done
#echo "vg  $x done"
