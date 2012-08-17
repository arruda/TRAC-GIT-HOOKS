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

#/tmp
RSA_FOLDER_PATH=$6


echo "Installing apache and dependencies"
apt-get install -y apache2 libapache2-mod-python python-setuptools libapache2-mod-wsgi


echo "installing git" ###

apt-get install -y git-core
cd /tmp/
git clone -b 0.12-stable git://github.com/edgewall/trac.git
easy_install Genshi==0.6
easy_install Babel==0.9.5
cd trac/
python ./setup.py install


echo "Creating trac's dirs" ###

mkdir /var/lib/trac
chown www-data:www-data /var/lib/trac/

mkdir /var/lib/cgi-bin
chown www-data:www-data /var/lib/cgi-bin


echo "Configuring Apache" ###

cat <<EOF > /etc/apache2/sites-available/repos.mysite.com
<virtualhost *:80>

ServerAdmin root@${DOMAIN_NAME}
ServerName repos.${DOMAIN_NAME}

DocumentRoot /var/www

<directory />
Options FollowSymLinks
AllowOverride None
</directory>

<directory /var/www>
Options Indexes FollowSymLinks MultiViews
AllowOverride None
Order allow,deny
deny from all
</directory>

#include the repositories configurations from the mysite.repos folder.
Include /etc/apache2/sites-available/${DOMAIN_NAME}.repos/repos

WSGIScriptAlias /trac /var/lib/cgi-bin/trac.wsgi
<directory /var/lib/cgi-bin/trac.wsgi>
WSGIApplicationGroup %{GLOBAL}
Order deny,allow
Allow from all
</directory>

ErrorLog /var/log/apache2/${DOMAIN_NAME}-error.log
LogLevel warn
CustomLog /var/log/apache2/${DOMAIN_NAME}-access.log combined
</virtualhost>
EOF

mkdir /etc/apache2/sites-available/${DOMAIN_NAME}.repos/


cat <<EOF > /etc/apache2/sites-available/${DOMAIN_NAME}.repos/repos
#include all tracs infos from this domain here
Include /etc/apache2/sites-available/${DOMAIN_NAME}.repos/*.tracInfo
EOF


cat <<EOF > /etc/apache2/sites-available/${DOMAIN_NAME}.repos/${PROJECT_NAME}.tracInfo
<Location "/trac/${PROJECT_NAME}/login">
#PythonInterpreter main_interpreter
AuthType Basic
AuthName "Trac"
AuthUserFile /var/lib/trac_user_access/${PROJECT_NAME}_passwdfile
Require valid-user
</Location>
EOF


ln -s /etc/apache2/sites-available/repos.${DOMAIN_NAME} /etc/apache2/sites-enabled/repos.${DOMAIN_NAME}



echo "Creating the WSGI script"  ###
cat <<EOF > /var/lib/cgi-bin/trac.wsgi
#!/usr/bin/python
# -*- coding: utf-8 -*-
import trac.web.main
def application(environ, start_response):
        environ['trac.env_parent_dir'] = '/var/lib/trac'
        return trac.web.main.dispatch_request(environ, start_response)
EOF

chown www-data:www-data /var/lib/cgi-bin/trac.wsgi


echo "Adding users to Trac"
mkdir -p /var/lib/trac_user_access/

chown www-data:www-data /var/lib/trac_user_access/

sudo -H -u www-data htpasswd -bcm /var/lib/trac_user_access/${PROJECT_NAME}_passwdfile ${USER_NAME} ${USER_PSSWD}


echo "Installing Gitolite (GIT server)"


adduser \
    --system \
    --shell /bin/sh \
    --gecos 'git version control' \
    --group \
    --disabled-password \
    --home /home/git \
    git


mkdir /home/git/dl
cd /home/git/dl
git clone git://github.com/sitaramc/gitolite

gitolite/install -ln /usr/local/bin



cat <<EOF
First, remember that you'll need to get a working station(not your server) to do most of the configs in Gitolite.
And first of all you'll need to create(if you don't have one yet) rsa-keypair:

cd ~/
>>>ssh-keygen -t rsa -C "your_email@youremail.com"

Then you'll have to copy the pub key to the server:
>>>scp ~/.ssh/id_rsa.pub root@yourserver.com:${RSA_FOLDER_PATH}/${USER_NAME}.pub

EOF

sudo -H -u git gitolite setup -pk ${RSA_FOLDER_PATH}/${USER_NAME}.pub




cat <<EOF
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>>>>>>Configuring gitolite-admin

Back in the workstation(the one that you copied the id_rsa.pub):
git clone git@${DOMAIN_NAME}:gitolite-admin

Open the conf/gitolite.conf file, and add this lines to the end of it:

repo ${REPO_NAME}
    RW+    =    ${USER_NAME}
    
save, commit and push it:

git add . 
git commit -m 'new repo' 
git push origin master

After this execute install_2.sh
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
EOF
