#!/bin/sh
##############################################################################
# Copyright (c) 2012 Felipe Arruda Pontes
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
##############################################################################


#CloudFuzzy
PROJECT_NAME=$1

#cloudfuzzy
REPO_NAME=$2

#mysite.com
DOMAIN_NAME=$3

#myNewUser
USER_NAME=$4

#user
USER_PSSWD=$5

#/tmp/
RSA_FOLDER_PATH=$6


echo "Installing TRAC for git plugin"
#installing from tarball of the same commit that worked with me
easy_install https://github.com/hvr/trac-git-plugin/tarball/722342ef03639415d7a1dc0230239d34cb97d988

echo "Creating the TRAC for the git repos"

cat <<EOF | sudo -H -u www-data trac-admin /var/lib/trac/${PROJECT_NAME} initenv
${PROJECT_NAME}

EOF

#Add to the end of it:
cat <<EOF >> /var/lib/trac/${PROJECT_NAME}/conf/trac.ini

[git]
cached_repository = false
git_bin = /usr/bin/git
persistent_cache = false
shortrev_len = 7

[components]
tracext.git.* = enabled
tracopt.ticket.commit_updater.committicketreferencemacro = enabled
tracopt.ticket.commit_updater.committicketupdater = enabled
EOF


line="repository_dir ="
rep="repository_dir = \/home\/git\/repositories\/${REPO_NAME}.git"
sed -i "s/${line}/${rep}/g" /var/lib/trac/${PROJECT_NAME}/conf/trac.ini


line="repository_type = svn"
rep="repository_type = git"
sed -i "s/${line}/${rep}/g" /var/lib/trac/${PROJECT_NAME}/conf/trac.ini


echo "Setting the right permissions to GIT repos"

usermod -a -G git www-data


line="0077"
rep="0027"
sed -i "s/${line}/${rep}/g" /home/git/.gitolite.rc

chmod g+r /home/git/projects.list
chmod -R g+rx /home/git/repositories/${REPO_NAME}.git

echo "Adding Trac admin"

trac-admin /var/lib/trac/${PROJECT_NAME}/ permission add ${USER_NAME} TRAC_ADMIN

echo "Removing the default virtualhost"
rm /etc/apache2/sites-enabled/000-default

/etc/init.d/apache2 restart

cat <<EOF
And enter the url: ${DOMAIN_NAME}/trac/${PROJECT_NAME}
and try it.

Now to set up the post-receive you need to have post-receive-trac file in ${POST_RECEIVE_PATH}
Before continuing
EOF


echo "installing Post-receive Hooks"
cd /tmp/
git clone git://gist.github.com/3380522.git
cd /tmp/3380522
cp trac-post-receive-hook-0.12-new-commits-from-all-branches-with-logfile.py \
/home/git/repositories/${REPO_NAME}.git/hooks/post-receive

chown git:git /home/git/repositories/${REPO_NAME}.git/hooks/post-receive
chmod +x /home/git/repositories/${REPO_NAME}.git/hooks/post-receive


#TRAC_ENV = '/var/lib/trac/MyTrac'
line="TRAC_ENV = "
rep="TRAC_ENV = '\/var\/lib\/trac\/${PROJECT_NAME}' #"
sed -i "s/${line}/${rep}/g" /home/git/repositories/${REPO_NAME}.git/hooks/post-receive




chown git:git /home/git/repositories/${REPO_NAME}.git/hooks/post-receive
chmod +x /home/git/repositories/${REPO_NAME}.git/hooks/post-receive
chmod -R g+rx /home/git/repositories/${REPO_NAME}.git


echo "Allowing git user access to trac db"
usermod -a -G git www-data

chown -R www-data:git /var/lib/trac/${PROJECT_NAME}/db
chmod -R g+rwx /var/lib/trac/${PROJECT_NAME}/db

chown -R www-data:git /var/lib/trac/${PROJECT_NAME}/conf
chmod -R g+rwx /var/lib/trac/${PROJECT_NAME}/conf


echo "restarting apache"
/etc/init.d/apache2 restart

echo "done!"
