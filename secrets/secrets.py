#!/usr/bin/env python3

import sys
import os
import argparse
import subprocess

if __name__ == "__main__":

  parser = argparse.ArgumentParser(description='Encrypt/decrypt secrets')
  parser.add_argument('-p', '--passphrase', help="GPG passphrase used for encryption")
  parser.add_argument('command', choices=['encrypt', 'decrypt'])
  parser.add_argument('ifile', help="Input file path")
  parser.add_argument('-o', '--ofile', help="Output file path")
  args = parser.parse_args()

  if not args.ofile:
    ofile = os.path.normpath(os.path.join(os.path.dirname(__file__), os.path.basename(args.ifile)))
  else:
    ofile = args.ofile

  cmd = "gpg --batch --yes --quiet "
  if args.command == "encrypt":
    if args.ifile.endswith('.gpg'):
      raise Exception("Input file is already encrypted")
    if not args.ofile:
      ofile = ofile + ".gpg"
    cmd = cmd + "--symmetric --cipher-algo AES256 "
  else:
    if not args.ifile.endswith('.gpg'):
      raise Exception("Input file is already derypted")
    if not args.ofile:
      ofile = ofile[:-len('.gpg')]
    cmd = cmd + "--decrypt "

  if args.passphrase:
    cmd = cmd + "--passphrase=\"" + args.passphrase + "\" "
  cmd = cmd + "--output " + ofile + " " + args.ifile

  process = subprocess.Popen(cmd.split(' '),
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE,
                             universal_newlines=True)
  stdout, stderr = process.communicate()
  if process.returncode:
    print(stdout, stderr, file=sys.stderr)
    sys.exit(process.returncode)