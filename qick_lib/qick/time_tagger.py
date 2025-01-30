from queue import Queue, Empty
from queue import Empty
import time
from threading import Thread, Event
from typing import Optional
import traceback

import numpy as np

STRIDE = 100
STRIDE_TIMEOUT = 1

class TimeTagStreamWorker:
    """
    Uses a thread to stream data from the time tagger.
    """
    def __init__(self, soc):
        """
        :param soc: The QickSoc object.
        :type soc: QickSoc
        """
        self.soc = soc

        # indicate whether the worker thread is running
        self.worker_running = Event()
        # the main thread sets this flag to signal to the worker to start/stop
        self.should_work = Event()

        # indicate whether a readout is running
        self.readout_running = Event()
        # the main thread sets this flag to signal to the worker to
        # start/stop readout
        self.should_readout = Event()

        # for passing data from the worker thread to the main thread
        self.data = Queue()
        # for passing exceptions from the worker thread to the main thread
        self.errors = Queue()

        self.start_worker()

    def start_worker(self):
        """Start the worker thread."""

        if self.worker_running.is_set():
            self.stop_worker()

        self.should_work.set()

        # start the readout thread
        self.readout_worker = Thread(target=self._worker_loop, daemon=True)
        self.readout_worker.start()

        # wait until the readout thread has started
        self.worker_running.wait()

    def stop_worker(self):
        """Stop the worker thread."""

        # instruct the worker to stop
        self.should_work.clear()

        # stop the current readout
        self.stop_readout()

        # block until the worker shuts down
        while self.worker_running.is_set():
            time.sleep(0.0001)

    def start_readout(self, interp, adc_ch, stride, stride_timeout):
        """Start the readout loop.

        :param interp: Number of interpolation bits.
        :type interp: int
        :param adc_ch: ADC channel number.
        :type adc_ch: int
        :param stride: TODO.
        :type stride: int
        :param stride_timeout: TODO.
        :type stride_timeout: float

        """

        self.interp = interp
        self.adc_ch = adc_ch
        self.stride = stride
        self.stride_timeout = stride_timeout

        # if a previous readout is still running, stop it
        self.stop_readout()

        # for some reason the data queue gets bugged out if
        # the pyro thread is killed while reading it
        # so, we make a new one for each readout
        self.data = Queue()
        self.errors = Queue()

        # signal a new readout to start
        self.should_readout.set()

        # wait until the new readout has started
        self.readout_running.wait()

    def stop_readout(self):
        """Stop the readout loop."""

        # signal the readout to stop
        self.should_readout.clear()
        # block until the readout finishes
        while self.readout_running.is_set():
            time.sleep(0.0001)

    def _worker_loop(self):
        """
        Worker thread for streaming the time tags.
        """
        self.worker_running.set()

        while self.should_work.is_set():
            try:
                # wait until the main thread gives the signal to start the readout
                self.should_readout.wait()

                # clear the FIFOs
                self.soc.qtt.read_mem('ARM')
                self.soc.qtt.read_mem('TAG0')

                # indicate the readout started
                self.readout_running.set()

                last_read = time.time()

                while self.should_readout.is_set():
                    now = time.time()
                    if self.soc.qtt.arm_qty > self.stride or now - last_read > self.stride_timeout:
                        last_read = now

                        # check for ARM buffer overflow
                        if self.soc.qtt.arm_qty == self.soc.qtt.cfg['arm_mem_size'] - 1:
                            raise RuntimeError('Overflowed ARM memory.')

                        # an array containing the number of tags
                        # collected in each arm event
                        arms = self.soc.qtt.read_mem('ARM')

                        if len(arms) > 0:
                            # check for TAG buffer overflow
                            if self.soc.qtt.tag0_qty == self.soc.qtt.cfg['tag_mem_size'] - 1:
                                raise RuntimeError('Overflowed TAG memory')

                            n_tags = np.sum(arms)
                            # an array containing the time tags
                            tags = self.soc.qtt.read_mem('TAG0', length=n_tags)
                            self.data.put((arms, tags))
                    else:
                        # yield
                        time.sleep(0.0001)

            except Exception as e:
                # get the exception traceback
                tb = traceback.format_exc()
                # print out the error on the server
                print(tb)
                # pass the exception to the main thread to be relayed to pyro clients
                self.errors.put((e, tb))
                # put dummy data in the queue to break out of a blocking read()
                self.data.put((np.array([]), np.array([])))
                # stop the readout
                self.should_readout.clear()
            finally:
                self.readout_running.clear()

        self.worker_running.clear()

    def read(
            self,
            block,
            timeout: Optional[float] = None,
        ):
        """Read out data from the time tagger.

        :param block: See queue.get().
        :type block: bool
        :param timeout: Max time to wait for reading out each arm event.
        :type timeout: float
        :return: List of numpy arrays. Each array contains all of the time tags
            received during an arm event.
        :rtype: list

        """

        arms = []
        tags = []
        err = None
        tb = None

        while True:
            # try to read out time tags from the queue
            try:
                a, t = self.data.get_nowait()
                arms.append(a)
                tags.append(t)
            except Empty:
                break

        # check error queue
        try:
            err, tb = self.errors.get_nowait()
        except Empty:
            pass

        return arms, tags, err, tb

