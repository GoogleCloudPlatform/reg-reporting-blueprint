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

"""Python script for converting a list of performance nodes into a DOT graph.

   Expected list of nodes is in JSON of the format:
     - List of objects
     - Each object having the following:
        - name - name of the node
        - depends_on - list of upstream dependencies (correponding to other
          nodes)
        - start_time - Javascript formatted timestamp when node started
        - end_time - Javascript formatted timestamp when node ended
"""

import os.path
import datetime
import sys
import argparse

import json


def clean_name(name):
    """ Turn a name into a valid dot node name """
    return name.replace('.','__').replace("-", "__")


def trim_names(nodes):
    """ Remove common prefixes from all graph names (DBT can be verbose!) """
    names = [n['name'] for n in nodes.values()]
    prefix = os.path.commonprefix(names)
    if prefix:
        for node in nodes.values():
            node['name'] = node['name'].removeprefix(prefix)


def find_critical_path(nodes):
    """ Identify the critical path and mark it red

        The critical path is the set of nodes whose time,
        if shorter, would result in the entire graph being
        having shorter term.
    """

    def find_last_node(ids):
        end_time = None
        node_id = None
        for node in ids:
            if end_time is None or nodes[node]["end_time"] > end_time:
                end_time = nodes[node]["end_time"]
                node_id = node

        return node_id

    # Start with all nodes
    upstream_nodes = nodes.keys()

    while True:

        # Find the last node to finish if possible
        last_node = find_last_node(upstream_nodes)
        if last_node is None:
            break

        # Mark as critical
        nodes[last_node]['critical'] = True

        # New upstream nodes
        upstream_nodes = nodes[last_node]['depends_on']



def find_real(nodes):
    """ Remove nodes that have no timing information

        DBT can have nodes that have no timing information
        and not actually run in the data warehouse (e.g.,
        ephemeral queries). These are removed from the graph,
        while preserving the overall dependency graph.
    """

    # Assumes no cycles in the graph!
    def expand_real(depends):
        new_depends = set()

        for dep in depends:

            # Source. We should have these in the graph!
            if not dep in nodes:
                continue

            if nodes[dep]["start_time"]:
                new_depends.add(dep)

            elif "real_depends_on" in nodes[dep]:
                new_depends.update(nodes[dep]["real_depends_on"])

            else:
                new_depends.update(expand_real(nodes[dep]["depends_on"]))

        return new_depends

    # Find the real depends_on
    for node in nodes.values():
        node["real_depends_on"] = expand_real(node["depends_on"])

    # Shift to actual depends_on
    for node in list(nodes.keys()):
        if not nodes[node]['start_time']:
            del nodes[node]
            continue
        nodes[node]['depends_on'] = nodes[node]['real_depends_on']
        del nodes[node]['real_depends_on']


def get_elapsed_time(secs):
    """ Turn absolute seconds into a readable time format """
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
    """ Convert incoming JSON node list into a set of
        python formatted dictionary.
    """
    nodes = {}
    for node in data:
        name = clean_name(node['name'])
        nodes[name] = {
            'name': node['name'],
            'start_time': None,
            'end_time': None,
            'depends_on': [clean_name(x) for x in node['depends_on']],
        }
        if node['end_time']:
            nodes[name]['end_time'] = (datetime.datetime
                                       .fromisoformat(node['end_time'])
                                       .timestamp())
        if node['start_time']:
            nodes[name]['start_time'] = (datetime.datetime
                                         .fromisoformat(node['start_time'])
                                         .timestamp())
    return nodes


def render_dot(nodes,
               left_right=False,
               seconds_per_block=1,
               fontsize=24,
               debug=False):
    """Render graph into a DOT graph

    Parameters
    ----------
    nodes : Nodes
        Node graph for rendering
    left_right : bool
        Whether to use left to right or top to bottom for query timelines
    seconds_per_block : int
        Number of seconds per block size
    fontsize : int
        Font size for nodes
    debug : bool
        Whether to produce a DOT graph that is debuggable
    """
    start_time = min([v["start_time"] for v in nodes.values() if v["start_time"]])
    end_time = max([v["end_time"] for v in nodes.values() if v["end_time"]])

    def find_block(time_stamp):
        return int(time_stamp - start_time) // seconds_per_block

    print("digraph {\n")
    print('newrank=true;')
    print('compound=true;')
    print(f'rankdir="{"LR" if left_right else "TB"}";')
    print('ranksep="equally";')
    print('overlap="false";')
    print(f'node [fontsize={fontsize}, shape = plaintext];')

    print('\n/* Timeline */\n')
    print('edge [style="invis"];')
    for blk in range(find_block(end_time)):
        print(f"{blk} -> {blk+1}")
        print(f"{blk} [label=\"{get_elapsed_time(blk * seconds_per_block)}\"] ")

    print('\n/* Main Styling */\n')
    print('edge [style="solid"];')
    if debug:
        print('node [shape="box"];')

    print('\n/* Main Data */\n')

    for node_id, node in nodes.items():

        print(f"subgraph cluster_{node_id} {{")
        print(f'  bgcolor="{"red" if "critical" in node else "steelblue1"}"')
        print("  style=\"rounded\"")

        # Find start and end time block for alignment
        start_align = find_block(node["start_time"])
        end_align = find_block(node["end_time"]) - 1

        if start_align < end_align:
            print(f"  {node_id}_start [fontsize={fontsize}, label=\"{node['name']}\" width=0]")
            print(f"  {node_id} [style=\"invis\" label=\"{node['name']}\"]")
        else:
            print(f"  {node_id} [fontsize={fontsize}, label=\"{node['name']}\"]")

        print("}")

        if start_align < end_align:
            print(f"{{ rank=same; {start_align} {node_id}_start }}")
            print(f"{{ rank=same; {end_align} {node_id} }}")
        else:
            print(f"{{ rank=same; {start_align} {node_id} }}")

        # Upstream dependencies
        for depends in node["depends_on"]:
            print(f"{depends} -> {node_id}{'_start' if start_align < end_align else ''} " +
                  f"[ltail=\"cluster_{depends}\" lhead=\"cluster_{node_id}\"]")

    print("}\n")


def main():
    """ Main for converting a dependency graph into a graphviz DOT formatted graph"""
    parser = argparse.ArgumentParser(description='Convert JSON performance graph to DOT graph')
    parser.add_argument('json_graph', nargs='?', type=argparse.FileType('r'),
                        default=sys.stdin)
    parser.add_argument('dot_graph', nargs='?', type=argparse.FileType('w'),
                        default=sys.stdout)
    parser.add_argument('--lr',
                        help='Left to right graph instead of top to bottom',
                        action='store_true')
    parser.add_argument('--debug',
                        help='Enable debug style DOT graph',
                        action='store_true')
    args = parser.parse_args()

    # Read in JSON
    data = json.load(sys.stdin)

    # Convert to a dictionary from a list
    nodes = json_to_dot_dict(data)

    # Find real nodes, trim names
    find_real(nodes)
    trim_names(nodes)

    find_critical_path(nodes)

    # Reader as a DOT graph
    render_dot(nodes, left_right=args.lr)


if __name__ == "__main__":
    main()
