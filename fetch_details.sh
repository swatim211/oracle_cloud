#!/bin/bash
oci=/opt/oracle-cli/bin/
compartmentid=%compartment-id%
oci_config=~/.oci/config

function setProxy(){
echo "setting Proxy.."
export http_proxy=http://proxy:3128
export https_proxy=http://proxy:3128
}

function region(){
region="$(awk "/region/" .oci/config | awk -F"=" '{print $2}')"
echo " All the details will be from the region ${region}, if you want details from some other region please update the OCI config file."
}

function getDetails(){
mkdir tmp

echo "Fetching Instance names..."
${oci}/oci compute instance list --compartment-id ${compartmentid} | awk "/\"display-name\"/" | awk -F"\"" '{print $4}' > tmp/instance_name.txt

echo "Fetching Instance shapes..."
${oci}/oci compute instance list --compartment-id ${compartmentid} | awk "/\"shape\"/" | awk -F"\"" '{print $4}' > tmp/instance_shape.txt

echo "Fetching VNIC IDs ofeach Instance..."
${oci}/oci compute instance list --compartment-id ${compartmentid} | awk "/\"id\"/" | awk -F"\"" '{print $4}' | while read line
do
 ${oci}/oci compute instance list-vnics --instance-id $line | awk "/\"id\"/" | awk -F"\"" '{print $4}' >> tmp/vnics.txt
done

echo "Fetching Private IPs of ech Instance..."
cat tmp/vnics.txt | while read line
do
 ${oci}/oci network private-ip list --vnic-id $line | awk "/\"ip-address\"/" | awk -F"\"" '{print $4}' >> tmp/privateip.txt
done

echo "Fetching Names of Block Volumes in the region..."
${oci}/oci bv volume list --compartment-id ${compartmentid} | awk "/\"display-name\"/" | awk -F"\"" '{print $4}' >> tmp/volumenames.txt

echo "Fetching Block Volumes size in the region..."
${oci}/oci bv volume list --compartment-id ${compartmentid} | awk "/\"size-in-gbs\"/" | awk -F":" '{print $2}' >> tmp/volumesize.txt
}

function createCsvFile(){
echo " Creating instanceDetails.csv containg Instance name, shape, and Private IP..."
paste -d, tmp/instance_name.txt tmp/instance_shape.txt tmp/privateip.txt > instanceDetails.csv

echo " Creating volumeDetails.csv comprising of BLock Volume names and sizes..."
paste -d, tmp/volumenames.txt tmp/volumesize.txt > volumeDetails.csv
}

function cleanup(){
rm -rf tmp
}

setProxy
region
getDetails
createCsvFile
cleanup
