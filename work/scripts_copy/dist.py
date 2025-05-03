#!/usr/bin/env python3

###############################################################################
#  Copyright (C) 2019 Cadence Design Systems, Inc.                            #
#  All Rights Reserved.                                                       #
#  CCRNI-0013                                                                 #
#                                                                             #
# This script is AEWare, provided as an example of how to perform specialized #
# tasks within SoC Encounter.  It is not supported via the Cadence Hotline    #
# nor the CCR system.                                                         #
#                                                                             #
# This work is Cadence intellectual property and may under no circumstances   #
# be given to third parties, neither in original nor in modified versions,    #
# without explicit written permission from Cadence                            #
#                                                                             #
# The information contained herein is the proprietary and confidential        #
# information of Cadence or its licensors, and is supplied subject to, and    #
# may be used only by Cadence's customers in accordance with, a previously    #
# executed license and maintenance agreement between Cadence and its          #
# customer.                                                                   #
###############################################################################
#
# ============================================================================
# =
# = A distribution script to use with flowtool
# =
# ============================================================================
#
###############################################################################

import signal
import sys
import os
import getpass
import subprocess
import re
import datetime
import time
import logging

###############################################################################
# DIST CONFIGURATION
###############################################################################
def configure_dist():
  global flow
  # None is the default configuration
  flow = {
    None: {
      "dist": "lsf",
      "threads": 1,
      "mem": 10000
    },
    "syn_generic": {"threads": 2},
    "syn_map": {"threads": 2},
    "syn_opt": {"threads": 2},
    "prects": {"threads": 2},
    "cts": {"threads": 2},
    "postcts": {"threads": 2},
    "route": {"threads": 2, "mem": 15000},
    "postroute": {"threads": 2, "mem": 15000},
    "sta": {"threads": 2},
    "report_postroute.route": {"threads": 2},
    "report_postroute.postroute": {"threads": 2}
  }

  global dist_config
  dist_config = {
    "local": {},
    "lsf": {
      "cmd": "< PLACEHOLDER: DIST EXECUTABLE >",
      "queue": "< PLACEHOLDER: DIST QUEUE STRING >",
      "args": "< PLACEHOLDER: DIST ARGS STRING >",
      "resource": "< PLACEHOLDER: DIST RESOURCE STRING >"
    }
  }

  ###############################################################################
  # FLOW DEPENDENT JOB CONFIGURATION
  ###############################################################################
  global flow_dist, flow_threads, flow_mem
  # distribution method
  if flow_name in flow and "dist" in flow[flow_name]:
    flow_dist = flow[flow_name]["dist"]
  elif flow_top in flow and "dist" in flow[flow_top]:
    flow_dist = flow[flow_top]["dist"]
  elif os.path.basename(flow_prefix) in flow and "dist" in flow[os.path.basename(flow_prefix)]:
    flow_dist = flow[os.path.basename(flow_prefix)]["dist"]
  else:
    flow_dist = flow[None]["dist"]
  # number of threads
  if flow_name in flow and "threads" in flow[flow_name]:
    flow_threads = flow[flow_name]["threads"]
  elif flow_top in flow and "threads" in flow[flow_top]:
    flow_threads = flow[flow_top]["threads"]
  elif os.path.basename(flow_prefix) in flow and "threads" in flow[os.path.basename(flow_prefix)]:
    flow_threads = flow[os.path.basename(flow_prefix)]["threads"]
  else:
    flow_threads = flow[None]["threads"]
  # maximum memory
  if flow_name in flow and "mem" in flow[flow_name]:
    flow_mem = flow[flow_name]["mem"]
  elif flow_top in flow and "mem" in flow[flow_top]:
    flow_mem = flow[flow_top]["mem"]
  elif os.path.basename(flow_prefix) in flow and "mem" in flow[os.path.basename(flow_prefix)]:
    flow_mem = flow[os.path.basename(flow_prefix)]["mem"]
  else:
    flow_mem = flow[None]["mem"]

  os.environ["FLOWTOOL_NUM_CPUS"] = str(flow_threads)

  #############################################################################
  ## MAKE FLOWTOOL RUN LOCALY
  #############################################################################
  if tool == "flowtool":
    flow_dist = "local"

