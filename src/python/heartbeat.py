import os
import time
import logging
from sched import scheduler
import threading

class PeriodicEvent(object):
    """
    Allow subclass to execute periodically
    """
    def __init__(self):
        pass

    def start(self, period):
        """
        Schedule, execute action, and repeat. Never stop.

        The first action executes immediately. Henceforth an
        action occurs every `period` seconds.
        """
        INITIAL_DELAY = 1       # seconds
        PRIORITY = 1            # required, unused here

        self.period = period
        event = scheduler(time.time, time.sleep)
        event.enter(INITIAL_DELAY, PRIORITY, self.run, ())
        while True:
            event.run()
            event.enter(self.period, PRIORITY, self.run, ())

    def run(self):
        """
        Subclass overrides to define periodic action.
        """
        raise NotImplementedError

class Heartbeat(PeriodicEvent):
    """
    Generate a periodic log event resembling:

    INFO:voyager2:heartbeat 712345678901 outerlimits dotzzYoqbx 0
    INFO:voyager2:heartbeat 712345678901 outerlimits dotzzYoqbx 1
    INFO:voyager2:heartbeat 712345678901 outerlimits dotzzYoqbx 2
    ..
    """

    def __init__(self, context, label):
        """
        PeriodicEvent(context, label)
            context - environment in which heartbeat is running (e.g. AWS account)
            label   - the service or subsystem generating the beat
          where
            identity- unique id differentiating instances of the same generator
        """
        PeriodicEvent.__init__(self)
        self.context = context
        self.label = label
        self.log = logging.getLogger(__name__)
        self.identity = os.urandom(8).encode('base64')[:-3]
        self.counter = 0

    def run(self):
        self.log.info("heartbeat %s %s %s %s", self.context, self.label, self.identity, self.counter)
        #self.log.info("%s", { "label": self.label, "id": self.identity, "count": self.counter})
        self.counter += 1

class Pulsar(threading.Thread):
    """
    Generate a heartbeat in a separate thread.
    """

    def __init__(self, context, label):
        threading.Thread.__init__(self)
        self.heartbeat = Heartbeat(context, label)

    def start(self, period):
        self.period = period
        threading.Thread.start(self)

    def run(self):
        self.heartbeat.start(self.period)

if __name__ == '__main__':
    if not logging.getLogger().handlers:
        logging.basicConfig(level=os.environ.get('LOGLEVEL', 'INFO'))

    # self test
    # beater = Heartbeat("712345678901", "outerlimits")
    # beater.start(10)

    beater1 = Pulsar("512345678901", "outerlimits")
    beater1.start(5)
    beater2 = Pulsar("712345678901", "outerlimits")
    beater2.start(7)
    beater3 = Heartbeat("312345678901", "outerlimits")
    beater3.start(3)

