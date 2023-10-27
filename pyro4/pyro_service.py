#!/usr/bin/env python3
"""This file starts a pyro nameserver and the proxying server."""
from pathlib import Path
import subprocess
import time
import argparse

from qick.pyro import start_server

############
# parameters
############

proxy_name ='rfsoc'
ns_port = 8000
# set to 0.0.0.0 to allow access from outside systems
ns_host = 'localhost'

############

# parse command-line arguments
arg_parser = argparse.ArgumentParser(
    description='Start a pyro server for the QickSoc.'
)
arg_parser.add_argument(
    '-n',
    '--nameserver',
    action='store_true',
    help='start the pyro nameserver',
)
arg_parser.add_argument(
    '-p',
    '--proxy',
    action='store_true',
    help='start the pyro proxy server',
)
cmd_args = arg_parser.parse_args()

if cmd_args.nameserver:
    # start the nameserver process
    ns_proc = subprocess.Popen(
        [f'PYRO_SERIALIZERS_ACCEPTED=pickle PYRO_PICKLE_PROTOCOL_VERSION=4 pyro4-ns -n {ns_host} -p {ns_port}'],
        shell=True
    )
    if cmd_args.proxy:
        # wait for nameserver to start
        time.sleep(5)
    else:
        # loop forever
        while True:
            time.sleep(1)

if cmd_args.proxy:
    # start the qick proxy server
    start_server(
        proxy_name=proxy_name,
        ns_host='localhost',
        ns_port=ns_port
    )
