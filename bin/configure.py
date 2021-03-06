#!/usr/bin/env python
import glob
from jinja2 import Environment, FileSystemLoader
import os
import re
import sys

usage = "Usage: configure.py <dir>"

if len(sys.argv) != 2:
  print(usage)
  sys.exit(1)

path = sys.argv[1]

if not os.path.isdir(path):
  print(path + " is not a directory")
  sys.exit(1)

env = Environment(
  loader=FileSystemLoader(searchpath=path)
)

template_files = glob.glob(os.path.join(path, '*.j2'))

for tf in template_files:
  template = env.get_template(os.path.basename(tf))
  out_file = re.sub('\.j2$', '', tf)

  print("Writing file: " + os.path.join(path, out_file))
  with open(os.path.join(path, out_file), 'w') as f:
    f.write(template.render(env=os.environ))