class TimeTagStream:
    """Represents a stream of time tags."""
    def __init__(
            self,
            soc,
            threshold: float = 100e-3,
            dead_time: float = 50e-9,
            interp: int = 4,
            adc_samples: int = 1,
            sample_filter: bool = False,
            slope: bool = False,
            invert: bool = True,
            stride: int = STRIDE,
            stride_timeout: int = STRIDE_TIMEOUT,
        ):
        """
        :param soc: The QickSoc object.
        :type soc: QickSoc
        :param threshold: Trigger threshold (V)
        :type threshold: float
        :param dead_time: Time to disable the time tagger after a tag (s)
        :type dead_time: float
        :param interp: Number of interpolation bits.
        :type interp: int
        :param adc_samples: Number of ADC samples to acquire for each time tag.
        :type adc_samples: int
        :param sample_filter: Whether to average ADC samples together.
        :type sample_filter: bool
        :param slope: Whether to use slope detection.
        :type slope: bool
        :param invert: Whether to invert the ADC input signal.
        :type invert: bool
        :param stride: TODO.
        :type stride: int
        :param stride_timeout: TODO.
        :type stride_timeout: float

        """
        self.soc = soc
        # convert to ADC units
        # approximate size of ADC step in V
        v_per_lsb = 18.89e-6
        self.threshold = int(threshold / v_per_lsb)
        # convert to us
        self.dead_time = dead_time / 1e-6
        self.interp = interp
        self.adc_samples = adc_samples
        if sample_filter:
            self.sample_filter = 1
        else:
            self.sample_filter = 0
        if slope:
            self.slope = 1
        else:
            self.slope = 0
        if invert:
            self.invert = 1
        else:
            self.invert = 0
        self.stride = stride
        self.stride_timeout = stride_timeout

        self.soc.qtt.set_threshold(self.threshold)
        # TODO get the adc channel associated with this time tagger
        self.adc_ch = 0
        self.soc.qtt.set_dead_time(self.soc.us2cycles(self.dead_time, ro_ch=self.adc_ch))
        self.soc.qtt.set_config(
            cfg_filter=self.sample_filter,
            cfg_slope=self.slope,
            cfg_inter=self.interp,
            smp_wr_qty=self.adc_samples,
            cfg_invert=self.invert
        )

        # conversion factor for converting tag raw values to seconds
        # factor of 8 comes from the fact that the ADC sample clock
        # is 8x than the fabric clock
        one_cycle = self.soc.cycles2us(1, ro_ch=self.adc_ch)
        self.conversion_factor = 1e-6 * one_cycle / 2**self.interp / 8

        # total number of arms/tags collected in this readout
        self.tot_arms = 0
        self.tot_tags = 0

        # buffers for storing arms/tags
        self.arms = []
        self.tags = []

    def __enter__(self):
        self.soc.tt_streamer.start_readout(
            adc_ch=self.adc_ch,
            interp=self.interp,
            stride=self.stride,
            stride_timeout=self.stride_timeout,
        )
        return self

    def __exit__(self, *args):
        self.soc.tt_streamer.stop_readout()

    def read(
            self,
            n_arms: int = 0,
            multiples: int = 1,
            timeout: Optional[float] = None,
        ):
        """Read out data from the time tagger.

        :param n_arms: Number of arm events to read out. Set to 0 to readout all available.
        :type n_arms: int
        :param multiples: TODO.
        :type multiples: int
        :param timeout: Max time to wait for reading out each arm event.
        :type timeout: float
        :return: TODO List of numpy arrays. Each array contains all of the time tags
            received during an arm event.
        :rtype: list

        """

        # conversion factor for converting tag raw values to seconds
        # factor of 8 comes from the fact that the ADC sample clock
        # is 8x than the fabric clock
        one_cycle = self.soc.cycles2us(1, ro_ch=self.adc_ch)
        conversion_factor = 1e-6 * one_cycle / 2**self.interp / 8

        timeout_remaining = timeout
        start_time = time.time()

        # buffers to store the arms/tags that will be returned from this read
        read_arms = []
        read_tags = []

        while True:
            if n_arms == 0:
                arms_list, tags_raw_list, err, tb = self.soc.tt_streamer.read(block=False)
                if arms_list is None:
                    break
            else:
                arms_list, tags_raw_list, err, tb = self.soc.tt_streamer.read(block=True, timeout=timeout_remaining)
                if timeout is not None:
                    timeout_remaining = timeout - (time.time() - start_time)

            if err is not None:
                # an error was thrown in the server
                # rethrow the traceback here
                raise RuntimeError(f'Remote exception\n\n{tb}')

            for i in range(len(arms_list)):
                # arms = numpy array containing # of tags for each arm
                arms = arms_list[i]
                self.tot_arms += len(arms)
                self.tot_tags += np.sum(arms)

                # convert tags to s
                tags = tags_raw_list[i] * conversion_factor

                tag_idx = 0
                # iterate through each arm event and add its associated tags
                # to the tags buffer
                for n_tags in arms:
                    self.arms.append(n_tags)
                    self.tags.append(tags[tag_idx:tag_idx + n_tags])
                    tag_idx += n_tags

            if n_arms == 0 or \
                (timeout is not None and time.time() - start_time >= timeout):
                # timeout elapsed or nonblocking read
                # return whatever tags we have
                read_arms = self.arms
                read_tags = self.tags
                self.arms = []
                self.tags = []
                break

            if len(self.tags) >= n_arms:
                read_arms = self.arms[:n_arms]
                read_tags = self.tags[:n_arms]
                self.arms = self.arms[n_arms:]
                self.tags = self.tags[n_arms:]
                break

        # if we read out more arms than a multiple of 'multiples', put the extras
        # back into the buffer
        num_extras = len(read_arms) % multiples
        if num_extras != 0:
            self.arms += read_arms[-num_extras:]
            read_arms = read_arms[:-num_extras]
            self.tags += read_tags[-num_extras:]
            read_tags = read_tags[:-num_extras]

        return read_arms, read_tags

class TimeTagProcessor:
    def __init__(
            self,
            num_experiments: int,
            bin_width: float,
            num_bins: int,
            bins=None
        ):
        """TODO"""
        if bins is not None:
            self.time_bins = bins
        else:
            self.time_bins = np.linspace(0, num_bins * bin_width, num_bins + 1)

        self.num_experiments = num_experiments

        # histogram of time tags for each experiment
        self.hist = np.zeros( (self.num_experiments, len(self.time_bins) - 1) )

    def bin_tags(self, new_tags):
        """TODO"""
        for i in range(self.num_experiments):
            # grab the tags relevant for experiment i
            exp_tags = np.concatenate(new_tags[i % self.num_experiments :: self.num_experiments])
            # bin the tags
            binned_tags, _ = np.histogram(exp_tags, bins=self.time_bins, density=False)
            # add the binned tags to the previously binned data
            self.hist[i] += binned_tags