###############################################################################
# OUTPUT CONFIGURATION
###############################################################################
def configure_output():
  global debug, email_addr, is_trunk, is_interactive, tool
  debug = False
  email_addr = None
  is_trunk = tclBool(os.environ.get("FLOWTOOL_IS_TRUNK", "false"))
  is_interactive = tclBool(os.environ.get("FLOWTOOL_INTERACTIVE", "false"))
  tool = os.environ.get("FLOWTOOL_TOOL", "")
  run_tag = os.environ.get("FLOWTOOL_RUN_TAG", "")

  global flow_name, flow_child_of, flow_path, flow_top
  flow_name = os.environ.get("FLOWTOOL_FLOW_PATH", "").replace(" ", ".")
  flow_child_of = os.environ.get("FLOWTOOL_FLOW_CHILD_OF", "").split()
  flow_top = os.environ.get("FLOWTOOL_FLOW", "").replace("flow:","")
  if len(flow_child_of) > 0:
    flow_child_of = flow_child_of[-1].replace("flow:","")
    flow_path = flow_child_of + "." + flow_name
  else:
    flow_child_of = ""
    flow_path = flow_name

  global flow_prefix, flow_log, console
  flow_prefix = os.environ.get("FLOWTOOL_LOG_PREFIX", "")
  if os.path.isdir(flow_prefix):
    dist_log = flow_prefix + "/dist.log"
  elif flow_prefix == "":
    dist_log = "dist.log"
  else:
    dist_log = flow_prefix + ".dist"
  if os.path.isfile(dist_log):
    dist_log = unique_filename(dist_log)
  # set up logging to file
  logging.basicConfig(level=logging.DEBUG,
                      format='%(asctime)s %(levelname)-8s %(message)s',
                      datefmt='%m-%d %H:%M',
                      filename=dist_log,
                      filemode='w')

  # setup logging to console
  console = logging.StreamHandler(sys.stdout)
  console.setLevel(logging.INFO)
  console_style = logging.Formatter('    DIST: %(levelname)-8s %(message)s')
  console.setFormatter(console_style)
  logging.getLogger('').addHandler(console)

  if debug:
    flow_log = "output." + flow_path + ".log"
  else:
    flow_log = "/dev/null"

  # Write out messages somewhere useful, flowtool does not save stdout by
  # default (it repeats the output in debug mode)
  global flow_run
  if run_tag:
    flow_run = os.path.basename(os.path.abspath(os.environ.get("FLOWTOOL_DIR", "."))) + "/" + run_tag + "-" + flow_path
  else:
    flow_run = os.path.basename(os.path.abspath(os.environ.get("FLOWTOOL_DIR", "."))) + "-" + flow_path

def unique_filename(basename):
  i = 0
  unique = basename
  while os.path.isfile(unique):
    i += 1
    unique = basename + str(i)
  return unique

def compat_shlex_join(split_command):
  """Return a shell-escaped string from *split_command*."""
  _find_unsafe = re.compile(r'[^\w@%+=:,./-]', re.ASCII).search
  def compat_shlex_quote(s):
    """Return a shell-escaped version of the string *s*."""
    if not s:
        return "''"
    if _find_unsafe(s) is None:
        return s
    # use single quotes, and put single quotes into double quotes
    # the string $'b is then quoted as '$'"'"'b'
    return "'" + s.replace("'", "'\"'\"'") + "'"
  return ' '.join(compat_shlex_quote(arg) for arg in split_command)

