#!/usr/bin/python
# -*- encoding: utf-8; py-indent-offset: 4 -*-
# +------------------------------------------------------------------+
# |             ____ _               _        __  __ _  __           |
# |            / ___| |__   ___  ___| | __   |  \/  | |/ /           |
# |           | |   | '_ \ / _ \/ __| |/ /   | |\/| | ' /            |
# |           | |___| | | |  __/ (__|   <    | |  | | . \            |
# |            \____|_| |_|\___|\___|_|\_\___|_|  |_|_|\_\           |
# |                                                                  |
# | Copyright Mathias Kettner 2013             mk@mathias-kettner.de |
# +------------------------------------------------------------------+
#
# This file is part of Check_MK.
# The official homepage is at http://mathias-kettner.de/check_mk.
#
# check_mk is free software;  you can redistribute it and/or modify it
# under the  terms of the  GNU General Public License  as published by
# the Free Software Foundation in version 2.  check_mk is  distributed
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;  with-
# out even the implied warranty of  MERCHANTABILITY  or  FITNESS FOR A
# PARTICULAR PURPOSE. See the  GNU General Public License for more de-
# ails.  You should have  received  a copy of the  GNU  General Public
# License along with GNU Make; see the file  COPYING.  If  not,  write
# to the Free Software Foundation, Inc., 51 Franklin St,  Fifth Floor,
# Boston, MA 02110-1301 USA.

#<<<microsoft_queues>>>

# microsoft_queues_default_levels = ( 1000, 1200 )
microsoft_queues_default_levels = {
        "messages" : (200,3000)
}

def inventory_microsoft_queues(info):
    return [ ( x[1], 'microsoft_queues_default_levels' ) for x in info  ]

def check_microsoft_queues(item, params, info):
    for messages, queue in info:
        if queue == item:
            warn, crit = params['messages']
            messages = saveint(messages)
            message = "%d Messages in Queue" % messages
            perf = [ ( "queue", messages, warn, crit ) ]
            if messages >= crit:
                return 2, message, perf
            if messages >= warn:
                return 1, message, perf
            return 0, message, perf

check_info["MSMQ"] = {
    "group"                 : "microsoft_mq",
    "check_function"        : check_microsoft_queues,
    "inventory_function"    : inventory_microsoft_queues,
    "service_description"   : "MSMQ",
    "has_perfdata"          : True,
}
