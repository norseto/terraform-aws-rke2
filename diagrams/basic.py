#!/usr/bin/env python3

from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.client import Client
from diagrams.aws.storage import S3
from diagrams.aws.network import NLB
from diagrams.aws.compute import EC2, EC2AutoScaling

with Diagram('Basic', show=False):
  with Cluster('Config Storage'):
    storage = S3('Config Bucket')
  
  with Cluster('VPC'):
    with Cluster('Private'):
      with Cluster('Control Plane'):
        servers = [
            EC2('Seed'),
            EC2('Replica')
        ]
      internal_lb = NLB('Internal')
      with Cluster('Agents'):
        agent_asg = EC2AutoScaling('Agent ASG'),
        agents = EC2('Agents')
    with Cluster('Public'):
      api_lb = NLB('Public')

  Client() >> api_lb >> servers >> Edge(label="Read/Write", color="firebrick", style="dashed") >> storage
  agent_asg >> agents >> Edge(label="ReadOnly", color="firebrick", style="dashed") >> storage
  agents >> internal_lb >> servers