###############################################################################
# LOCAL DISTRIBUTION
###############################################################################
class DistLocal():
  command = None
  process = None
  out = None
  error = None
  def __init__(self, command):
    self.command = command

  def alterpgid(self):
    # Alter the process group ID so that we don't automatically receive Ctrl-C
    # in the child process, we can then pass it on manually. This is useful in
    # farm distribution methods as we can then call a kill command
    pid = os.getpid()
    os.setpgid(pid, 0)

  def run(self):
    logging.debug("FLOW: " + flow_top)
    logging.debug("FLOW name: " + flow_name)
    logging.debug("FLOW child: " + flow_child_of)
    logging.debug("FLOW prefix: " + os.path.basename(flow_prefix))
    logging.debug("DIST method: " + flow_dist)
    logging.debug("DIST cmd: " + compat_shlex_join(self.command))
    if is_interactive:
      self.process = subprocess.Popen(self.command, preexec_fn=self.alterpgid, stdout=sys.stdout, stderr=sys.stderr, stdin=sys.stdin)
    else:
      self.process = subprocess.Popen(self.command, preexec_fn=self.alterpgid, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if not is_interactive:
      outs, errs = self.process.communicate()
      self.out = outs.decode('utf-8')
      if errs:
        self.error = errs.decode('utf-8')
    returncode = self.process.poll()
    logging.debug("DIST cmd return: {}".format(returncode))
    if not is_interactive:
      logging.debug("DIST cmd std.err: {}".format(self.error))
      if flow_dist != "local":
        logging.debug("DIST cmd std.out: {}\n".format(self.out))
    if returncode != 0:
      logging.error("DIST: Process exited abnormally")
    self.process = None
    return returncode

  def kill(self, sig):
    if self.process is not None:
      self.process.send_signal(sig)

###############################################################################
# LSF DISTRIBUTION
###############################################################################
class DistLSF(DistLocal):
  lsf_exec = None
  lsf_queue = None
  jobid = None

  def __init__(self, command):
    DistLocal.__init__(self, command)
    self.lsf_exec     = dist_config["lsf"]["cmd"]
    self.lsf_queue    = dist_config["lsf"]["queue"].split()
    lsf_args     = dist_config["lsf"]["args"].split()
    lsf_resource = dist_config["lsf"]["resource"]
    lsf_cmd = [self.lsf_exec, "-n", str(flow_threads), "-J", flow_run, "-R", lsf_resource + " rusage[mem=" + str(flow_mem) + "]"] + lsf_args + ["-q"] + self.lsf_queue
    if is_interactive:
      self.command = lsf_cmd + ["-Is"] + self.command
    else:
      self.command = lsf_cmd + ["-o", flow_log] + self.command
    if not type(flow_threads) is int:
      raise TypeError(logging.error("Reserved threads for flow should be an integer. Please review values in the configure_dist function."))
    if flow_threads < 1:
      raise Exception (logging.error("Reserved threads for flow should be greater than 0. Please review values in the configure_dist function."))
    if not type(flow_mem) is int:
      raise TypeError(logging.error("Reserved memory for flow should be an integer. Please review values in the configure_dist function."))
    if flow_mem < 1:
      raise Exception (logging.error("Reserved memory for flow should be greater than 0. Please review values in the configure_dist function."))

  def format_bjobs_time(self, secondstr):
    seconds = secondstr.split()
    if len(seconds) > 0 and seconds[0].isnumeric():
      seconds = int(seconds[0]);
      days = seconds//86400;
      seconds %= 86400;
      hours = seconds//3600;
      seconds %= 3600;
      minutes = seconds//60;
      seconds %= 60;
      return "{0:0>2}:{1:0>2}:{2:0>2}:{3:0>2}".format(days, hours, minutes, seconds)
    return secondstr

  def run(self):
    code = DistLocal.run(self)
    if is_interactive or code != 0:
      return code

    # we are running non-interactive, poll bjobs to detect when job finishes
    reg_result = re.search(r".*Job <([0-9]+)> is submitted to queue.*", self.out)
    if reg_result:
      self.jobid = reg_result.group(1).strip()
      logging.debug("DIST job: " + self.jobid)
      running = True
      poll_limit = 3 * 60
      poll_incr = 10
      poll_time = 0

      bjobs_exec = os.path.join(os.path.dirname(self.lsf_exec), "bjobs")
      bjobs_command = [bjobs_exec, "-noheader", "-o", 'id stat name run_time mem delimiter="^"', "-q"] + self.lsf_queue
      bjobs_command += [self.jobid]
      logging.debug("DIST poll: " + compat_shlex_join(bjobs_command))
      time.sleep(poll_incr)
      while running:
        bjobs_process = subprocess.Popen(bjobs_command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        bjobs_output, bjobs_err = bjobs_process.communicate()
        bjobs_output = bjobs_output.decode('utf-8').strip()
        bjobs_list = bjobs_output.split("^")
        if len(bjobs_list) == 5:
          logging.info("{0} {1[0]:>5} {1[1]:>5} {2:>11} {1[4]:>10} {1[2]}".format(datetime.datetime.now().strftime("%H:%M:%S"), bjobs_list, self.format_bjobs_time(bjobs_list[3])))
          console.flush()
          if bjobs_list[1] in ["UNKNWN", "EXIT", "DONE"]:
            running = False
            breport = subprocess.Popen([os.path.join(os.path.dirname(self.lsf_exec), "bhist"), "-q"] + self.lsf_queue + ["-l", "-UF", self.jobid], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            breport_out, breport_err = breport.communicate()
            report = breport_out.decode('utf-8')
            logging.debug("DIST bhist -l report: " + report)
            logging.debug("DIST bsub finished with status: " + bjobs_list[1])
            console.flush()
            if bjobs_list[1] in ["UNKNWN", "EXIT"]:
              if email_addr is not None:
                mail = subprocess.Popen(["mail", "-s", flow_run + "-" + bjobs_list[1], email_addr], stdin=subprocess.PIPE, universal_newlines=True)
                mail.communicate(report)
              return 1
          else:
            running = True
        else:
          logging.info("{0} {1}".format(datetime.datetime.now().strftime("%H:%M:%S"), bjobs_output))
          console.flush()
        if running:
          if poll_time < poll_limit:
            poll_time += poll_incr
          time.sleep(poll_time)
      return 0
    else:
      logging.error("DIST failed to find job ID in message: " + self.out)
      return 1

  def kill(self, sig):
    DistLocal.kill(self, sig)
    if not is_interactive and self.jobid is not None:
      logging.debug("DIST kill: " + self.jobid)
      subprocess.call([os.path.join(os.path.dirname(self.lsf_exec), "bkill"), "-q"] + self.lsf_queue + [self.jobid])

###############################################################################
# HELPER FUNCTIONS
###############################################################################
def tclBool(value):
  if value == "1" or value == "true" or value == "yes":
    return True
  elif value == "0" or value == "false" or value == "no":
    return False
  else:
    raise Exception("Bad tcl boolean value: " + value)

def main(argv):
  signal.signal(signal.SIGINT, sigintHandler)
  configure_output()
  configure_dist()

  argv.pop(0)

  global dist
  if flow_dist == "lsf":
    dist = DistLSF(argv)
  else:
    dist = DistLocal(argv)

  exitstatus = dist.run()
  logging.debug("DIST return: " + str(exitstatus))
  logging.shutdown()
  exit(exitstatus)

def sigintHandler(sig, frame):
  if dist is None:
    exit(1);
  else:
    dist.kill(sig)

if __name__ == "__main__":
  main(sys.argv)
