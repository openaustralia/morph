#!/bin/bash

# TODO Put this script somewhere more sensible

sudo ipfw add 100 fwd 127.0.0.1,8000 tcp from any to me 80
sudo ipfw add 101 fwd 127.0.0.1,8001 tcp from any to me 443
