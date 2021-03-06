#!/usr/bin/python
#
#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# This script accepts a json dump via stdin that was generated by calling the
# rabbitmq /api/definitions endpoint. It then removes the queues, bindings and
# exchanges that should not be restored if the dump was loaded and prints
# the json back out to stdout.
#

import json
import sys

defs = json.loads(sys.stdin.read())

newqueues = []
allqueues = set()

# delete all auto-delete queues
for queue in defs['queues']:
    if not queue['auto_delete']:
        newqueues.append(queue)
        allqueues.add(queue['name'])

newbindings = []
allsources = set()

# delete all bindings pointing to auto-delete queues
for binding in defs['bindings']:
    if binding['destination'] in allqueues:
        newbindings.append(binding)
        allsources.add(binding['source'])

newexchanges = []

# delete all exchanges which were left without bindings
for exchange in defs['exchanges']:
    if exchange['name'] in allsources:
        newexchanges.append(exchange)

defs['queues'] = newqueues
defs['bindings'] = newbindings
defs['exchanges'] = newexchanges

print(json.dumps(defs))
