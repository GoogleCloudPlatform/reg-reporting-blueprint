#!/usr/bin/python3

# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import os.path
import datetime
import sys

import json

def clean_name(x):
    return x.replace('.','__').replace("-", "__")


#
# Remove common prefixes from the node names
#
def trim_names(nodes):
    names = [n['name'] for n in nodes.values()]
    prefix = os.path.commonprefix(names)
    if prefix:
        for n in nodes.values():
            n['name'] = n['name'].removeprefix(prefix)


#
# Find real dependencies
#
# This removes dependencies that have no start_time and finds
# the true upstream dependencies
#
def find_real(nodes):

    # Assumes no cycles in the graph!
    def expand_real(depends):
        new_depends = set()

        for d in depends:

            # Source. We should have these in the graph!
            if not d in nodes:
                continue

            if nodes[d]["start_time"]:
                new_depends.add(d)

            elif "real_depends_on" in nodes[d]:
                new_depends.update(nodes[d]["real_depends_on"])

            else:
                new_depends.update(expand_real(nodes[d]["depends_on"]))

        return new_depends

    # Find the real depends_on
    for k, v in nodes.items():
        v["real_depends_on"] = expand_real(v["depends_on"])

    # Shift to actual depends_on
    for n in list(nodes.keys()):
        if not nodes[n]['start_time']:
            del nodes[n]
            continue
        nodes[n]['depends_on'] = nodes[n]['real_depends_on']
        del nodes[n]['real_depends_on']


#
# Get human time
#
def get_elapsed_time(secs):
    secs = int(secs)
    hours = secs // 3600
    secs -= (hours * 3600)
    mins = secs // 60
    secs -= (mins * 60)
    if hours > 0:
        return f'{hours:2d}:{mins:02d}:{secs:02d}'
    if mins > 0:
        return f'{mins:2d}:{secs:02d}'
    return f'{secs:2d}'


def json_to_dot_dict(data):
    nd = {}
    for node in data:
        n = clean_name(node['name'])
        nd[n] = {
            'name': node['name'],
            'start_time': None,
            'end_time': None,
            'depends_on': [clean_name(x) for x in node['depends_on']],
        }
        if node['end_time']:
            nd[n]['end_time'] = datetime.datetime.fromisoformat(node['end_time'])
        if node['start_time']:
            nd[n]['start_time'] = datetime.datetime.fromisoformat(node['start_time'])
    return nd


def render_dot(d,
               seconds_per_block=1,
               FONTSIZE=24,
               DEBUG=False):

    start_time = min([v["start_time"] for v in d.values() if v["start_time"]])
    end_time = max([v["end_time"] for v in d.values() if v["end_time"]])
    elapsed = (end_time.timestamp() - start_time.timestamp())

    def find_block(ts):
        return int(ts - start_time.timestamp()) // seconds_per_block

    print("digraph {\n")
    print('newrank=true;')
    print('compound=true;')
    # TODO: Make this optionally LR as well (left to right)
    print('rankdir="TB";')
    print('ranksep="equally";')
    print('overlap="false";')

    print('\n/* Timeline */\n')
    print(f'node [fontsize={FONTSIZE}, shape = plaintext];')
    print('edge [style="invis"];')
    for blk in range(int(elapsed // seconds_per_block)):
        label=get_elapsed_time(blk * seconds_per_block)
        print(f"{blk} -> {blk+1}")
        print(f"{blk} [label=\"{label}\"] ")

    print('\n/* Main Styling */\n')
    print('edge [style="solid"];')
    if DEBUG:
        print('node [shape="box"];')

    print('\n/* Main Data */\n')

    sameranks = []
    dependencies = []


    for k, v in d.items():

        # Find start and end time block for alignment
        # NOTE: end_align is adjusted back by one to make boundaries easier to
        # see.
        start_align = find_block(v["start_time"].timestamp())
        end_align = find_block(v["end_time"].timestamp()) - 1

        print(f"subgraph cluster_{k} {{")
        if not DEBUG:
            print("  bgcolor=\"red\"")
        print("  style=\"rounded\"")
        label = v["name"]
        end_style = 'invis'
        if DEBUG:
            end_style = 'solid'
        if start_align != end_align:
            print(f"  {k}_start [fontsize={FONTSIZE}, label=\"{label}\" width=0]")
            sameranks.append(f"{{ rank=same; {start_align} {k}_start }}")
            print(f"  {k} [style=\"{end_style}\" label=\"{label}\"]")
            sameranks.append(f"{{ rank=same; {end_align} {k} }}")

            # Upstream dependencies
            for depends in v["depends_on"]:
                dependencies.append(f"{depends} -> {k}_start " +
                                    f"[ltail=\"cluster_{depends}\" lhead=\"cluster_{k}\"]")
        else:
            print(f"  {k} [fontsize=24, label=\"{label}\"]")
            sameranks.append(f"{{ rank=same; {start_align} {k} }}")
            # Upstream dependencies
            for depends in v["depends_on"]:
                dependencies.append(f"{depends} -> {k} " +
                                    f"[ltail=\"cluster_{depends}\" lhead=\"cluster_{k}\"]")
        print("}")


    print('\n/* Same ranks */\n')
    for r in sameranks:
        print(r)

    print('\n/* Dependencies */\n')
    for r in dependencies:
        print(r)

    print("}\n")

# Read in JSON
data = json.load(sys.stdin)

# Convert to a dictionary from a list
d = json_to_dot_dict(data)

# Find real nodes, trim names
find_real(d)
trim_names(d)

# Reader as a DOT graph
render_dot(d)
