#!/usr/bin/env python3

from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.client import Client
from diagrams.aws.storage import S3
from diagrams.aws.compute import EC2, EC2AutoScaling, EC2ElasticIpAddress

with Diagram('Single', show=False):
  with Cluster('Config Storage'):
    storage = S3('Config Bucket')
  with Cluster('VPC'):
    with Cluster('Public'):
      eip = EC2ElasticIpAddress('Global IP')
      with Cluster('Private Host Zone'):
        with Cluster('Control Plane'):
          servers = [
            EC2('Seed')
          ]
      with Cluster('Agents'):
        agent_asg = EC2AutoScaling('Agent ASG'),
        agents = EC2('Agents')

    servers >> Edge(label="Read/Write", color="firebrick", style="dashed") >> storage
    agent_asg >> agents >> Edge(label="ReadOnly", color="firebrick", style="dashed") >> storage
    agents >> servers
    servers >> Edge(label="Associate", color="firebrick") >> eip
    Client() >> eip
