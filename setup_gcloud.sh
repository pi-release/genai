#!/bin/bash

set -e

CURR_DIR="$(cd $(dirname $0); pwd)"
TMP_WORKDIR="$CURR_DIR/tmp_download"
mkdir -p "$TMP_WORKDIR"

# manual download and install
# https://cloud.google.com/sdk/docs/install

export PROJECT_ID=${PROJECT_ID:=""}

# x86_64
GCLOUD_CLI_X86="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-473.0.0-darwin-x86_64.tar.gz"
GCLOUD_CLI_X86_SHA256="9ddd90144a004d9ff630781e9b8f144c21b2cea8fb45038073b7fb82399ed478"
# arm64
GCLOUD_CLI_ARM="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-473.0.0-darwin-arm.tar.gz"
GCLOUD_CLI_ARM_SHA256="4b534bf60585b6f6918daf0feeb0b68b39a689a794404e5a4f8fd8ce844de31c"
DOWNLOAD_URL=""
DOWNLOAD_FNAME="google-cloud-cli-473.0.0-darwin.tar.gz"
MARCH=$(uname -m)
# Pre-defined roles for vertex/gen AI services, probably too much, fine tune it yourself
GROLES=("aiplatform.serviceAgent" "notebooks.serviceAgent" "iam.serviceAccountKeyAdmin" "iam.serviceAccountUser")
DEFAULT_DEMO_SA_ACCOUNT="gemini-15-demo"
FLAGS_SKIPDOWNLOAD=false

function Usage() {
  printf "%s\n" "Usage:"
  printf "\n"
  printf "  $0 [-hds]\n"
  printf "     [-h] optional. print this help menu\n"
  printf "     [-d] optional. skip google-cloud-sdk download and instllation to save time if you already did it\n"
  printf "     [-s] optional. specify a different demo GCP serviceaccount name. default is gemini-15-demo\n"
  printf "\n"
  printf "  Runs everything, download, extract, create Google IAM/service-account, etc.\n"
  printf "  $0 \n"
  printf "\n"
  printf "  Runs everything except \"download and extract\", gcloud should be ready locally already. Still create Google IAM/service-account, etc.\n"
  printf "  $0 -d \n"
  printf "\n"
  printf "  Runs everything and apply your customized service account name, only allow format [a-zA-Z0-9\-], e.g. sa-abc-xyz \n"
  printf "  $0 -s sa-abc-xyz\n"
  exit 1
}

while getopts "hds:" opt; do
  case ${opt} in
    d)
      FLAGS_SKIPDOWNLOAD="true"
      ;;
    s)
      DEFAULT_DEMO_SA_ACCOUNT="${OPTARG}"
      echo "Applying different service account name $DEFAULT_DEMO_SA_ACCOUNT"
      ;;
    h)
      Usage
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      Usage
      ;;
  esac
done

function collect_info() {
  if [ "$MARCH" = "x86_64" ] ; then
    echo "Downloading x86_64 version"
    DOWNLOAD_URL="$GCLOUD_CLI_X86"
    CHECKSUM="$GCLOUD_CLI_X86_SHA256"
  elif [ "$MARCH" = "arm64" ] ; then
    echo "Downloading arm64 version"
    DOWNLOAD_URL="$GCLOUD_CLI_ARM"
    CHECKSUM="$GCLOUD_CLI_ARM_SHA256"
  else
    echo "$MARCH not yet added or implemented here, hack this script if you want by changing the URLs above."
    exit -1
  fi
}

function download_verify() {
  local outputfile=$1
  local sha256str=$2
  local url=$3

  echo "$sha256str  $outputfile" > "$outputfile.sha256"

  if [ -f "$outputfile" ] ; then
    shasum -a 256 -c "$outputfile.sha256"
    ret=$?
  else
    curl --progress-bar --fail -Lo "$outputfile" "$url"
    ret=$?
  fi
  return $?
}

function extract_binary() {
  local ext_file=$1
  local ext_dir=$2

  tar -xzf $ext_file -C $ext_dir
}

