#!/bin/sh
# Copyright (c) 2015, John Ko
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
######################################################################
# Script version is yymmdd-HHMMSS in UTC, date +%y%m%d-%H%M%S
######################################################################
SCRIPTVERSION=150105-031846


APIKEY=

test_for_git() {
  if ! which git >/dev/null 2>&1; then
    echo "git command not found."
    exit 1
  fi
}

list_all_repos() {
  if ! which curl >/dev/null 2>&1; then
    echo "curl command not found."
    exit 1
  fi
  if [ -z "${APIKEY}" ]; then
    echo "APIKEY not set."
    exit 1
  else
    curl -u ${APIKEY}:x-oauth-basic https://api.github.com/user/repos | grep clone_url >.user.repos.clone_url.txt
    curl -u ${APIKEY}:x-oauth-basic https://api.github.com/user/orgs | grep repos_url >.user.orgs.repos_url.txt
  fi
  [ -e .all.repos.clone_url.txt ] && rm .all.repos.clone_url.txt
  if [ -e .user.repos.clone_url.txt ]; then
    cat .user.repos.clone_url.txt >>.all.repos.clone_url.txt
  fi
  if [ -e .user.orgs.repos_url.txt ]; then
    [ -e .user.orgs.repos.clone_url.txt ] && rm .user.orgs.repos.clone_url.txt
    cat .user.orgs.repos_url.txt | while read line ; do
      url=`echo $line | awk '{print $2}' | awk -F, '{print $1}' | tr -d '"'`
      curl -u ${APIKEY}:x-oauth-basic $url | grep clone_url >>.user.orgs.repos.clone_url.txt
    done
    if [ -e .user.orgs.repos.clone_url.txt ]; then
      cat .user.orgs.repos.clone_url.txt >>.all.repos.clone_url.txt
    fi
  fi
  if [ -e .all.repos.clone_url.txt ]; then
    cat .all.repos.clone_url.txt | while read line ; do
      echo $line | awk '{print $2}' | awk -F, '{print $1}' | tr -d '"'
    done
  fi
}

clone_all_repos() {
  test_for_git
  [ -e .error_cloning.txt ] && rm .error_cloning.txt
  list_all_repos | while read line; do
    git clone $line || echo $line >>.error_cloning.txt
  done
  if [ -e .error_cloning.txt ]; then
    echo "Error cloning the following:"
    cat .error_cloning.txt
  fi
}

pull_all_folders() {
  test_for_git
  parentdir=`pwd`
  [ -e .error_pulling.txt ] && rm .error_pulling.txt
  find . -maxdepth 1 -type d | while read line; do
    cd $line && git pull || echo $line >>.error_pulling.txt
    cd $parentdir
  done
  if [ -e .error_pulling.txt ]; then
    echo "Error pulling the following:"
    cat .error_pulling.txt
  fi
}

########## This is called in clone_all_repos
#list_all_repos

clone_all_repos
pull_all_folders
