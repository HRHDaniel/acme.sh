#!/usr/bin/env sh

# Author: Daniel Harp
#
# Required Variables:
# export PORTUNITY_USER="ASDF1234ASDF1234"
# export PORTUNITY_API_KEY="CFCFCFCFCFCFCF"

########  Public functions #####################

PORTUNITY_API="https://wr.ispsuite.portunity.de/api/"

#Usage: dns_portunity_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_portunity_add() {
  fulldomain=$1
  txtvalue=$2
  _info "Adding Portunity DNS Record"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  if ! _portunity_rest "add" "$fulldomain" "$txtvalue"; then
    _err "Portunity add record failed"
    return 1
  fi

  _info "Add successful"
  return 0
}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_portunity_rm() {
  fulldomain=$1
  txtvalue=$2
  _info "Removing Portunity DNS Record"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  if ! _portunity_rest "delete" "$fulldomain" "$txtvalue"; then
    _err "Portunity delete record failed"
    return 1
  fi

  _info "Delete successful"
  return 0
}

####################  Private functions below ##################################
_portunity_rest() {
  action="$1"
  fulldomain="$2"
  txtvalue="$3"

  user_trimmed=$(printf "%s" "$PORTUNITY_USER" | tr -d '"')
  key_trimmed=$(printf "%s" "$PORTUNITY_API_KEY" | tr -d '"')
  authorization=$(printf "%s" "$user_trimmed:$key_trimmed" | _base64)
  export _H1="Authorization: Basic $authorization"

  data=$(printf 'data={"api":"product-dns","action": "%s","rrset": {"type": "TXT","name":"%s","ttl":30,"records":[{"content": "%s"}]}}' "$action" "$fulldomain" "txtvalue")

  _debug data "$data"
  response="$(_post "$data" "$PORTUNITY_API")"

  ret_cd="$?"
  if [ "$ret_cd" != "0" ]; then
    _err "Post to portunity failed. Return code: $ret_cd"
    return 1
  fi
  if _contains "$response" '"ok"'; then
    _err 'Response from Portunity did not include "ok".  Check error message in response.'
    _err "$response"
    return 1
  fi

  _debug2 "Response from Portunity: $response"
  return 0
}
