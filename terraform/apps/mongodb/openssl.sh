#!/bin/bash

KEY=`openssl rand -base64 756`

echo {\"key\": \"$KEY\"}
