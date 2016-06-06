########
# Copyright (c) 2014 GigaSpaces Technologies Ltd. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#    * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    * See the License for the specific language governing permissions and
#    * limitations under the License.

from cloudify.decorators import workflow, operation
from cloudify import ctx
import os


#@workflow
#def config_hss(ctx,**kwargs):
#    dns_ip = ctx.target.instance.host_ip
#    ctx.source.instance.runtime_properties['work_with_dns'] = dns_ip
#    s = 'nameserver {}'.format(dns_ip)
#    ctx.logger.info("DNS SETUP {}".format(dns_ip))
#    os.system("echo '{}' | sudo tee /etc/dnsmasq.resolv.conf".format(s))
#    os.system("echo 'RESOLV_CONF=/etc/dnsmasq.resolv.conf' | sudo tee -a /etc/default/dnsmasq")
#    os.system("sudo service dnsmasq restart")


@workflow
def config_dns(ctx, endpoint, **kwargs):
    # setting node instance runtime property
    ctx.logger.info('workflow parameter: {0}'.format(endpoint['ip_address']))
    
    nodes = ['bono_app', 'ellis_app', 'homer_app', 'homestead_app', 'ralf_app', 'sprout_app']
    graph = ctx.graph_mode()
    for node in ctx.nodes:
        ctx.logger.info('In node: {0}'.format(node.id))
        if node.id in nodes:
            ctx.logger.info('In node: {0}'.format(node.id))

            for instance in node.instances:
                sequence = graph.sequence()
                sequence.add(
                    instance.send_event('Starting to run operation'),
                    instance.execute_operation('cloudify.interfaces.lifecycle.configure-dns', \
                        {'dns_ip': endpoint['ip_address']}),
                    instance.send_event('Done running operation')
                )
    return graph.execute()


@workflow
def config_hss(ctx, endpoint, **kwargs):
    # setting node instance runtime property
    ctx.logger.info('workflow parameter: {0}:{1}:[2]' \
        .format(endpoint['ip_address'], endpoint['port'], endpoint['domain']))

    nodes = ['bono_app', 'ellis_app', 'homer_app', 'homestead_app', 'ralf_app', 'sprout_app']
    graph = ctx.graph_mode()
    for node in ctx.nodes:
        ctx.logger.info('In node: {0}'.format(node.id))
        if node.id in nodes:
            ctx.logger.info('In node: {0}'.format(node.id))

            for instance in node.instances:
                sequence = graph.sequence()
                sequence.add(
                    instance.send_event('Starting to run operation'),
                    instance.execute_operation('cloudify.interfaces.lifecycle.configure-hss', \
                        {'hss-domain': endpoint['domain'], 'hss-port': endpoint['port']}),
                    instance.send_event('Done running operation')
                )
    return graph.execute()
