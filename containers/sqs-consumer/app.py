"""
Python App to show how to receive and delete messages from AWS SQS Queue
"""

import logging
import os
import random
import signal
import sys
import time

import boto3
from botocore.exceptions import ClientError, EndpointConnectionError

logger = logging.getLogger(__name__)
sqs = boto3.resource("sqs")

# Global flag for graceful shutdown
shutdown_requested = False

# Retry configuration
MAX_RETRIES = 3
BASE_DELAY = 1  # Base delay in seconds for exponential backoff


def signal_handler(signum, frame):
    """
    Handle shutdown signals (SIGTERM, SIGINT) for graceful termination.
    """
    global shutdown_requested
    signal_name = signal.Signals(signum).name
    print(
        f"\n{signal_name} received. Finishing current batch and shutting down gracefully..."
    )
    shutdown_requested = True


def is_retryable_error(error):
    """
    Determine if an error is retryable (transient) or permanent.
    """
    if isinstance(error, EndpointConnectionError):
        # Network connectivity issues - retryable
        return True

    if isinstance(error, ClientError):
        error_code = error.response.get("Error", {}).get("Code", "")

        # Retryable AWS errors (throttling, temporary issues)
        retryable_codes = [
            "RequestTimeout",
            "RequestTimeoutException",
            "ServiceUnavailable",
            "Throttling",
            "ThrottlingException",
            "TooManyRequestsException",
            "ProvisionedThroughputExceededException",
            "InternalError",
            "InternalServerError",
            "SlowDown",
        ]

        return error_code in retryable_codes

    # Unknown error types - don't retry
    return False


def calculate_backoff_delay(attempt, base_delay=BASE_DELAY, max_delay=30):
    """
    Calculate exponential backoff delay with jitter.

    Args:
        attempt: Current retry attempt (0-based)
        base_delay: Base delay in seconds
        max_delay: Maximum delay in seconds

    Returns:
        Delay in seconds with jitter applied
    """
    # Exponential backoff: base_delay * 2^attempt
    delay = base_delay * (2**attempt)

    # Cap at max_delay
    delay = min(delay, max_delay)

    # Add jitter (randomize between 0% and 100% of delay)
    jitter = random.uniform(0, delay)

    return jitter


def retry_with_backoff(operation_name, operation_func, *args, **kwargs):
    """
    Execute a function with exponential backoff retry logic.

    Args:
        operation_name: Name of the operation for logging
        operation_func: Function to execute
        *args, **kwargs: Arguments to pass to the function

    Returns:
        Result of the operation function

    Raises:
        The last exception if all retries fail
    """
    last_exception = None

    for attempt in range(MAX_RETRIES):
        if shutdown_requested:
            # Don't retry if shutdown is requested
            raise (
                last_exception if last_exception else RuntimeError("Shutdown requested")
            )

        try:
            return operation_func(*args, **kwargs)

        except Exception as error:
            last_exception = error

            # Check if error is retryable
            if not is_retryable_error(error):
                logger.error(
                    f"{operation_name} failed with non-retryable error: {error}"
                )
                raise error

            # Last attempt - don't wait, just raise
            if attempt == MAX_RETRIES - 1:
                logger.error(
                    f"{operation_name} failed after {MAX_RETRIES} attempts: {error}"
                )
                raise error

            # Calculate backoff delay
            delay = calculate_backoff_delay(attempt)

            logger.warning(
                f"{operation_name} attempt {attempt + 1}/{MAX_RETRIES} failed: {error}. "
                f"Retrying in {delay:.2f} seconds..."
            )

            time.sleep(delay)

    # Should never reach here, but just in case
    raise last_exception


def get_queue(name):
    """
    Gets an SQS queue by name with retry logic.
    """

    def _get_queue():
        try:
            queue = sqs.get_queue_by_name(QueueName=name)
            logger.info("Got queue '%s' with URL=%s", name, queue.url)
            return queue
        except ClientError as error:
            logger.exception("Couldn't get queue named %s.", name)
            raise error

    return retry_with_backoff("get_queue", _get_queue)


def delete_messages(queue, messages):
    """
    Delete a batch of messages from a queue in a single request with retry logic.
    """

    def _delete_messages():
        try:
            entries = [
                {"Id": str(ind), "ReceiptHandle": msg.receipt_handle}
                for ind, msg in enumerate(messages)
            ]
            response = queue.delete_messages(Entries=entries)
            if "Successful" in response:
                for msg_meta in response["Successful"]:
                    logger.info(
                        "Deleted %s", messages[int(msg_meta["Id"])].receipt_handle
                    )
            if "Failed" in response:
                for msg_meta in response["Failed"]:
                    logger.warning(
                        "Could not delete %s",
                        messages[int(msg_meta["Id"])].receipt_handle,
                    )
            return response
        except ClientError as error:
            logger.exception("Couldn't delete messages from queue %s", queue)
            raise error

    try:
        return retry_with_backoff("delete_messages", _delete_messages)
    except Exception as error:
        # Log but don't crash - deletion failures are not critical
        # Messages will become visible again after visibility timeout
        logger.error(f"Failed to delete messages after retries: {error}")
        return None


def receive_messages(queue, max_number, wait_time):
    """
    Receive a batch of messages in a single request from an SQS queue with retry logic.
    """

    def _receive_messages():
        try:
            messages = queue.receive_messages(
                MessageAttributeNames=["All"],
                MaxNumberOfMessages=max_number,
                WaitTimeSeconds=wait_time,
            )
            for msg in messages:
                logger.info("Received message: %s: %s", msg.message_id, msg.body)
            return messages
        except ClientError as error:
            logger.exception("Couldn't receive messages from queue: %s", queue)
            raise error

    return retry_with_backoff("receive_messages", _receive_messages)


def main():
    """
    Main Function
    """
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)  # Kubernetes sends SIGTERM
    signal.signal(signal.SIGINT, signal_handler)  # Ctrl+C for local testing

    # Get configuration from environment variables
    sqs_queue_name = os.getenv("SQS_QUEUE_NAME")
    if not sqs_queue_name:
        raise ValueError("SQS_QUEUE_NAME environment variable is required")

    try:
        sleep_wait = int(os.getenv("SLEEP_WAIT", "10"))  # Default to 10 seconds
    except ValueError:
        raise ValueError("SLEEP_WAIT must be a valid integer")

    print(f"Starting SQS consumer for queue: {sqs_queue_name}")
    print(f"Sleep interval: {sleep_wait} seconds")

    # Main processing loop
    while not shutdown_requested:
        sqs_queue = get_queue(sqs_queue_name)

        batch_size = 10
        print(
            f"Receiving, handling, and deleting messages in \
              batches of {batch_size}."
        )
        more_messages = True
        while more_messages and not shutdown_requested:
            received_messages = receive_messages(sqs_queue, batch_size, 5)
            print(".", end="")
            sys.stdout.flush()
            if received_messages:
                delete_messages(sqs_queue, received_messages)
            else:
                more_messages = False
        print("Done.")

        # Sleep with interruption check for faster shutdown
        if not shutdown_requested:
            print(f"Sleeping for {sleep_wait} seconds...")
            for _ in range(sleep_wait):
                if shutdown_requested:
                    break
                time.sleep(1)

    print("Shutdown complete. Exiting gracefully.")


if __name__ == "__main__":
    main()
