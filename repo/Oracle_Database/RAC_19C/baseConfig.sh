#!/bin/bash
# Purpose :  This script is a base script to all the mail scripts
# Date : 29 Dec 2018
# Author : DJ

FCGreen="\033[32m"
FCYellow="\033[33m"
FCRed="\033[31m"
FCNoColor="\033[m"
FCBold="\033[1m"

successLogs=/tmp/$0.success.log
failureLogs=/tmp/$0.error.log


echo "--------------------------------------------------------------------------------------------------------------------------------" >> $successLogs
date >> $successLogs


echo "--------------------------------------------------------------------------------------------------------------------------------" >> $failureLogs
date >> $failureLogs


