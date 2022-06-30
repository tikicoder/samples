set -e


echo "rg ${AZURE_STORAGE_RG}"
echo "account-name ${AZURE_STORAGE_NAME}"
echo "name ${AZURE_STORAGE_CONTAINER}"

echo "AZURE_TENANT_ID ${AZURE_TENANT_ID}"
echo "AZURE_APP_ID ${AZURE_APP_ID}"
echo "AZURE_APP_ID ${AZURE_SUBSCRIPTION_ID}"

startSAS=$(date -u -d "-30 minutes" '+%Y-%m-%dT%H:%MZ')
endSAS=$(date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ')

az login --service-principal -t "${AZURE_TENANT_ID}" -u "${AZURE_APP_ID}" -p "${AZURE_PASSWORD} "
az account set --subscription="${AZURE_SUBSCRIPTION_ID}"

accountKey=$(az storage account keys list -g "$AZURE_STORAGE_RG" -n "$AZURE_STORAGE_NAME" -otsv | grep key1 | awk '{print $3}')

storageSASTokenRaw=$(az storage container generate-sas --account-name "$AZURE_STORAGE_NAME" --name "$AZURE_STORAGE_CONTAINER" --expiry "$endSAS" --start "$startSAS" --account-key "${accountKey}" --https-only --permissions rcwd --out tsv)

STATIC_WEBSITE_DESTINATION="https://${AZURE_STORAGE_NAME}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}"
AZURE_STORAGE_SAS_TOKEN="?${storageSASTokenRaw}"

pushd $(dirname $0)
chmod 755 ./azcopy


buildPath=$(realpath $(dirname $0)/../build)

echo "buildPath: $buildPath"
echo "destination: $STATIC_WEBSITE_DESTINATION"
ls -la

./azcopy cp "${buildPath}/*" "${STATIC_WEBSITE_DESTINATION}${AZURE_STORAGE_SAS_TOKEN}" --overwrite=true --recursive
az cdn endpoint purge --resource-group "${AZURE_CDN_RG}" --profile-name "${AZURE_CDN_PROFILE}" --name "${AZURE_CDN_ENDPOINT}" --content-paths '/'

popd

az logout