# Just following https://cloud.google.com/docs/authentication/provide-credentials-adc#local-dev
function init_gcloud() {
  local gcloud_cli=$1
  local project_id=$2
  local sa_account=$3
  local keyfile="$sa_account.json"

  if [ "x${project_id}" = "x" ] ; then
    project_id=$($gcloud_cli config get-value project 2>/dev/null)
    if [ "x${project_id}" = "x" ] ; then
      echo "PROJECT_ID cannot be empty. \"export PROJECT_ID=<YOUR_PROJECT_ID>\""
      exit -2
    else
      echo "Applying default $project_id from your default settings. Override with export PROJECT_ID=<YOUR_NEW_PROJETC_ID>"
    fi
  fi
  # $gcloud_cli auth application-default login
  # $gcloud_cli init
  is_sa_exist=$($gcloud_cli iam service-accounts list --format='value(displayName)' --filter=displayName:$sa_account 2>/dev/null)
  if [ "x${is_sa_exist}" = "x$sa_account" ] ; then
    echo "Skip $sa_account creation since it already exist. If you want to delete it, delete it manually with \"gcloud iam service-accounts delete $sa_account\""
  else
    $gcloud_cli iam service-accounts create $sa_account \
      --project=$project_id \
      --description="Gemini 1.5 Pro demo via Vertex API 20240401" \
      --display-name="$sa_account"
  fi

  sa_id_email=$($gcloud_cli iam service-accounts list --format='value(email)' --filter=displayName:$sa_account 2>/dev/null)

  current_iam_bindings=$($gcloud_cli projects get-iam-policy $project_id \
    --flatten="bindings[].members" \
    --format='table(bindings.role)' \
    --filter="bindings.members:$sa_account")
  echo "Current $project_id iam bindings for $sa_account is: $current_iam_bindings"

  # customize it as you see fit. this probably grant too much permission, finegrain tuning it yourself.
  # to see full list of roles - "gcloud iam roles list"
  for role in "${GROLES[@]}"
  do
    $gcloud_cli iam service-accounts add-iam-policy-binding $sa_id_email \
      --member=serviceAccount:$sa_id_email \
      --role=roles/$role
    $gcloud_cli projects add-iam-policy-binding $project_id --condition=None \
      --member=serviceAccount:$sa_id_email \
      --role=roles/$role
  done

  $gcloud_cli projects get-iam-policy $project_id \
    --flatten="bindings[].members" \
    --format='table(bindings.role)' \
    --filter="bindings.members:$sa_account"

  # Produce the key json file for GOOGLE_APPLICATION_CREDENTIALS
  $gcloud_cli iam service-accounts keys create $keyfile \
    --iam-account=$sa_id_email
  goog_api_key=$($gcloud_cli services api-keys create \
    --display-name=$sa_account \
    --project=$project_id 2>&1 | grep -o "keyString.*" | cut -d: -f2 | tr -d '"' | sed 's/.$//')
  echo "Your GOOGLE_API_KEY=$goog_api_key"
  return 0
}

function main() {
  collect_info
  if [ "x${FLAGS_SKIPDOWNLOAD}" = "xfalse" ] ; then
    download_verify "$TMP_WORKDIR/$DOWNLOAD_FNAME" "$CHECKSUM" "$DOWNLOAD_URL"
    extract_binary "$TMP_WORKDIR/$DOWNLOAD_FNAME" "$TMP_WORKDIR"
  else
    echo "Validating previous setup, we still need everything in $TMP_WORKDIR from previous download and extract!"
    if [ ! -f "$TMP_WORKDIR/google-cloud-sdk/bin/gcloud" ] ; then
      echo "Previous setup is broken, please re-run $0 WITHOUT -d option, re-download and extract google-cloud-sdk again! Exiting!"
    fi
  fi

  # the directory should have a fix name google-cloud-sdk
  init_gcloud "$TMP_WORKDIR/google-cloud-sdk/bin/gcloud" "" "$DEFAULT_DEMO_SA_ACCOUNT"

  echo "GOOGLE_APPLICATION_CREDENTIALS key file is stored in $CURR_DIR/$DEFAULT_DEMO_SA_ACCOUNT.json"
}

main

exit 0



