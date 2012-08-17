#! /usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2011 Grzegorz Sobański
#               2012 Juan Fernando Jaramillo
#
# Version: 2.1
#
# - adds the commits to trac
# based on post-receive-email from git-contrib
#

import re
import os
import sys
from subprocess import Popen, PIPE, call

# config
TRAC_ENV = '/var/lib/trac/MyTrac'
GIT_PATH = '/usr/bin/git'
TRAC_ADMIN = '/usr/local/bin/trac-admin'    # I have other that doesn't work in  /usr/bin/trac-admin
REPO_NAME = '"(default)"'   # The original one have no "", I change it and work
LOG_FILE = ""     #"/tmp/traggitplugin.log"

# if you are using gitolite or sth similar, you can get the repo name from environemt
# REPO_NAME = os.getenv('GL_REPO')

def log(v):
    if LOG_FILE != "":
        f = open(LOG_FILE, "a+")
        print(v)
        f.close()

# communication with git

def call_git(command, args, input=None):
    return Popen([GIT_PATH, command] + args, stdin=PIPE, stdout=PIPE).communicate(input)[0]


def get_new_commits(ref_updates):
    """ Gets a list uf updates from git running post-receive,
    we want the list of new commits to the repo, that are part
    of the push. Even if the are in more then one ref in the push.

    Basically, we are running:
    git rev-list new1 ^old1 new2 ^old2 ^everything_else

    It returns a list of commits"""

    all_refs = set(call_git('for-each-ref', ['--format=%(refname)']).splitlines())
    commands = []
    for old, new, ref in ref_updates:
        # branch delete, skip it
        if re.match('0*$', new):
            continue

        commands += [new]
        all_refs.discard(ref)

        if not re.match('0*$', old):
            # update
            commands += ["^%s" % old]
        # else: new - do nothing more

    for ref in all_refs:
        commands += ["^%s" % ref]

    new_commits = call_git('rev-list', ['--stdin', '--reverse'], '\n'.join(commands)).splitlines()
    return new_commits


def handle_trac(commits):
    if not (os.path.exists(TRAC_ENV) and os.path.isdir(TRAC_ENV)):
        print "Trac path (%s) is not a directory." % TRAC_ENV

    if len(commits) == 0:
        return

    args = [TRAC_ADMIN, TRAC_ENV, 'changeset', 'added', REPO_NAME] + commits 
    call(' '.join(args), shell = True)

# main
if __name__ == '__main__':
    # gather all commits, to call trac-admin only once
    lines = sys.stdin.readlines()
    log(lines)
    updates = [line.split() for line in lines]
    commits = get_new_commits(updates)
    log(commits)

    # call trac-admin
    handle_trac(commits)
