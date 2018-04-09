"""
sqs-cat
    Print messages in the indicated SQS queue until all are printed or the 
    message visibility forces one to re-appear.

USAGE
    python sqs-cat.py 
       --queue name  \
       --account account_id  \
       [ --region rname] [ --visibility seconds] [ --delete True]
"""
import sys
import argparse
import boto.sqs
import json
import os

parser = argparse.ArgumentParser(description='Print messages from the AWS SQS queue, one per line')

parser.add_argument(
    '-q', '--queue', dest='queue', type=str, required=True,
    help='The name of the AWS SQS queue to print.')

parser.add_argument(
    '-a', '--account', dest='account', type=str,
    help='The AWS account ID whose queue is being printed.')

parser.add_argument(
    '-r', '--region', dest='aws_region', type=str, default="us-east-1",
    help='The AWS region where the queue is located.')

parser.add_argument(
    '-d', '--delete', dest='delete', default=False, action='store_true',
    help='Whether or not to delete printed messages from the queue.')

parser.add_argument(
    '-v', '--visibility', dest='visibility', type=int, default=15,
    help='Timeout before printed messages can be printed again.')

args = parser.parse_args()

conn = boto.sqs.connect_to_region(args.aws_region)

queue = conn.get_queue(args.queue, owner_acct_id=args.account)

count = 0
seen = {}
while True:
    messages = queue.get_messages(
            num_messages=10,
            message_attributes=['All'],
            visibility_timeout=args.visibility)
    if len(messages) == 0: break

    for msg in messages:
        if msg.id in seen:
            raise RuntimeError("message visibility too short")
        else:
            seen[msg.id] = True
        body = json.loads(msg.get_body())
        obj = { 'id': msg.id,
                'attributes': msg.message_attributes,
                'body': body }

        print "{}".format(obj)
        count += 1
        if args.delete:
            queue.delete_message(msg)


