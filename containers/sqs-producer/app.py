'''
Flask App to show how to send messages to AWS SQS Queue
'''
import logging
import os
import uuid
import sys
import threading
import boto3
from botocore.exceptions import ClientError
from kubernetes import client, config
from flask import Flask, render_template, request, jsonify


app = Flask(__name__, template_folder='template')

logger = logging.getLogger(__name__)
sqs = boto3.resource("sqs")
sqs_client = boto3.client("sqs")


def get_current_namespace():
    """
    Function to get Kubernetes Namespace
    """
    try:
        with open("/var/run/secrets/kubernetes.io/serviceaccount/namespace",
                  "r", encoding="utf-8") as file:
            return file.read().strip()
    except IOError as e:
        print(f"Error reading namespace file: {e}")
        return None


def get_pods_with_label(label_selector=''):
    """
    Function to get all Kubernetes Pods with a specific label.
    """
    config.load_incluster_config()

    v1 = client.CoreV1Api()
    namespace = get_current_namespace()
    pods = v1.list_namespaced_pod(namespace=namespace,
                                  label_selector=label_selector)
    pod_names = [pod.metadata.name for pod in pods.items]

    return pod_names, len(pod_names)


def get_num_of_messages():
    """
    Get the approximate number of messages in AWS SQS Queue
    """
    # Assign SQS Queue Name
    sqs_queue_name = os.getenv('SQS_QUEUE_NAME')

    # Get AWS SQS Queue
    sqs_queue = get_queue(sqs_queue_name)

    response = sqs_client.get_queue_attributes(
        QueueUrl=sqs_queue.url,
        AttributeNames=['ApproximateNumberOfMessages']
    )

    message_count = response['Attributes']['ApproximateNumberOfMessages']

    print(f"The number of messages in the queue is: {message_count}")

    return message_count


@app.route('/', methods=['GET', 'POST'])
def home():
    """
    Flask Main App
    """
    label_selector = 'app=sqs-consumer'
    pod_names, pod_count = get_pods_with_label(label_selector)
    message_count = get_num_of_messages()

    if request.method == 'GET':
        return render_template('index.html', pod_count=pod_count,
                               pod_names=pod_names,
                               message_count=message_count)

    max_messages = int(request.form.get('number'))

    if max_messages:
        sqs_demo(max_messages)

    return render_template('index.html', pod_count=pod_count,
                           pod_names=pod_names, message_count=message_count)


@app.route('/get_pods')
def get_pods():
    """
    Get SQS Consumer Pods
    """
    label_selector = 'app=sqs-consumer'
    pod_names, pod_count = get_pods_with_label(label_selector)

    return jsonify({"pod_names": pod_names, "pod_count": pod_count})


@app.route('/get_message_count')
def get_msgs():
    """
    Get the approximate number of messages in AWS SQS Queue
    """
    message_count = get_num_of_messages()

    return jsonify({"message_count": message_count})


def process_sqs_messages(sqs_queue, max_messages):
    """
    Process Messages
    """
    batch_size = 10
    number = 0
    print(f"Sending messages in batches of {batch_size}.")
    while number < max_messages:
        messages = [
            {
                'body': f'Message {index + 1} uuid: {uuid.uuid4()}',
                'attributes': {}
            }
            for index in range(number, min(number + batch_size, max_messages))
        ]
        number = number + batch_size
        send_messages(sqs_queue, messages)
        sys.stdout.flush()
    print(f"Done. Sent {max_messages} messages.")


def sqs_demo(max_messages):
    """
    SQS Demo Main Function
    """
    # Assign SQS Queue Name
    sqs_queue_name = os.getenv('SQS_QUEUE_NAME')

    # Get AWS SQS Queue
    sqs_queue = get_queue(sqs_queue_name)

    if max_messages <= 10:
        print(f"Sending {max_messages} messages.")
        for i in range(max_messages):
            message = {
                'body': f'Message {i + 1} uuid: {uuid.uuid4()}',
                'attributes': {}
            }
            send_message(sqs_queue, message)
            print(message)
        print(f"Done. Sent {i + 1} messages.")
    elif max_messages <= 200:
        print('Test')
        process_sqs_messages(sqs_queue, max_messages)
    elif max_messages <= 2000:
        messages_t1 = max_messages // 2
        messages_t2 = max_messages - messages_t1
        total_messages = messages_t1 + messages_t2

        # creating threads
        t1 = threading.Thread(target=process_sqs_messages,
                              args=(sqs_queue, messages_t1))
        t2 = threading.Thread(target=process_sqs_messages,
                              args=(sqs_queue, messages_t2))

        # starting threads
        t1.start()
        t2.start()

        # wait until threads are completely executed
        t1.join()
        t2.join()

        # process_sqs_messages(sqs_queue, max_messages)
        print(f'Sent a total of {total_messages} messages.')
        print("Done!")
    else:
        messages_t1 = max_messages // 4
        messages_t2 = messages_t1
        messages_t3 = messages_t1
        messages_t4 = max_messages - (messages_t1 * 3)
        total_messages = messages_t1 + messages_t2 + messages_t3 + messages_t4

        # creating thread
        t1 = threading.Thread(target=process_sqs_messages,
                              args=(sqs_queue, messages_t1))
        t2 = threading.Thread(target=process_sqs_messages,
                              args=(sqs_queue, messages_t2))
        t3 = threading.Thread(target=process_sqs_messages,
                              args=(sqs_queue, messages_t3))
        t4 = threading.Thread(target=process_sqs_messages,
                              args=(sqs_queue, messages_t4))

        # starting threads
        t1.start()
        t2.start()
        t3.start()
        t4.start()

        # wait until threads are completely executed
        t1.join()
        t2.join()
        t3.join()
        t4.join()

        print(f'Sent a total of {total_messages} messages.')
        print("Done!")


def get_queue(name):
    """
    Gets an SQS Queue by Name.
    """
    try:
        queue = sqs.get_queue_by_name(QueueName=name)
        logger.info("Got queue '%s' with URL=%s", name, queue.url)
    except ClientError as error:
        logger.exception("Couldn't get queue named %s.", name)
        raise error
    else:
        return queue


def send_message(queue, message, message_attributes=None):
    """
    Send a message to an Amazon SQS queue.
    """
    if not message_attributes:
        message_attributes = {}

    try:
        response = queue.send_message(
            MessageBody=message["body"],
            MessageAttributes=message["attributes"]
        )
    except ClientError as error:
        logger.exception("Send message failed: %s", message)
        raise error
    else:
        return response


def send_messages(queue, messages):
    """
    Send a batch of messages in a single request to an SQS queue.
    This request may return overall success even when some
    messages were not sent. The caller must inspect the
    Successful and Failed lists in the response and resend any failed messages.
    """
    try:
        entries = [
            {
                "Id": str(ind),
                "MessageBody": msg["body"],
                "MessageAttributes": msg["attributes"],
            }
            for ind, msg in enumerate(messages)
        ]
        response = queue.send_messages(Entries=entries)
        if "Successful" in response:
            for msg_meta in response["Successful"]:
                logger.info(
                    "Message sent: %s: %s",
                    msg_meta["MessageId"],
                    messages[int(msg_meta["Id"])]["body"],
                )
        if "Failed" in response:
            for msg_meta in response["Failed"]:
                logger.warning(
                    "Failed to send: %s: %s",
                    msg_meta["MessageId"],
                    messages[int(msg_meta["Id"])]["body"],
                )
    except ClientError as error:
        logger.exception("Send messages failed to queue: %s", queue)
        raise error
    else:
        return response


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
